#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_5700661447_20261101003310/api/_infra.sh

# Given
cv_step Given "unique emails for missing, empty and blank password cases" $LINENO
E_MISSING=$(unique_email nopw)
E_EMPTY=$(unique_email emptypw)
E_BLANK=$(unique_email blankpw)

# When
cv_step When "registering without a password, with an empty one and with a blank one" $LINENO
cv_http POST /auth/register "$(jq -cn --arg e "$E_MISSING" '{email:$e}')"
S_MISSING=$CV_HTTP_STATUS
cv_http POST /auth/register "$(reg_body "$E_EMPTY" "")"
S_EMPTY=$CV_HTTP_STATUS
cv_http POST /auth/register "$(reg_body "$E_BLANK" "          ")"
S_BLANK=$CV_HTTP_STATUS

# Then
cv_step Then "all requests are rejected with 400 and no account exists" $LINENO
[ "$S_MISSING" = "400" ] || cv_fail "expected 400 for missing password got $S_MISSING" $LINENO
[ "$S_EMPTY" = "400" ] || cv_fail "expected 400 for empty password got $S_EMPTY" $LINENO
[ "$S_BLANK" = "400" ] || cv_fail "expected 400 for blank password got $S_BLANK" $LINENO
for E in "$E_MISSING" "$E_EMPTY" "$E_BLANK"; do
  cv_http POST /auth/register "$(reg_body "$E" "ProbePass#123")"
  [ "$CV_HTTP_STATUS" = "201" ] || cv_fail "expected 201 probing $E (no prior account) got $CV_HTTP_STATUS" $LINENO
done

# Cleanup
cv_step Cleanup "nothing to remove via API" $LINENO
cleanup_note
echo "CODEVALID_TEST_ASSERTION_OK:registration_fails_missing_or_empty_password"
