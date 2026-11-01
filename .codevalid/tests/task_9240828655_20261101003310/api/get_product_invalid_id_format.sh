#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_9240828655_20261101003310/api/_infra.sh

# Given
cv_step Given "a malformed product id" $LINENO
PID=""
BAD_ID="not-a-valid-id_%24%40%21"
cv_http GET /health 200

# When
cv_step When "an anonymous caller requests GET /products/{malformed id}" $LINENO
cv_http GET "/products/${BAD_ID}"

# Then
cv_step Then "a 4xx client error is returned without product data" $LINENO
case "$CV_HTTP_STATUS" in 4??) ;; *) cv_fail "expected a 4xx client error got $CV_HTTP_STATUS" $LINENO ;; esac
case "$CV_HTTP_STATUS" in 401|403) cv_fail "expected a client error other than auth got $CV_HTTP_STATUS" $LINENO ;; esac
HAS=$(printf "%s" "$CV_HTTP_BODY" | jq -r "has(\"product\")" 2>/dev/null || echo false)
[ "$HAS" = "false" ] || cv_fail "expected no product in body got $CV_HTTP_BODY" $LINENO

# Cleanup
cv_step Cleanup "nothing to remove: the app keeps data in memory and exposes no delete route" $LINENO
echo "created product ${PID:-none} stays in the in-memory store until restart"
echo "CODEVALID_TEST_ASSERTION_OK:get_product_invalid_id_format"
