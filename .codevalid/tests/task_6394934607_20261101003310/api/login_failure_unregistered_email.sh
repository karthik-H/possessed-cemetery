#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_6394934607_20261101003310/api/_infra.sh

# Given
cv_step Given "a registered customer with a wrong password reference response and an unregistered email" $LINENO
EMAIL=$(cv_unique_email known)
PASSWORD="Pw-$(cv_suffix)-known"
cv_register_user "$EMAIL" "$PASSWORD" "Known" $LINENO
cv_login "$EMAIL" "Wrong-$(cv_suffix)-pw"
[ "$CV_HTTP_STATUS" = "401" ] || cv_fail "expected 401 for wrong password reference got $CV_HTTP_STATUS" $LINENO
REF_BODY=$CV_HTTP_BODY
UNKNOWN=$(cv_unique_email unknown)

# When
cv_step When "someone logs in with an email that is not registered" $LINENO
cv_login "$UNKNOWN" "Some-$(cv_suffix)-pw"

# Then
cv_step Then "401 without token, same message as a wrong password, and catalog stays protected" $LINENO
[ "$CV_HTTP_STATUS" = "401" ] || cv_fail "expected 401 got $CV_HTTP_STATUS" $LINENO
[ -z "$CV_LOGIN_TOKEN" ] || cv_fail "expected no token for unknown email" $LINENO
[ "$CV_HTTP_BODY" = "$REF_BODY" ] || cv_fail "expected identical body to wrong-password case ($REF_BODY) got $CV_HTTP_BODY" $LINENO
if cv_body_leaks "$UNKNOWN"; then cv_fail "expected no account info in body got $CV_HTTP_BODY" $LINENO; fi
cv_post_product "" '{"name":"no-auth","price":1}'
[ "$CV_HTTP_STATUS" = "401" ] || cv_fail "expected catalog change 401 got $CV_HTTP_STATUS" $LINENO

# Cleanup
cv_step Cleanup "nothing persistent to remove (in-memory store, no delete API)" $LINENO
echo "CODEVALID_TEST_ASSERTION_OK:login_failure_unregistered_email"
