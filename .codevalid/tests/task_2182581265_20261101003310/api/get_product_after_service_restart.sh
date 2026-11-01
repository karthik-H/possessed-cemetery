#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_2182581265_20261101003310/api/_infra.sh

# Given
cv_step Given "a product was added and is retrievable by id" $LINENO
SFX=$(cv_suffix)
cv_register_user "$(cv_unique_email restart)" "Passw0rd!123" "CV Restart" $LINENO
cv_create_product "$CV_TOKEN" "CV Restart $SFX" "restart desc" 7 "RS-$SFX" $LINENO
PID=$CV_PRODUCT_ID
cv_http GET "/products/$PID" 200

# When
cv_step When "the service restarts and the product id is requested again" $LINENO
cv_restart_app $LINENO
cv_http GET "/products/$PID"

# Then
cv_step Then "the product is not found (404 with error JSON)" $LINENO
[ "$CV_HTTP_STATUS" = "404" ] || cv_fail "expected 404 after restart got $CV_HTTP_STATUS" $LINENO
printf '%s' "$CV_HTTP_BODY" | jq -e '.error | type == "string"' >/dev/null || cv_fail "expected JSON error message got $CV_HTTP_BODY" $LINENO
if printf '%s' "$CV_HTTP_BODY" | jq -e '.product' >/dev/null 2>&1; then cv_fail "expected no product in body got $CV_HTTP_BODY" $LINENO; fi

# Cleanup
cv_step Cleanup "nothing to remove (restart wiped the in-memory store)" $LINENO
echo "CODEVALID_TEST_ASSERTION_OK:get_product_after_service_restart"
