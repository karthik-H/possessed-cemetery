#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_5700661447_20261101003310/api/_infra.sh

# Given
cv_step Given "a new unique email and a distinctive password" $LINENO
EMAIL=$(unique_email priv)
PASSWORD="Secret$(date +%s)#Pw"

# When
cv_step When "registering the account" $LINENO
cv_http POST /auth/register "$(reg_body "$EMAIL" "$PASSWORD")" 201

# Then
cv_step Then "the response has id and email but no password or hash" $LINENO
printf '%s' "$CV_HTTP_BODY" | jq -e '.user.id and .user.email' >/dev/null || cv_fail "expected user.id and user.email got $CV_HTTP_BODY" $LINENO
case "$CV_HTTP_BODY" in *"$PASSWORD"*) cv_fail "expected raw password absent from response got it present" $LINENO ;; esac
KEYS=$(printf '%s' "$CV_HTTP_BODY" | jq -r '[paths | last | strings | ascii_downcase] | map(select(test("password|hash|salt"))) | join(",")')
[ -z "$KEYS" ] || cv_fail "expected no password/hash fields got $KEYS" $LINENO
printf '%s' "$CV_HTTP_BODY" | grep -Eq '\$(2[aby]?|argon2|scrypt)' && cv_fail "expected no password hash value in response got one" $LINENO
TOKEN=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.token // empty')
if [ -n "$TOKEN" ]; then
  PAYLOAD=$(printf '%s' "$TOKEN" | cut -d. -f2 | tr '_-' '/+')
  while [ $(( ${#PAYLOAD} % 4 )) -ne 0 ]; do PAYLOAD="${PAYLOAD}="; done
  DECODED=$(printf '%s' "$PAYLOAD" | base64 -d 2>/dev/null || true)
  echo "token payload: $DECODED"
  case "$DECODED" in *"$PASSWORD"*|*assword*|*[Hh]ash*) cv_fail "expected token payload without password data got $DECODED" $LINENO ;; esac
fi

# Cleanup
cv_step Cleanup "nothing to remove via API" $LINENO
cleanup_note
echo "CODEVALID_TEST_ASSERTION_OK:password_not_exposed_in_response"
