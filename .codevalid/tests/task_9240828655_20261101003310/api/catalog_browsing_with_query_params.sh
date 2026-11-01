#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_9240828655_20261101003310/api/_infra.sh

# Given
cv_step Given "a registered user has created three uniquely named products" $LINENO
SFX=$(cv_suffix)
register_user "cv_qp_${SFX}@example.com" "Passw0rd!${SFX}" $LINENO
TOKEN="$CV_TOKEN"
cv_prereq "create three products" $LINENO
create_product "$TOKEN" "cvqp-${SFX}-a" "first" 1.5 $LINENO
create_product "$TOKEN" "cvqp-${SFX}-b" "second" 2.5 $LINENO
create_product "$TOKEN" "cvqp-${SFX}-c" "third" 3.5 $LINENO
cv_prereq "baseline catalog without query params" $LINENO
cv_http GET /products 200
TOTAL=$(printf '%s' "$CV_HTTP_BODY" | jq '.products | length')
[ "$TOTAL" -ge 3 ] || cv_fail "expected at least 3 products in baseline catalog got $TOTAL" $LINENO

# When
cv_step When "anonymous caller requests GET /products?page=1&size=1" $LINENO
cv_http GET "/products?page=1&size=1"

# Then
cv_step Then "response is 200 without auth and contains a constrained subset of at most 1 product" $LINENO
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected 200 got $CV_HTTP_STATUS" $LINENO
printf '%s' "$CV_HTTP_BODY" | jq -e '.products | type == "array"' >/dev/null \
  || cv_fail "expected products array in response got $(printf '%s' "$CV_HTTP_BODY" | head -c 200)" $LINENO
COUNT=$(printf '%s' "$CV_HTTP_BODY" | jq '.products | length')
[ "$COUNT" -le 1 ] || cv_fail "expected at most 1 product with size=1 (of $TOTAL total) got $COUNT" $LINENO
[ "$COUNT" -lt "$TOTAL" ] || cv_fail "expected a constrained subset smaller than full catalog ($TOTAL) got $COUNT" $LINENO

# Cleanup
cv_step Cleanup "nothing to remove (in-memory store has no delete endpoint)" $LINENO
echo "CODEVALID_TEST_ASSERTION_OK:catalog_browsing_with_query_params"
