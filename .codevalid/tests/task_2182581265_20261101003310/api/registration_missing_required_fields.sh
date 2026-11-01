#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_2182581265_20261101003310/api/_infra.sh

# Given
cv_step Given "payloads missing email, password, or both" $LINENO
EMAIL=$(cv_unique_email missing)
NO_EMAIL=$(jq -nc '{password:"Passw0rd!123",name:"CV Missing"}')
NO_PASS=$(jq -nc --arg e "$EMAIL" '{email:$e,name:"CV Missing"}')
EMPTY='{}'

# When
cv_step When "each payload is posted to /auth/register" $LINENO
cv_http POST /auth/register "$NO_EMAIL"; S1=$CV_HTTP_STATUS; B1=$CV_HTTP_BODY
cv_http POST /auth/register "$NO_PASS"; S2=$CV_HTTP_STATUS; B2=$CV_HTTP_BODY
cv_http POST /auth/register "$EMPTY"; S3=$CV_HTTP_STATUS; B3=$CV_HTTP_BODY

# Then
cv_step Then "each is rejected with 400 validation errors and no account is created" $LINENO
[ "$S1" = "400" ] || cv_fail "expected 400 for missing email got $S1" $LINENO
printf '%s' "$B1" | jq -e '.details.email' >/dev/null || cv_fail "expected details.email error got $B1" $LINENO
[ "$S2" = "400" ] || cv_fail "expected 400 for missing password got $S2" $LINENO
printf '%s' "$B2" | jq -e '.details.password' >/dev/null || cv_fail "expected details.password error got $B2" $LINENO
[ "$S3" = "400" ] || cv_fail "expected 400 for empty body got $S3" $LINENO
printf '%s' "$B3" | jq -e '.details.email and .details.password' >/dev/null || cv_fail "expected email and password errors got $B3" $LINENO
cv_login "$EMAIL" "Passw0rd!123"
[ "$CV_HTTP_STATUS" = "401" ] || cv_fail "expected login for never-created account to be 401 got $CV_HTTP_STATUS" $LINENO

# Cleanup
cv_step Cleanup "nothing created" $LINENO
echo "CODEVALID_TEST_ASSERTION_OK:registration_missing_required_fields"
