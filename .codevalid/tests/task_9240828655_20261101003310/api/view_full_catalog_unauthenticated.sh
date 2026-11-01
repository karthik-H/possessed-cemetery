#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_9240828655_20261101003310/api/_infra.sh

# Given
cv_step Given "a registered user has created two products" $LINENO
SUFFIX=$(cv_suffix)
register_user "cv_cat_${SUFFIX}@example.com" "Passw0rd!${SUFFIX}" $LINENO
create_product "$CV_TOKEN" "CV Catalog A ${SUFFIX}" "A ${SUFFIX}" 10 $LINENO
PID="$CV_PRODUCT_ID"
create_product "$CV_TOKEN" "CV Catalog B ${SUFFIX}" "B ${SUFFIX}" 20.5 $LINENO
PID2="$CV_PRODUCT_ID"

# When
cv_step When "an anonymous caller requests GET /products" $LINENO
cv_http GET /products

# Then
cv_step Then "the catalog is returned with both products" $LINENO
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected 200 got $CV_HTTP_STATUS" $LINENO
TYPE=$(printf "%s" "$CV_HTTP_BODY" | jq -r ".products | type")
[ "$TYPE" = "array" ] || cv_fail "expected products array got $TYPE" $LINENO
for id in "$PID" "$PID2"; do
  N=$(printf "%s" "$CV_HTTP_BODY" | jq --arg id "$id" "[.products[] | select(.id == \$id)] | length")
  [ "$N" = "1" ] || cv_fail "expected product $id in catalog once got $N" $LINENO
done
NAME=$(printf "%s" "$CV_HTTP_BODY" | jq -r --arg id "$PID" ".products[] | select(.id == \$id) | .name")
[ "$NAME" = "CV Catalog A ${SUFFIX}" ] || cv_fail "expected name CV Catalog A ${SUFFIX} got $NAME" $LINENO

# Cleanup
cv_step Cleanup "nothing to remove: the app keeps data in memory and exposes no delete route" $LINENO
echo "created product ${PID:-none} stays in the in-memory store until restart"
echo "CODEVALID_TEST_ASSERTION_OK:view_full_catalog_unauthenticated"
