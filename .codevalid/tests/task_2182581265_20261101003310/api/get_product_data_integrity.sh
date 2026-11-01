#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_2182581265_20261101003310/api/_infra.sh

# Given
cv_step Given "a signed-in user adds a product with name, description, price and unique code" $LINENO
SFX=$(cv_suffix)
cv_register_user "$(cv_unique_email integ)" "Passw0rd!123" "CV Integrity" $LINENO
PNAME="CV Integrity $SFX"; PDESC="integrity desc $SFX"; PCODE="INT-$SFX"
cv_create_product "$CV_TOKEN" "$PNAME" "$PDESC" 19.99 "$PCODE" $LINENO
PID=$CV_PRODUCT_ID
CREATED=$(printf '%s' "$CV_HTTP_BODY" | jq -c '.product')

# When
cv_step When "the product is retrieved via GET /products/{id}" $LINENO
cv_http GET "/products/$PID"

# Then
cv_step Then "all fields round-trip exactly with numeric price, stable id and the unique code" $LINENO
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected 200 got $CV_HTTP_STATUS" $LINENO
P=$(printf '%s' "$CV_HTTP_BODY" | jq -c '.product // empty')
[ -n "$P" ] || cv_fail "expected .product in body got $CV_HTTP_BODY" $LINENO
[ "$(printf '%s' "$P" | jq -r .id)" = "$PID" ] || cv_fail "expected id $PID got $(printf '%s' "$P" | jq -r .id)" $LINENO
[ "$(printf '%s' "$P" | jq -r .name)" = "$PNAME" ] || cv_fail "expected name $PNAME" $LINENO
[ "$(printf '%s' "$P" | jq -r .description)" = "$PDESC" ] || cv_fail "expected description $PDESC" $LINENO
printf '%s' "$P" | jq -e '(.price|type) == "number" and .price == 19.99' >/dev/null || cv_fail "expected numeric price 19.99 got $(printf '%s' "$P" | jq -c .price)" $LINENO
printf '%s' "$P" | jq -e --argjson c "$CREATED" '.id == $c.id and .name == $c.name and .description == $c.description and .price == $c.price' >/dev/null || cv_fail "expected GET product to equal created product $CREATED got $P" $LINENO
[ "$(printf '%s' "$P" | jq -r '.code // empty')" = "$PCODE" ] || cv_fail "expected unique product code $PCODE got $(printf '%s' "$P" | jq -c .code)" $LINENO

# Cleanup
cv_step Cleanup "no delete API; in-memory data uses unique values" $LINENO
echo "left in-memory data in place"

echo "CODEVALID_TEST_ASSERTION_OK:get_product_data_integrity"
