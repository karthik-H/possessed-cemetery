#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_6394934607_20261101003310/api/_infra.sh

# Given
cv_step Given "a registered customer exists and catalog changes are rejected before login" $LINENO
EMAIL=$(cv_unique_email login_ok)
PASSWORD="Pw-$(cv_suffix)-ok"
cv_register_user "$EMAIL" "$PASSWORD" "Login OK" $LINENO
cv_prereq "POST /products without a token before login" $LINENO
cv_post_product "" '{"name":"before-login","price":1}'
[ "$CV_HTTP_STATUS" = "401" ] || cv_fail "expected 401 for catalog change before login got $CV_HTTP_STATUS" $LINENO

# When
cv_step When "the customer logs in with valid email and password" $LINENO
cv_login "$EMAIL" "$PASSWORD"
LOGIN_STATUS=$CV_HTTP_STATUS
LOGIN_BODY=$CV_HTTP_BODY
TOKEN=$CV_LOGIN_TOKEN

# Then
cv_step Then "login returns a token without the password and the token enables catalog changes" $LINENO
[ "$LOGIN_STATUS" = "200" ] || cv_fail "expected login 200 got $LOGIN_STATUS" $LINENO
[ -n "$TOKEN" ] || cv_fail "expected token in login response got none" $LINENO
[ "$(printf '%s' "$LOGIN_BODY" | jq -r '.user.email')" = "$EMAIL" ] || cv_fail "expected user.email $EMAIL in login response" $LINENO
CV_HTTP_BODY=$LOGIN_BODY
if cv_body_leaks "$PASSWORD"; then cv_fail "expected no password in login response got leak" $LINENO; fi
PNAME="cv-login-product-$(cv_suffix)"
cv_post_product "$TOKEN" "$(jq -nc --arg n "$PNAME" '{name:$n,price:12.5}')"
[ "$CV_HTTP_STATUS" = "201" ] || cv_fail "expected 201 for catalog change after login got $CV_HTTP_STATUS" $LINENO
[ "$(printf '%s' "$CV_HTTP_BODY" | jq -r '.product.name')" = "$PNAME" ] || cv_fail "expected product.name $PNAME" $LINENO
if cv_body_leaks "$PASSWORD"; then cv_fail "expected no password in products response" $LINENO; fi

# Cleanup
cv_step Cleanup "nothing persistent to remove (in-memory store, no delete API)" $LINENO
echo "CODEVALID_TEST_ASSERTION_OK:login_success_enables_catalog_access"
