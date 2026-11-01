#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_2182581265_20261101003310/api/_infra.sh

# Given
cv_step Given "a registered, signed-in user" $LINENO
SFX=$(cv_suffix)
cv_register_user "$(cv_unique_email missing)" "Passw0rd!123" "CV Missing" $LINENO
TOKEN=$CV_TOKEN
NAME="CV Missing $SFX"

# When
cv_step When "the user POSTs /products with missing or empty name, and with missing or empty product code" $LINENO
check_rejected() {
  local label=$1 body=$2 line=$3
  cv_post_product "$TOKEN" "$body"
  [ "$CV_HTTP_STATUS" = "400" ] || cv_fail "$label: expected 400 validation error got $CV_HTTP_STATUS" "$line"
  printf '%s' "$CV_HTTP_BODY" | jq -e '.error | type == "string"' >/dev/null || cv_fail "$label: expected .error message in body got $CV_HTTP_BODY" "$line"
  printf '%s' "$CV_HTTP_BODY" | jq -e 'has("product") | not' >/dev/null || cv_fail "$label: expected no product in body got $CV_HTTP_BODY" "$line"
}

# Then
cv_step Then "each request is rejected with 400 and no product is created" $LINENO
check_rejected "missing name" "$(jq -nc --arg c "MC-$SFX" '{description:"d",price:5,code:$c}')" $LINENO
check_rejected "empty name" "$(jq -nc --arg c "MC-$SFX" '{name:"",description:"d",price:5,code:$c}')" $LINENO
check_rejected "blank name" "$(jq -nc --arg c "MC-$SFX" '{name:"   ",description:"d",price:5,code:$c}')" $LINENO
check_rejected "empty body" '{}' $LINENO
check_rejected "missing product code" "$(jq -nc --arg n "$NAME" '{name:$n,description:"d",price:5}')" $LINENO
check_rejected "empty product code" "$(jq -nc --arg n "$NAME" '{name:$n,description:"d",price:5,code:""}')" $LINENO
cv_http GET /products 200
CNT=$(printf '%s' "$CV_HTTP_BODY" | jq --arg n "$NAME" '[.products[] | select(.name == $n)] | length')
[ "$CNT" = "0" ] || cv_fail "expected no product named $NAME to be created got $CNT" $LINENO

# Cleanup
cv_step Cleanup "nothing persistent to remove (in-memory store, no delete API)" $LINENO
echo "CODEVALID_TEST_ASSERTION_OK:missing_required_fields_validation_error"
