#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_9240828655_20261101003310/api/_infra.sh

# Given
cv_step Given "a registered user has created three products" $LINENO
SUFFIX=$(cv_suffix)
register_user "cv_qp_${SUFFIX}@example.com" "Passw0rd!${SUFFIX}" $LINENO
for i in 1 2 3; do
  create_product "$CV_TOKEN" "CV Paged ${i} ${SUFFIX}" "Paged ${SUFFIX}" "$i" $LINENO
done
PID="$CV_PRODUCT_ID"

# When
cv_step When "an anonymous caller requests GET /products?page=1&size=1" $LINENO
cv_http GET "/products?page=1&size=1"

# Then
cv_step Then "a constrained subset of at most one product is returned" $LINENO
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected 200 got $CV_HTTP_STATUS" $LINENO
TYPE=$(printf "%s" "$CV_HTTP_BODY" | jq -r ".products | type")
[ "$TYPE" = "array" ] || cv_fail "expected products array got $TYPE" $LINENO
COUNT=$(printf "%s" "$CV_HTTP_BODY" | jq ".products | length")
[ "$COUNT" -ge 1 ] || cv_fail "expected at least 1 product on page 1 got $COUNT" $LINENO
[ "$COUNT" -le 1 ] || cv_fail "expected at most 1 product with size=1 got $COUNT" $LINENO

# Cleanup
cv_step Cleanup "nothing to remove: the app keeps data in memory and exposes no delete route" $LINENO
echo "created product ${PID:-none} stays in the in-memory store until restart"
echo "CODEVALID_TEST_ASSERTION_OK:catalog_browsing_with_query_params"
