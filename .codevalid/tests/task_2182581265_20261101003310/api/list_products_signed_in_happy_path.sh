#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_2182581265_20261101003310/api/_infra.sh

# Given
cv_step Given "a signed-in user who added two products with unique codes" $LINENO
SFX=$(cv_suffix)
cv_register_user "$(cv_unique_email list)" "Passw0rd!123" "CV Lister" $LINENO
TOKEN=$CV_TOKEN
cv_create_product "$TOKEN" "CV ListA $SFX" "desc A" 3.5 "LA-$SFX" $LINENO
IDA=$CV_PRODUCT_ID
cv_create_product "$TOKEN" "CV ListB $SFX" "desc B" 7 "LB-$SFX" $LINENO
IDB=$CV_PRODUCT_ID

# When
cv_step When "signed-in user calls GET /products" $LINENO
cv_http GET /products "" -H "Authorization: Bearer $TOKEN"

# Then
cv_step Then "200 with both products listed with name, description, price and code" $LINENO
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected 200 got $CV_HTTP_STATUS" $LINENO
printf '%s' "$CV_HTTP_BODY" | jq -e '.products | type == "array"' >/dev/null || cv_fail "expected .products array" $LINENO
for spec in "$IDA|CV ListA $SFX|desc A|3.5|LA-$SFX" "$IDB|CV ListB $SFX|desc B|7|LB-$SFX"; do
  IFS='|' read -r id n d p c <<<"$spec"
  P=$(printf '%s' "$CV_HTTP_BODY" | jq -c --arg id "$id" '.products[] | select(.id == $id)')
  [ -n "$P" ] || cv_fail "expected product $id in list got none" $LINENO
  [ "$(printf '%s' "$P" | jq -r .name)" = "$n" ] || cv_fail "expected name $n got $(printf '%s' "$P" | jq -r .name)" $LINENO
  [ "$(printf '%s' "$P" | jq -r .description)" = "$d" ] || cv_fail "expected description $d" $LINENO
  printf '%s' "$P" | jq -e --argjson p "$p" '.price == $p' >/dev/null || cv_fail "expected price $p got $(printf '%s' "$P" | jq -c .price)" $LINENO
  [ "$(printf '%s' "$P" | jq -r '.code // empty')" = "$c" ] || cv_fail "expected product code $c got $(printf '%s' "$P" | jq -c .code)" $LINENO
done

# Cleanup
cv_step Cleanup "No delete endpoints exist; users/products live in the in-memory store and use unique values" $LINENO
echo "in-memory data with unique suffix left in place (no delete API)"

echo "CODEVALID_TEST_ASSERTION_OK:list_products_signed_in_happy_path"
