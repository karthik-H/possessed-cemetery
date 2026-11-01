#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_5700661447_20261101003310/api/_infra.sh

# Given
cv_step Given "a new unique email and a strong password" $LINENO
EMAIL=$(unique_email newreg)
PASSWORD='Str0ng!Passw0rd#2026'

# When
cv_step When "the customer registers via POST /auth/register" $LINENO
cv_http POST /auth/register "$(reg_body "$EMAIL" "$PASSWORD" "New Customer")"

# Then
cv_step Then "the account is created (201 with id, email, token) and can sign in" $LINENO
[ "$CV_HTTP_STATUS" = "201" ] || cv_fail "expected 201 got $CV_HTTP_STATUS" $LINENO
ID=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.user.id // empty')
[ -n "$ID" ] || cv_fail "expected user.id in response got empty" $LINENO
GOT_EMAIL=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.user.email // empty')
[ "$GOT_EMAIL" = "$EMAIL" ] || cv_fail "expected user.email $EMAIL got $GOT_EMAIL" $LINENO
TOKEN=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.token // empty')
[ -n "$TOKEN" ] || cv_fail "expected non-empty token got empty" $LINENO
cv_http POST /auth/login "$(login_body "$EMAIL" "$PASSWORD")"
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected login 200 for new account got $CV_HTTP_STATUS" $LINENO
LOGIN_ID=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.user.id // empty')
[ "$LOGIN_ID" = "$ID" ] || cv_fail "expected login user.id $ID got $LOGIN_ID" $LINENO

# Cleanup
cv_step Cleanup "nothing to remove via API" $LINENO
cleanup_note
echo "CODEVALID_TEST_ASSERTION_OK:successful_registration_new_email"
