#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_9240828655_20261101003310/api/_infra.sh

# Given
cv_step Given "a registered user has created a product" $LINENO
SUFFIX=$(cv_suffix)
register_user "cv_prod_${SUFFIX}@example.com" "Passw0rd!${SUFFIX}" $LINENO
PNAME="CV Product ${SUFFIX}"
create_product "$CV_TOKEN" "$PNAME" "Description ${SUFFIX}" 19.99 $LINENO
PID="$CV_PRODUCT_ID"

# When
cv_step When "GET /products/{id} is sent without any token or session cookie" $LINENO
cv_http GET "/products/${PID}"

# Then
cv_step Then "the product details are returned, not an auth error" $LINENO
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected 200 got $CV_HTTP_STATUS" $LINENO
GOT_ID=$(printf "%s" "$CV_HTTP_BODY" | jq -r ".product.id // empty")
[ "$GOT_ID" = "$PID" ] || cv_fail "expected product.id $PID got $GOT_ID" $LINENO
GOT_NAME=$(printf "%s" "$CV_HTTP_BODY" | jq -r ".product.name // empty")
[ "$GOT_NAME" = "$PNAME" ] || cv_fail "expected product.name $PNAME got $GOT_NAME" $LINENO
GOT_PRICE=$(printf "%s" "$CV_HTTP_BODY" | jq -r ".product.price // empty")
[ "$GOT_PRICE" = "19.99" ] || cv_fail "expected product.price 19.99 got $GOT_PRICE" $LINENO

# Cleanup
cv_step Cleanup "nothing to remove: the app keeps data in memory and exposes no delete route" $LINENO
echo "created product ${PID:-none} stays in the in-memory store until restart"
echo "CODEVALID_TEST_ASSERTION_OK:get_product_without_auth_token"
