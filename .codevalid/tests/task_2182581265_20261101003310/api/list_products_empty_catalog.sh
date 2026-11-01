#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_2182581265_20261101003310/api/_infra.sh

# Given
cv_step Given "a fresh service with no products and a signed-in user" $LINENO
cv_prereq "restart the app so the in-memory catalog is empty" $LINENO
cv_restart_app $LINENO
cv_register_user "$(cv_unique_email empty)" "Passw0rd!123" "CV Empty" $LINENO
TOKEN=$CV_TOKEN

# When
cv_step When "the signed-in user calls GET /products" $LINENO
cv_http GET /products "" -H "Authorization: Bearer $TOKEN"

# Then
cv_step Then "200 with an empty products list, not an error" $LINENO
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected 200 got $CV_HTTP_STATUS" $LINENO
printf '%s' "$CV_HTTP_BODY" | jq -e '.products | type == "array" and length == 0' >/dev/null || cv_fail "expected empty .products array got $CV_HTTP_BODY" $LINENO

# Cleanup
cv_step Cleanup "nothing persistent to remove (in-memory store, no delete API)" $LINENO
echo "CODEVALID_TEST_ASSERTION_OK:list_products_empty_catalog"
