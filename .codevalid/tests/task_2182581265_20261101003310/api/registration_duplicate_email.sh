#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_2182581265_20261101003310/api/_infra.sh

# Given
cv_step Given "an account already exists for an email" $LINENO
EMAIL=$(cv_unique_email dup)
cv_register_user "$EMAIL" "Passw0rd!123" "CV Original" $LINENO
ORIG_ID=$CV_USER_ID

# When
cv_step When "another registration uses the same email (different case)" $LINENO
UPPER=$(printf '%s' "$EMAIL" | tr '[:lower:]' '[:upper:]')
cv_http POST /auth/register "$(jq -nc --arg e "$UPPER" '{email:$e,password:"OtherPass!456",name:"CV Dup"}')"

# Then
cv_step Then "409 with an already-registered error and original credentials unchanged" $LINENO
[ "$CV_HTTP_STATUS" = "409" ] || cv_fail "expected 409 got $CV_HTTP_STATUS" $LINENO
printf '%s' "$CV_HTTP_BODY" | jq -e '.error | test("already"; "i")' >/dev/null || cv_fail "expected already-registered error got $CV_HTTP_BODY" $LINENO
if printf '%s' "$CV_HTTP_BODY" | jq -e '.token' >/dev/null 2>&1; then cv_fail "expected no token got $CV_HTTP_BODY" $LINENO; fi
cv_login "$EMAIL" "Passw0rd!123"
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected original login 200 got $CV_HTTP_STATUS" $LINENO
[ "$(printf '%s' "$CV_HTTP_BODY" | jq -r .user.id)" = "$ORIG_ID" ] || cv_fail "expected original user id $ORIG_ID" $LINENO

# Cleanup
cv_step Cleanup "no delete API; in-memory user uses a unique email" $LINENO
echo "CODEVALID_TEST_ASSERTION_OK:registration_duplicate_email"
