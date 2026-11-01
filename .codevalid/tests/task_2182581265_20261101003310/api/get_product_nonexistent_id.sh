#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_2182581265_20261101003310/api/_infra.sh

# Given
cv_step Given "a product id that was never created and a healthy service" $LINENO
cv_http GET /health 200
MISSING_ID="00000000-0000-4000-8000-$(printf '%012d' "$((RANDOM * RANDOM))")"

# When
cv_step When "a client requests GET /products/{id} for the missing id" $LINENO
cv_http GET "/products/$MISSING_ID"

# Then
cv_step Then "404 not-found with an error message and the service stays healthy" $LINENO
[ "$CV_HTTP_STATUS" = "404" ] || cv_fail "expected 404 got $CV_HTTP_STATUS" $LINENO
printf '%s' "$CV_HTTP_BODY" | jq -e '(.error | type == "string") and (has("product") | not)' >/dev/null || cv_fail "expected .error and no product got $CV_HTTP_BODY" $LINENO
cv_http GET /health 200

# Cleanup
cv_step Cleanup "nothing created" $LINENO
echo "CODEVALID_TEST_ASSERTION_OK:get_product_nonexistent_id"
