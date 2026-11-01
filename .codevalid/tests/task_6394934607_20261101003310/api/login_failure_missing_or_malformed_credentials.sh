#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_6394934607_20261101003310/api/_infra.sh

# Given
cv_step Given "a registered customer exists" $LINENO
EMAIL=$(cv_unique_email malformed)
PASSWORD="Pw-$(cv_suffix)-mal"
cv_register_user "$EMAIL" "$PASSWORD" "Malformed" $LINENO

# When
cv_step When "login is sent with missing, wrongly named, wrongly typed and non-JSON credentials" $LINENO
STATUSES=""
TOKENS=""
LEAKS=""
for body in \
  "$(jq -nc --arg p "$PASSWORD" '{password:$p}')" \
  "$(jq -nc --arg e "$EMAIL" '{email:$e}')" \
  '{}' \
  "$(jq -nc --arg e "$EMAIL" --arg p "$PASSWORD" '{username:$e,pass:$p}')" \
  "$(jq -nc --arg p "$PASSWORD" '{email:12345,password:$p}')" \
  "$(jq -nc --arg e "$EMAIL" '{email:$e,password:12345678}')" \
  '[]'; do
  cv_http POST /auth/login "$body"
  STATUSES="$STATUSES $CV_HTTP_STATUS"
  T=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.token? // empty' 2>/dev/null || true)
  [ -z "$T" ] || TOKENS="$TOKENS x"
  if cv_body_leaks "$PASSWORD"; then LEAKS="$LEAKS x"; fi
done
cv_http POST /auth/login '' -H 'Content-Type: application/json' --data-raw 'not-json{'
RAW_STATUS=$CV_HTTP_STATUS

# Then
cv_step Then "every malformed request gets 400, no token and no sensitive data" $LINENO
for s in $STATUSES; do
  [ "$s" = "400" ] || cv_fail "expected 400 for every malformed login got statuses:$STATUSES" $LINENO
done
[ "$RAW_STATUS" = "400" ] || cv_fail "expected 400 for non-JSON body got $RAW_STATUS" $LINENO
[ -z "$TOKENS" ] || cv_fail "expected no token on malformed logins" $LINENO
[ -z "$LEAKS" ] || cv_fail "expected no password in malformed-login responses" $LINENO
cv_post_product "" '{"name":"no-auth","price":1}'
[ "$CV_HTTP_STATUS" = "401" ] || cv_fail "expected catalog change 401 got $CV_HTTP_STATUS" $LINENO

# Cleanup
cv_step Cleanup "nothing persistent to remove (in-memory store, no delete API)" $LINENO
echo "CODEVALID_TEST_ASSERTION_OK:login_failure_missing_or_malformed_credentials"
