#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_6394934607_20261101003310/api/_infra.sh

# Given
cv_step Given "a registered customer logged in and made a catalog change" $LINENO
EMAIL=$(cv_unique_email restart)
PASSWORD="Pw-$(cv_suffix)-rs"
cv_register_user "$EMAIL" "$PASSWORD" "Restart" $LINENO
cv_login "$EMAIL" "$PASSWORD"
[ "$CV_HTTP_STATUS" = "200" ] && [ -n "$CV_LOGIN_TOKEN" ] || cv_fail "expected login 200 with token got $CV_HTTP_STATUS" $LINENO
OLD_TOKEN=$CV_LOGIN_TOKEN
cv_post_product "$OLD_TOKEN" '{"name":"before-restart","price":3}'
[ "$CV_HTTP_STATUS" = "201" ] || cv_fail "expected 201 before restart got $CV_HTTP_STATUS" $LINENO

# When
cv_step When "the service is restarted" $LINENO
cv_restart_app $LINENO

# Then
cv_step Then "the old token no longer grants catalog access and login must be redone" $LINENO
cv_post_product "$OLD_TOKEN" '{"name":"after-restart-old-token","price":3}'
[ "$CV_HTTP_STATUS" = "401" ] || cv_fail "expected 401 with pre-restart token got $CV_HTTP_STATUS" $LINENO
cv_login "$EMAIL" "$PASSWORD"
[ "$CV_HTTP_STATUS" = "401" ] || cv_fail "expected 401 login after restart (account not retained) got $CV_HTTP_STATUS" $LINENO
cv_register_user "$EMAIL" "$PASSWORD" "Restart" $LINENO
cv_login "$EMAIL" "$PASSWORD"
[ "$CV_HTTP_STATUS" = "200" ] && [ -n "$CV_LOGIN_TOKEN" ] || cv_fail "expected fresh login 200 got $CV_HTTP_STATUS" $LINENO
cv_post_product "$CV_LOGIN_TOKEN" '{"name":"after-restart-new-token","price":3}'
[ "$CV_HTTP_STATUS" = "201" ] || cv_fail "expected 201 with fresh token got $CV_HTTP_STATUS" $LINENO

# Cleanup
cv_step Cleanup "nothing persistent to remove (in-memory store, no delete API)" $LINENO
echo "CODEVALID_TEST_ASSERTION_OK:session_invalid_after_service_restart"
