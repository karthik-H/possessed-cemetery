#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_6394934607_20261101003310/api/_infra.sh

# Given
cv_step Given "a registered customer exists" $LINENO
EMAIL=$(cv_unique_email badpw)
PASSWORD="Pw-$(cv_suffix)-right"
WRONG="Wrong-$(cv_suffix)-pw"
cv_register_user "$EMAIL" "$PASSWORD" "Bad PW" $LINENO

# When
cv_step When "the customer logs in with an incorrect password" $LINENO
cv_login "$EMAIL" "$WRONG"

# Then
cv_step Then "login is rejected with 401, no token, no password or account details, and catalog stays protected" $LINENO
[ "$CV_HTTP_STATUS" = "401" ] || cv_fail "expected 401 got $CV_HTTP_STATUS" $LINENO
[ -z "$CV_LOGIN_TOKEN" ] || cv_fail "expected no token on failed login" $LINENO
if cv_body_leaks "$PASSWORD" "$WRONG" "$CV_USER_ID"; then cv_fail "expected no password or account details in failure body got $CV_HTTP_BODY" $LINENO; fi
[ "$(printf '%s' "$CV_HTTP_BODY" | jq -r '.user // empty')" = "" ] || cv_fail "expected no user object in failure body" $LINENO
cv_post_product "" '{"name":"no-auth","price":1}'
[ "$CV_HTTP_STATUS" = "401" ] || cv_fail "expected catalog change 401 without login got $CV_HTTP_STATUS" $LINENO

# Cleanup
cv_step Cleanup "nothing persistent to remove (in-memory store, no delete API)" $LINENO
echo "CODEVALID_TEST_ASSERTION_OK:login_failure_invalid_password"
