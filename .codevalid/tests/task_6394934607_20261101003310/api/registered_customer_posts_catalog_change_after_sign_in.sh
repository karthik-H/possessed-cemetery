#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_6394934607_20261101003310/api/_infra.sh

# Given
cv_step Given "a registered customer signs in" $LINENO
EMAIL=$(cv_unique_email poster)
PASSWORD="Pw-$(cv_suffix)-post"
cv_register_user "$EMAIL" "$PASSWORD" "Poster" $LINENO
USER_ID=$CV_USER_ID
cv_login "$EMAIL" "$PASSWORD"
[ "$CV_HTTP_STATUS" = "200" ] && [ -n "$CV_LOGIN_TOKEN" ] || cv_fail "expected login 200 with token got $CV_HTTP_STATUS" $LINENO
TOKEN=$CV_LOGIN_TOKEN
PNAME="cv-widget-$(cv_suffix)"

# When
cv_step When "the customer posts a new product" $LINENO
cv_post_product "$TOKEN" "$(jq -nc --arg n "$PNAME" '{name:$n,description:"A test widget",price:19.99}')"

# Then
cv_step Then "201 with the product, createdBy is the customer, and it appears in the catalog" $LINENO
[ "$CV_HTTP_STATUS" = "201" ] || cv_fail "expected 201 got $CV_HTTP_STATUS" $LINENO
P=$(printf '%s' "$CV_HTTP_BODY" | jq -c '.product')
[ "$(printf '%s' "$P" | jq -r '.name')" = "$PNAME" ] || cv_fail "expected name $PNAME got $P" $LINENO
[ "$(printf '%s' "$P" | jq -r '.price')" = "19.99" ] || cv_fail "expected price 19.99 got $P" $LINENO
[ "$(printf '%s' "$P" | jq -r '.description')" = "A test widget" ] || cv_fail "expected description got $P" $LINENO
[ "$(printf '%s' "$P" | jq -r '.createdBy')" = "$USER_ID" ] || cv_fail "expected createdBy $USER_ID got $P" $LINENO
PID=$(printf '%s' "$P" | jq -r '.id')
[ -n "$PID" ] && [ "$PID" != "null" ] || cv_fail "expected product id" $LINENO
cv_http GET "/products/$PID" 200
[ "$(printf '%s' "$CV_HTTP_BODY" | jq -r '.product.name')" = "$PNAME" ] || cv_fail "expected GET product name $PNAME" $LINENO

# Cleanup
cv_step Cleanup "nothing persistent to remove (in-memory store, no delete API)" $LINENO
echo "CODEVALID_TEST_ASSERTION_OK:registered_customer_posts_catalog_change_after_sign_in"
