#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_2182581265_20261101003310/api/_infra.sh

# Given
cv_step Given "the catalog holds a product added by a signed-in user" $LINENO
SFX=$(cv_suffix)
cv_register_user "$(cv_unique_email unauth)" "Passw0rd!123" "CV Unauth" $LINENO
NAME="CV Unauth $SFX"
cv_create_product "$CV_TOKEN" "$NAME" "secret desc" 9 "UA-$SFX" $LINENO
PID=$CV_PRODUCT_ID

# When
cv_step When "an unauthenticated client calls GET /products without a token" $LINENO
cv_http GET /products

# Then
cv_step Then "access is denied with 401 or 403 and no product data is exposed" $LINENO
case "$CV_HTTP_STATUS" in 401|403) ;; *) cv_fail "expected 401 or 403 for unauthenticated GET /products got $CV_HTTP_STATUS" $LINENO ;; esac
case "$CV_HTTP_BODY" in *"$PID"*|*"$NAME"*) cv_fail "expected no product data in denied response got $CV_HTTP_BODY" $LINENO ;; esac

# Cleanup
cv_step Cleanup "nothing persistent to remove (in-memory store, no delete API)" $LINENO
echo "CODEVALID_TEST_ASSERTION_OK:list_products_unauthorized_user"
