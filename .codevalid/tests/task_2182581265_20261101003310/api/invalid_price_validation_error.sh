#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_2182581265_20261101003310/api/_infra.sh

# Given
cv_step Given "a signed-in user and payloads with negative and non-numeric prices" $LINENO
SFX=$(cv_suffix)
cv_register_user "$(cv_unique_email price)" "Passw0rd!123" "CV Price" $LINENO
TOKEN=$CV_TOKEN
NEG="CV Neg $SFX"; STR="CV Str $SFX"

# When
cv_step When "POST /products with price -5 and with price \"abc\"" $LINENO
cv_post_product "$TOKEN" "$(cv_product_body "$NEG" "neg" -5 "NEG-$SFX")"
S1=$CV_HTTP_STATUS; B1=$CV_HTTP_BODY
cv_post_product "$TOKEN" "$(cv_product_body "$STR" "str" '"abc"' "STR-$SFX")"
S2=$CV_HTTP_STATUS; B2=$CV_HTTP_BODY

# Then
cv_step Then "both return 400 validation errors mentioning price and nothing is created" $LINENO
[ "$S1" = "400" ] || cv_fail "expected 400 for negative price got $S1" $LINENO
[ "$S2" = "400" ] || cv_fail "expected 400 for non-numeric price got $S2" $LINENO
printf '%s' "$B1" | jq -e '.details.price' >/dev/null || cv_fail "expected price validation detail for negative price got $B1" $LINENO
printf '%s' "$B2" | jq -e '.details.price' >/dev/null || cv_fail "expected price validation detail for non-numeric price got $B2" $LINENO
cv_http GET /products 200
N=$(printf '%s' "$CV_HTTP_BODY" | jq --arg a "$NEG" --arg b "$STR" '[.products[] | select(.name == $a or .name == $b)] | length')
[ "$N" = "0" ] || cv_fail "expected no invalid-price products created got $N" $LINENO

# Cleanup
cv_step Cleanup "No delete endpoints exist; users/products live in the in-memory store and use unique values" $LINENO
echo "in-memory data with unique suffix left in place (no delete API)"

echo "CODEVALID_TEST_ASSERTION_OK:invalid_price_validation_error"
