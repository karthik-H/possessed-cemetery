#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_2182581265_20261101003310/api/_infra.sh

# Given
cv_step Given "a new unique email, password and name" $LINENO
SFX=$(cv_suffix)
EMAIL=$(cv_unique_email reg); PASS="Passw0rd!123"; NAME="CV Reg $SFX"

# When
cv_step When "POST /auth/register with valid data" $LINENO
cv_http POST /auth/register "$(jq -nc --arg e "$EMAIL" --arg p "$PASS" --arg n "$NAME" '{email:$e,password:$p,name:$n}')"

# Then
cv_step Then "201 with token and public user, and the user can log in and add a product" $LINENO
[ "$CV_HTTP_STATUS" = "201" ] || cv_fail "expected 201 got $CV_HTTP_STATUS" $LINENO
UIDV=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.user.id // empty')
[ -n "$UIDV" ] || cv_fail "expected user.id got none" $LINENO
[ "$(printf '%s' "$CV_HTTP_BODY" | jq -r .user.email)" = "$EMAIL" ] || cv_fail "expected user.email $EMAIL" $LINENO
[ "$(printf '%s' "$CV_HTTP_BODY" | jq -r .user.name)" = "$NAME" ] || cv_fail "expected user.name $NAME" $LINENO
[ -n "$(printf '%s' "$CV_HTTP_BODY" | jq -r '.token // empty')" ] || cv_fail "expected token in register response" $LINENO
printf '%s' "$CV_HTTP_BODY" | jq -e '[.. | objects | keys[]] | any(. == "password" or . == "passwordHash") | not' >/dev/null || cv_fail "expected no password fields in response" $LINENO
cv_login "$EMAIL" "$PASS"
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected login 200 got $CV_HTTP_STATUS" $LINENO
[ -n "$CV_LOGIN_TOKEN" ] || cv_fail "expected login token" $LINENO
cv_post_product "$CV_LOGIN_TOKEN" "$(jq -nc --arg n "CV RegProd $SFX" '{name:$n,description:"d",price:1}')"
[ "$CV_HTTP_STATUS" = "201" ] || cv_fail "expected 201 adding product after login got $CV_HTTP_STATUS" $LINENO
[ "$(printf '%s' "$CV_HTTP_BODY" | jq -r .product.createdBy)" = "$UIDV" ] || cv_fail "expected createdBy $UIDV" $LINENO

# Cleanup
cv_step Cleanup "No delete endpoints exist; users/products live in the in-memory store and use unique values" $LINENO
echo "in-memory data with unique suffix left in place (no delete API)"

echo "CODEVALID_TEST_ASSERTION_OK:successful_registration_new_user"
