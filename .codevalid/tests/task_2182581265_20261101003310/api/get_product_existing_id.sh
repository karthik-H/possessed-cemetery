#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_2182581265_20261101003310/api/_infra.sh

# Given
cv_step Given "a signed-in user has added a product with a unique code" $LINENO
SFX=$(cv_suffix)
cv_register_user "$(cv_unique_email get)" "Passw0rd!123" "CV Getter" $LINENO
PNAME="CV Get $SFX"; PDESC="get desc $SFX"; PCODE="GET-$SFX"
cv_create_product "$CV_TOKEN" "$PNAME" "$PDESC" 42.5 "$PCODE" $LINENO
PID=$CV_PRODUCT_ID

# When
cv_step When "a client fetches GET /products/{id}" $LINENO
cv_http GET "/products/$PID"

# Then
cv_step Then "200 with matching id, name, description, price and code" $LINENO
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected 200 got $CV_HTTP_STATUS" $LINENO
P=$(printf '%s' "$CV_HTTP_BODY" | jq -c '.product // empty')
[ -n "$P" ] || cv_fail "expected .product in body" $LINENO
[ "$(printf '%s' "$P" | jq -r .id)" = "$PID" ] || cv_fail "expected id $PID" $LINENO
[ "$(printf '%s' "$P" | jq -r .name)" = "$PNAME" ] || cv_fail "expected name $PNAME" $LINENO
[ "$(printf '%s' "$P" | jq -r .description)" = "$PDESC" ] || cv_fail "expected description $PDESC" $LINENO
printf '%s' "$P" | jq -e '.price == 42.5' >/dev/null || cv_fail "expected price 42.5 got $(printf '%s' "$P" | jq -c .price)" $LINENO
[ "$(printf '%s' "$P" | jq -r '.code // empty')" = "$PCODE" ] || cv_fail "expected product code $PCODE got $(printf '%s' "$P" | jq -c .code)" $LINENO

# Cleanup
cv_step Cleanup "No delete endpoints exist; users/products live in the in-memory store and use unique values" $LINENO
echo "in-memory data with unique suffix left in place (no delete API)"

echo "CODEVALID_TEST_ASSERTION_OK:get_product_existing_id"
