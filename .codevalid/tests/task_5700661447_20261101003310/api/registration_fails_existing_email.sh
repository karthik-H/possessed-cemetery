#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_5700661447_20261101003310/api/_infra.sh

# Given
cv_step Given "an account already registered with a unique email" $LINENO
EMAIL=$(unique_email dup)
PASSWORD='OriginalPass#123'
cv_prereq "register the first account" $LINENO
cv_http POST /auth/register "$(reg_body "$EMAIL" "$PASSWORD")"
[ "$CV_HTTP_STATUS" = "201" ] || cv_fail "expected 201 when seeding first account got $CV_HTTP_STATUS" $LINENO
FIRST_ID=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.user.id // empty')

# When
cv_step When "registering again with the same email and a different password" $LINENO
cv_http POST /auth/register "$(reg_body "$EMAIL" "AnotherPass#456")"

# Then
cv_step Then "the request is rejected with a clear error and no duplicate is created" $LINENO
[ "$CV_HTTP_STATUS" = "409" ] || cv_fail "expected 409 got $CV_HTTP_STATUS" $LINENO
ERR=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.error // empty')
[ -n "$ERR" ] || cv_fail "expected an error message got empty" $LINENO
printf '%s' "$CV_HTTP_BODY" | jq -e '.token' >/dev/null 2>&1 && cv_fail "expected no token on duplicate registration got one" $LINENO
cv_http POST /auth/login "$(login_body "$EMAIL" "AnotherPass#456")"
[ "$CV_HTTP_STATUS" = "401" ] || cv_fail "expected 401 logging in with the rejected password got $CV_HTTP_STATUS" $LINENO
cv_http POST /auth/login "$(login_body "$EMAIL" "$PASSWORD")"
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected original account login 200 got $CV_HTTP_STATUS" $LINENO
LID=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.user.id // empty')
[ "$LID" = "$FIRST_ID" ] || cv_fail "expected original user id $FIRST_ID got $LID" $LINENO

# Cleanup
cv_step Cleanup "nothing to remove via API" $LINENO
cleanup_note
echo "CODEVALID_TEST_ASSERTION_OK:registration_fails_existing_email"
