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
cv_step When "GET /products is sent with no Authorization header or cookie" $LINENO
cv_http GET /products

# Then
cv_step Then "catalog data is returned instead of an authentication error" $LINENO
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected 200 got $CV_HTTP_STATUS" $LINENO
N=$(printf "%s" "$CV_HTTP_BODY" | jq --arg id "$PID" "[.products[]? | select(.id == \$id)] | length")
[ "$N" = "1" ] || cv_fail "expected created product $PID in catalog got $N matches" $LINENO

# Cleanup
cv_step Cleanup "nothing to remove: the app keeps data in memory and exposes no delete route" $LINENO
echo "created product ${PID:-none} stays in the in-memory store until restart"
echo "CODEVALID_TEST_ASSERTION_OK:catalog_access_without_auth_headers"
