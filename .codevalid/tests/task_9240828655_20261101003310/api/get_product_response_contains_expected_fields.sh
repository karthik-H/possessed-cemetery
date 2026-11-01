#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_9240828655_20261101003310/api/_infra.sh

# Given
cv_step Given "a registered user has created a product" $LINENO
SUFFIX=$(cv_suffix)
register_user "cv_prod_${SUFFIX}@example.com" "Passw0rd!${SUFFIX}" $LINENO
PNAME="CV Product ${SUFFIX}"
create_product "$CV_TOKEN" "$PNAME" "Description ${SUFFIX}" 19.99 $LINENO
PID="$CV_PRODUCT_ID"

# When
cv_step When "an anonymous caller requests GET /products/{id}" $LINENO
cv_http GET "/products/${PID}"

# Then
cv_step Then "the product payload has id, name, description and price with correct types and values" $LINENO
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected 200 got $CV_HTTP_STATUS" $LINENO
P=$(printf "%s" "$CV_HTTP_BODY" | jq -c ".product // empty")
[ -n "$P" ] || cv_fail "expected product object got $CV_HTTP_BODY" $LINENO
for f in id name description; do
  T=$(printf "%s" "$P" | jq -r ".$f | type")
  [ "$T" = "string" ] || cv_fail "expected product.$f string got $T" $LINENO
done
T=$(printf "%s" "$P" | jq -r ".price | type")
[ "$T" = "number" ] || cv_fail "expected product.price number got $T" $LINENO
[ "$(printf "%s" "$P" | jq -r .id)" = "$PID" ] || cv_fail "expected id $PID got $(printf "%s" "$P" | jq -r .id)" $LINENO
[ "$(printf "%s" "$P" | jq -r .name)" = "$PNAME" ] || cv_fail "expected name $PNAME got $(printf "%s" "$P" | jq -r .name)" $LINENO
[ "$(printf "%s" "$P" | jq -r .description)" = "Description ${SUFFIX}" ] || cv_fail "expected description Description ${SUFFIX} got $(printf "%s" "$P" | jq -r .description)" $LINENO
[ "$(printf "%s" "$P" | jq -r .price)" = "19.99" ] || cv_fail "expected price 19.99 got $(printf "%s" "$P" | jq -r .price)" $LINENO

# Cleanup
cv_step Cleanup "nothing to remove: the app keeps data in memory and exposes no delete route" $LINENO
echo "created product ${PID:-none} stays in the in-memory store until restart"
echo "CODEVALID_TEST_ASSERTION_OK:get_product_response_contains_expected_fields"
