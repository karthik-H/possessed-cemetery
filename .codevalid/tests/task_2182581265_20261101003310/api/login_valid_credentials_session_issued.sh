#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_2182581265_20261101003310/api/_infra.sh

# Given
cv_step Given "a registered user with known credentials" $LINENO
SFX=$(cv_suffix)
EMAIL=$(cv_unique_email login); PASS="Passw0rd!123"
cv_register_user "$EMAIL" "$PASS" "CV Login" $LINENO
UIDV=$CV_USER_ID

# When
cv_step When "POST /auth/login with correct email and password" $LINENO
cv_login "$EMAIL" "$PASS"

# Then
cv_step Then "200 with a token that authorizes adding a product" $LINENO
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected 200 got $CV_HTTP_STATUS" $LINENO
[ -n "$CV_LOGIN_TOKEN" ] || cv_fail "expected token in login response got none" $LINENO
[ "$(printf '%s' "$CV_HTTP_BODY" | jq -r .user.id)" = "$UIDV" ] || cv_fail "expected user.id $UIDV" $LINENO
[ "$(printf '%s' "$CV_HTTP_BODY" | jq -r .user.email)" = "$EMAIL" ] || cv_fail "expected user.email $EMAIL" $LINENO
PNAME="CV LoginProd $SFX"
cv_post_product "$CV_LOGIN_TOKEN" "$(jq -nc --arg n "$PNAME" '{name:$n,description:"d",price:2}')"
[ "$CV_HTTP_STATUS" = "201" ] || cv_fail "expected 201 adding product with login token got $CV_HTTP_STATUS" $LINENO
[ "$(printf '%s' "$CV_HTTP_BODY" | jq -r .product.name)" = "$PNAME" ] || cv_fail "expected product name $PNAME" $LINENO
[ "$(printf '%s' "$CV_HTTP_BODY" | jq -r .product.createdBy)" = "$UIDV" ] || cv_fail "expected createdBy $UIDV" $LINENO

# Cleanup
cv_step Cleanup "No delete endpoints exist; users/products live in the in-memory store and use unique values" $LINENO
echo "in-memory data with unique suffix left in place (no delete API)"

echo "CODEVALID_TEST_ASSERTION_OK:login_valid_credentials_session_issued"
