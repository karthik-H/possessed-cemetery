#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_2182581265_20261101003310/api/_infra.sh

# Given
cv_step Given "a signed-in user and an existing product with a known code" $LINENO
SFX=$(cv_suffix)
cv_register_user "$(cv_unique_email dup)" "Passw0rd!123" "CV Dup" $LINENO
TOKEN=$CV_TOKEN
PCODE="DUP-$SFX"
cv_create_product "$TOKEN" "CV First $SFX" "first" 10 "$PCODE" $LINENO
DUPNAME="CV Second $SFX"

# When
cv_step When "POST /products with a different product but the same code" $LINENO
cv_post_product "$TOKEN" "$(cv_product_body "$DUPNAME" "second" 12 "$PCODE")"

# Then
cv_step Then "request rejected (4xx, typically 409) and no second product created" $LINENO
case "$CV_HTTP_STATUS" in 409|400|422) ;; *) cv_fail "expected 409/400/422 for duplicate code got $CV_HTTP_STATUS" $LINENO ;; esac
cv_http GET /products 200
N=$(printf '%s' "$CV_HTTP_BODY" | jq --arg n "$DUPNAME" '[.products[] | select(.name == $n)] | length')
[ "$N" = "0" ] || cv_fail "expected 0 products named $DUPNAME got $N" $LINENO

# Cleanup
cv_step Cleanup "No delete endpoints exist; users/products live in the in-memory store and use unique values" $LINENO
echo "in-memory data with unique suffix left in place (no delete API)"

echo "CODEVALID_TEST_ASSERTION_OK:duplicate_product_code_rejected"
