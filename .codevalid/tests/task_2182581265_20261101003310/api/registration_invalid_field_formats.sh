#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_2182581265_20261101003310/api/_infra.sh

# Given
cv_step Given "payloads with an invalid email syntax and a too-short password" $LINENO
SFX=$(cv_suffix)
BAD_EMAIL=$(jq -nc --arg e "not-an-email-$SFX" '{email:$e,password:"Passw0rd!123",name:"CV Bad"}')
SHORT_EMAIL=$(cv_unique_email short)
SHORT_PASS=$(jq -nc --arg e "$SHORT_EMAIL" '{email:$e,password:"abc",name:"CV Bad"}')

# When
cv_step When "each payload is posted to /auth/register" $LINENO
cv_http POST /auth/register "$BAD_EMAIL"; S1=$CV_HTTP_STATUS; B1=$CV_HTTP_BODY
cv_http POST /auth/register "$SHORT_PASS"; S2=$CV_HTTP_STATUS; B2=$CV_HTTP_BODY

# Then
cv_step Then "both are rejected with 400 and field-level validation errors" $LINENO
[ "$S1" = "400" ] || cv_fail "expected 400 for invalid email got $S1" $LINENO
printf '%s' "$B1" | jq -e '.details.email' >/dev/null || cv_fail "expected details.email error got $B1" $LINENO
[ "$S2" = "400" ] || cv_fail "expected 400 for short password got $S2" $LINENO
printf '%s' "$B2" | jq -e '.details.password' >/dev/null || cv_fail "expected details.password error got $B2" $LINENO
cv_login "$SHORT_EMAIL" "abcdefgh1"
[ "$CV_HTTP_STATUS" = "401" ] || cv_fail "expected no account for rejected email (login 401) got $CV_HTTP_STATUS" $LINENO

# Cleanup
cv_step Cleanup "nothing created" $LINENO
echo "CODEVALID_TEST_ASSERTION_OK:registration_invalid_field_formats"
