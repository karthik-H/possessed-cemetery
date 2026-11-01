#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_2182581265_20261101003310/api/_infra.sh

# Given
cv_step Given "a new user registers successfully" $LINENO
SFX=$(cv_suffix)
EMAIL=$(cv_unique_email flow)
PASS="Passw0rd!123"
cv_register_user "$EMAIL" "$PASS" "CV Flow" $LINENO
UID_REG=$CV_USER_ID

# When
cv_step When "the user signs in with the same credentials and adds a product" $LINENO
cv_login "$EMAIL" "$PASS"
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected login 200 got $CV_HTTP_STATUS" $LINENO
[ -n "$CV_LOGIN_TOKEN" ] || cv_fail "expected token from login" $LINENO
[ "$(printf '%s' "$CV_HTTP_BODY" | jq -r .user.id)" = "$UID_REG" ] || cv_fail "expected login user id $UID_REG" $LINENO
PNAME="CV Flow $SFX"
cv_post_product "$CV_LOGIN_TOKEN" "$(jq -nc --arg n "$PNAME" '{name:$n,description:"flow desc",price:12.5}')"
CS=$CV_HTTP_STATUS; CB=$CV_HTTP_BODY

# Then
cv_step Then "product is created (201), owned by the user and retrievable" $LINENO
[ "$CS" = "201" ] || cv_fail "expected 201 from POST /products got $CS" $LINENO
PID=$(printf '%s' "$CB" | jq -r '.product.id // empty')
[ -n "$PID" ] || cv_fail "expected product.id got $CB" $LINENO
[ "$(printf '%s' "$CB" | jq -r .product.createdBy)" = "$UID_REG" ] || cv_fail "expected createdBy $UID_REG got $CB" $LINENO
cv_http GET "/products/$PID"
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected 200 fetching new product got $CV_HTTP_STATUS" $LINENO
[ "$(printf '%s' "$CV_HTTP_BODY" | jq -r .product.name)" = "$PNAME" ] || cv_fail "expected name $PNAME" $LINENO

# Cleanup
cv_step Cleanup "no delete API; in-memory data uses unique values" $LINENO
echo "CODEVALID_TEST_ASSERTION_OK:registration_followed_by_auth_and_product_add"
