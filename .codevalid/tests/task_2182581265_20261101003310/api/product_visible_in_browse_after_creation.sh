#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_2182581265_20261101003310/api/_infra.sh

# Given
cv_step Given "a signed-in user creates a product" $LINENO
SFX=$(cv_suffix)
cv_register_user "$(cv_unique_email browse)" "Passw0rd!123" "CV Browse" $LINENO
TOKEN=$CV_TOKEN
NAME="CV Browse $SFX"
cv_create_product "$TOKEN" "$NAME" "browse desc" 12.5 "BR-$SFX" $LINENO
PID=$CV_PRODUCT_ID

# When
cv_step When "the catalog is listed with GET /products in the same runtime" $LINENO
cv_http GET /products "" -H "Authorization: Bearer $TOKEN"

# Then
cv_step Then "the newly created product is in the list with its details" $LINENO
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected 200 got $CV_HTTP_STATUS" $LINENO
P=$(printf '%s' "$CV_HTTP_BODY" | jq -c --arg id "$PID" '[.products[]? | select(.id == $id)] | first // empty')
[ -n "$P" ] || cv_fail "expected product $PID in GET /products list got none" $LINENO
[ "$(printf '%s' "$P" | jq -r .name)" = "$NAME" ] || cv_fail "expected name $NAME got $(printf '%s' "$P" | jq -r .name)" $LINENO
[ "$(printf '%s' "$P" | jq -r .description)" = "browse desc" ] || cv_fail "expected description 'browse desc' got $(printf '%s' "$P" | jq -r .description)" $LINENO
printf '%s' "$P" | jq -e '.price == 12.5' >/dev/null || cv_fail "expected price 12.5 got $(printf '%s' "$P" | jq -c .price)" $LINENO

# Cleanup
cv_step Cleanup "nothing persistent to remove (in-memory store, no delete API)" $LINENO
echo "CODEVALID_TEST_ASSERTION_OK:product_visible_in_browse_after_creation"
