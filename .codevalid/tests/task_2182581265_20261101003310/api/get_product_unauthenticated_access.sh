#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_2182581265_20261101003310/api/_infra.sh

# Given
cv_step Given "an existing product created by a signed-in user" $LINENO
SFX=$(cv_suffix)
cv_register_user "$(cv_unique_email getunauth)" "Passw0rd!123" "CV GetUnauth" $LINENO
NAME="CV GetUnauth $SFX"
cv_create_product "$CV_TOKEN" "$NAME" "open browse" 6.25 "GU-$SFX" $LINENO
PID=$CV_PRODUCT_ID

# When
cv_step When "an unauthenticated client calls GET /products/{id}" $LINENO
cv_http GET "/products/$PID"
ID_STATUS=$CV_HTTP_STATUS
ID_BODY=$CV_HTTP_BODY

# Then
cv_step Then "response follows the browse policy consistently: product returned if open, denied without data if restricted" $LINENO
cv_http GET /products
LIST_STATUS=$CV_HTTP_STATUS
case "$ID_STATUS" in
  200)
    printf '%s' "$ID_BODY" | jq -e --arg id "$PID" --arg n "$NAME" '.product.id == $id and .product.name == $n and .product.description == "open browse" and .product.price == 6.25' >/dev/null || cv_fail "expected product $PID details in body got $ID_BODY" $LINENO
    [ "$LIST_STATUS" = "200" ] || cv_fail "expected browse policy consistent (list 200 when detail open) got list $LIST_STATUS" $LINENO
    ;;
  401|403)
    case "$ID_BODY" in *"$NAME"*) cv_fail "expected no product data in denied response got $ID_BODY" $LINENO ;; esac
    case "$LIST_STATUS" in 401|403) ;; *) cv_fail "expected browse policy consistent (list denied when detail denied) got list $LIST_STATUS" $LINENO ;; esac
    ;;
  *) cv_fail "expected 200 (open browse) or 401/403 (restricted) got $ID_STATUS" $LINENO ;;
esac

# Cleanup
cv_step Cleanup "nothing persistent to remove (in-memory store, no delete API)" $LINENO
echo "CODEVALID_TEST_ASSERTION_OK:get_product_unauthenticated_access"
