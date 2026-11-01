#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_2182581265_20261101003310/api/_infra.sh

# Given
cv_step Given "a registered, signed-in user and a unique product payload" $LINENO
SFX=$(cv_suffix)
cv_register_user "$(cv_unique_email add)" "Passw0rd!123" "CV Adder" $LINENO
TOKEN=$CV_TOKEN; UID_=$CV_USER_ID
PNAME="CV Product $SFX"; PDESC="Desc $SFX"; PCODE="CODE-$SFX"
BODY=$(cv_product_body "$PNAME" "$PDESC" 19.99 "$PCODE")

# When
cv_step When "POST /products with valid name, description, price and code" $LINENO
cv_post_product "$TOKEN" "$BODY"

# Then
cv_step Then "201 with the created product carrying the submitted fields" $LINENO
[ "$CV_HTTP_STATUS" = "201" ] || cv_fail "expected 201 got $CV_HTTP_STATUS" $LINENO
P=$(printf '%s' "$CV_HTTP_BODY" | jq -c '.product // empty')
[ -n "$P" ] || cv_fail "expected .product in body got none" $LINENO
PID=$(printf '%s' "$P" | jq -r '.id // empty')
[ -n "$PID" ] || cv_fail "expected product.id got none" $LINENO
[ "$(printf '%s' "$P" | jq -r .name)" = "$PNAME" ] || cv_fail "expected name $PNAME got $(printf '%s' "$P" | jq -r .name)" $LINENO
[ "$(printf '%s' "$P" | jq -r .description)" = "$PDESC" ] || cv_fail "expected description $PDESC got $(printf '%s' "$P" | jq -r .description)" $LINENO
printf '%s' "$P" | jq -e '.price == 19.99' >/dev/null || cv_fail "expected price 19.99 got $(printf '%s' "$P" | jq -c .price)" $LINENO
[ "$(printf '%s' "$P" | jq -r '.code // empty')" = "$PCODE" ] || cv_fail "expected product code $PCODE got $(printf '%s' "$P" | jq -c '.code')" $LINENO
cv_http GET "/products/$PID" 200
[ "$(printf '%s' "$CV_HTTP_BODY" | jq -r .product.name)" = "$PNAME" ] || cv_fail "expected product retrievable after create" $LINENO

# Cleanup
cv_step Cleanup "No delete endpoints exist; users/products live in the in-memory store and use unique values" $LINENO
echo "in-memory data with unique suffix left in place (no delete API)"

echo "CODEVALID_TEST_ASSERTION_OK:signed_in_user_adds_valid_product"
