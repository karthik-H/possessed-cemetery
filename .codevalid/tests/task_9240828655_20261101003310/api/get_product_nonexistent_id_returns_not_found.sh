#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_9240828655_20261101003310/api/_infra.sh

# Given
cv_step Given "a product id that does not exist" $LINENO
PID=""
MISSING_ID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || printf "00000000-0000-4000-8000-%012d" "$(( $(date +%s) % 1000000000000 ))")
cv_http GET /health 200

# When
cv_step When "an anonymous caller requests GET /products/{missing id}" $LINENO
cv_http GET "/products/${MISSING_ID}"

# Then
cv_step Then "a 404 not-found response is returned without product data" $LINENO
[ "$CV_HTTP_STATUS" = "404" ] || cv_fail "expected 404 got $CV_HTTP_STATUS" $LINENO
HAS=$(printf "%s" "$CV_HTTP_BODY" | jq -r "has(\"product\")")
[ "$HAS" = "false" ] || cv_fail "expected no product in body got $CV_HTTP_BODY" $LINENO
ERR=$(printf "%s" "$CV_HTTP_BODY" | jq -r ".error // empty")
[ -n "$ERR" ] || cv_fail "expected an error message got none" $LINENO

# Cleanup
cv_step Cleanup "nothing to remove: the app keeps data in memory and exposes no delete route" $LINENO
echo "created product ${PID:-none} stays in the in-memory store until restart"
echo "CODEVALID_TEST_ASSERTION_OK:get_product_nonexistent_id_returns_not_found"
