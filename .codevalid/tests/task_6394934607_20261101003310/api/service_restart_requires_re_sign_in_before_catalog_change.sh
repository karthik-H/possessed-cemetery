#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_6394934607_20261101003310/api/_infra.sh

# Given
cv_step Given "a signed-in customer has posted a product successfully" $LINENO
EMAIL=$(cv_unique_email rs_post)
PASSWORD="Pw-$(cv_suffix)-rsp"
cv_register_user "$EMAIL" "$PASSWORD" "Restart Poster" $LINENO
cv_login "$EMAIL" "$PASSWORD"
[ "$CV_HTTP_STATUS" = "200" ] && [ -n "$CV_LOGIN_TOKEN" ] || cv_fail "expected login 200 with token got $CV_HTTP_STATUS" $LINENO
OLD_TOKEN=$CV_LOGIN_TOKEN
cv_post_product "$OLD_TOKEN" '{"name":"pre-restart","price":2}'
[ "$CV_HTTP_STATUS" = "201" ] || cv_fail "expected 201 before restart got $CV_HTTP_STATUS" $LINENO

# When
cv_step When "the service restarts and the old session is used for POST /products" $LINENO
cv_restart_app $LINENO
PNAME="cv-post-restart-$(cv_suffix)"
cv_post_product "$OLD_TOKEN" "$(jq -nc --arg n "$PNAME" '{name:$n,price:2}')"
OLD_STATUS=$CV_HTTP_STATUS

# Then
cv_step Then "old session is rejected, nothing is created, and only a fresh sign-in allows posting" $LINENO
[ "$OLD_STATUS" = "401" ] || cv_fail "expected 401 with pre-restart token got $OLD_STATUS" $LINENO
[ "$(cv_product_count_named "$PNAME")" = "0" ] || cv_fail "expected no product created with stale session" $LINENO
cv_register_user "$EMAIL" "$PASSWORD" "Restart Poster" $LINENO
cv_login "$EMAIL" "$PASSWORD"
[ "$CV_HTTP_STATUS" = "200" ] && [ -n "$CV_LOGIN_TOKEN" ] || cv_fail "expected re-sign-in 200 got $CV_HTTP_STATUS" $LINENO
cv_post_product "$CV_LOGIN_TOKEN" "$(jq -nc --arg n "$PNAME" '{name:$n,price:2}')"
[ "$CV_HTTP_STATUS" = "201" ] || cv_fail "expected 201 after re-sign-in got $CV_HTTP_STATUS" $LINENO

# Cleanup
cv_step Cleanup "nothing persistent to remove (in-memory store, no delete API)" $LINENO
echo "CODEVALID_TEST_ASSERTION_OK:service_restart_requires_re_sign_in_before_catalog_change"
