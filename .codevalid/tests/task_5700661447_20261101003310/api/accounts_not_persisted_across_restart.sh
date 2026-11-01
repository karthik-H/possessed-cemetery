#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_5700661447_20261101003310/api/_infra.sh

# Given
cv_step Given "an account registered before a service restart" $LINENO
EMAIL=$(unique_email restart)
PASSWORD='BeforeRestart#123'
cv_http POST /auth/register "$(reg_body "$EMAIL" "$PASSWORD")"
[ "$CV_HTTP_STATUS" = "201" ] || cv_fail "expected 201 seeding account got $CV_HTTP_STATUS" $LINENO
OLD_ID=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.user.id // empty')
cv_prereq "confirm the email is taken before restart" $LINENO
cv_http POST /auth/register "$(reg_body "$EMAIL" "$PASSWORD")"
[ "$CV_HTTP_STATUS" = "409" ] || cv_fail "expected 409 before restart got $CV_HTTP_STATUS" $LINENO
restart_app $LINENO

# When
cv_step When "registering again with the same email after restart" $LINENO
cv_http POST /auth/register "$(reg_body "$EMAIL" "AfterRestart#456")"

# Then
cv_step Then "the email is accepted as new (201, new id) and the old password no longer works" $LINENO
[ "$CV_HTTP_STATUS" = "201" ] || cv_fail "expected 201 after restart got $CV_HTTP_STATUS" $LINENO
NEW_ID=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.user.id // empty')
[ -n "$NEW_ID" ] && [ "$NEW_ID" != "$OLD_ID" ] || cv_fail "expected a new user id different from $OLD_ID got $NEW_ID" $LINENO
cv_http POST /auth/login "$(login_body "$EMAIL" "$PASSWORD")"
[ "$CV_HTTP_STATUS" = "401" ] || cv_fail "expected 401 for pre-restart password got $CV_HTTP_STATUS" $LINENO

# Cleanup
cv_step Cleanup "nothing to remove via API" $LINENO
cleanup_note
echo "CODEVALID_TEST_ASSERTION_OK:accounts_not_persisted_across_restart"
