#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_2182581265_20261101003310/api/_infra.sh

# Given
cv_step Given "a signed-in user added a product that is visible in the catalog" $LINENO
SFX=$(cv_suffix)
cv_register_user "$(cv_unique_email persist)" "Passw0rd!123" "CV Persist" $LINENO
NAME="CV Persist $SFX"
cv_create_product "$CV_TOKEN" "$NAME" "persist desc" 4 "PS-$SFX" $LINENO
PID=$CV_PRODUCT_ID
cv_http GET /products 200
printf '%s' "$CV_HTTP_BODY" | jq -e --arg id "$PID" 'any(.products[]; .id == $id)' >/dev/null || cv_fail "expected product $PID listed before restart" $LINENO

# When
cv_step When "the service is restarted" $LINENO
cv_restart_app $LINENO

# Then
cv_step Then "the previously added product is no longer returned" $LINENO
cv_http GET /products
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected 200 from GET /products after restart got $CV_HTTP_STATUS" $LINENO
if printf '%s' "$CV_HTTP_BODY" | jq -e --arg id "$PID" --arg n "$NAME" 'any(.products[]?; .id == $id or .name == $n)' >/dev/null; then
  cv_fail "expected product $PID absent after restart got it listed" $LINENO
fi
cv_http GET "/products/$PID"
[ "$CV_HTTP_STATUS" = "404" ] || cv_fail "expected 404 for GET /products/$PID after restart got $CV_HTTP_STATUS" $LINENO

# Cleanup
cv_step Cleanup "nothing to remove (restart wiped the in-memory store)" $LINENO
echo "CODEVALID_TEST_ASSERTION_OK:products_not_persisted_across_restart"
