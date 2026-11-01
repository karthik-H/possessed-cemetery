#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_2182581265_20261101003310/api/_infra.sh

# Given
cv_step Given "a signed-in user added products that are visible via GET /products" $LINENO
SFX=$(cv_suffix)
cv_register_user "$(cv_unique_email restartlist)" "Passw0rd!123" "CV RestartList" $LINENO
TOKEN=$CV_TOKEN
cv_create_product "$TOKEN" "CV RL-A $SFX" "a" 1 "RLA-$SFX" $LINENO
IDA=$CV_PRODUCT_ID
cv_create_product "$TOKEN" "CV RL-B $SFX" "b" 2 "RLB-$SFX" $LINENO
IDB=$CV_PRODUCT_ID
cv_http GET /products "" 200 -H "Authorization: Bearer $TOKEN"
for id in "$IDA" "$IDB"; do
  printf '%s' "$CV_HTTP_BODY" | jq -e --arg id "$id" 'any(.products[]; .id == $id)' >/dev/null || cv_fail "expected product $id listed before restart" $LINENO
done

# When
cv_step When "the service restarts and the same user calls GET /products" $LINENO
cv_restart_app $LINENO
cv_http GET /products "" -H "Authorization: Bearer $TOKEN"

# Then
cv_step Then "200 and none of the previously added products are in the catalog" $LINENO
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected 200 got $CV_HTTP_STATUS" $LINENO
printf '%s' "$CV_HTTP_BODY" | jq -e '.products | type == "array"' >/dev/null || cv_fail "expected .products array got $CV_HTTP_BODY" $LINENO
for id in "$IDA" "$IDB"; do
  if printf '%s' "$CV_HTTP_BODY" | jq -e --arg id "$id" 'any(.products[]; .id == $id)' >/dev/null; then
    cv_fail "expected product $id absent after restart got it listed" $LINENO
  fi
done

# Cleanup
cv_step Cleanup "nothing to remove (restart wiped the in-memory store)" $LINENO
echo "CODEVALID_TEST_ASSERTION_OK:list_products_after_service_restart"
