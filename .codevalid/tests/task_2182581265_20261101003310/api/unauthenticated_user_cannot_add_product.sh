#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_2182581265_20261101003310/api/_infra.sh

# Given
cv_step Given "a unique product payload and no valid credentials" $LINENO
SFX=$(cv_suffix)
PNAME="CV Unauth $SFX"
BODY=$(cv_product_body "$PNAME" "should not exist" 5 "UNAUTH-$SFX")

# When
cv_step When "POST /products without a token and with a bogus token" $LINENO
cv_post_product "" "$BODY"
S1=$CV_HTTP_STATUS
cv_post_product "not.a.validtoken" "$BODY"
S2=$CV_HTTP_STATUS

# Then
cv_step Then "both requests are rejected with 401 and no product is created" $LINENO
[ "$S1" = "401" ] || cv_fail "expected 401 without token got $S1" $LINENO
[ "$S2" = "401" ] || cv_fail "expected 401 with invalid token got $S2" $LINENO
cv_http GET /products 200
N=$(printf '%s' "$CV_HTTP_BODY" | jq --arg n "$PNAME" '[.products[] | select(.name == $n)] | length')
[ "$N" = "0" ] || cv_fail "expected 0 products named $PNAME got $N" $LINENO

# Cleanup
cv_step Cleanup "No delete endpoints exist; users/products live in the in-memory store and use unique values" $LINENO
echo "in-memory data with unique suffix left in place (no delete API)"

echo "CODEVALID_TEST_ASSERTION_OK:unauthenticated_user_cannot_add_product"
