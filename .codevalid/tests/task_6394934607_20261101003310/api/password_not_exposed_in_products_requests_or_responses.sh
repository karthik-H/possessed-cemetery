#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_6394934607_20261101003310/api/_infra.sh

# Given
cv_step Given "a signed-in registered customer" $LINENO
EMAIL=$(cv_unique_email privacy)
PASSWORD="Secret-$(cv_suffix)-pw"
cv_register_user "$EMAIL" "$PASSWORD" "Privacy" $LINENO
cv_login "$EMAIL" "$PASSWORD"
[ "$CV_HTTP_STATUS" = "200" ] && [ -n "$CV_LOGIN_TOKEN" ] || cv_fail "expected login 200 with token got $CV_HTTP_STATUS" $LINENO
TOKEN=$CV_LOGIN_TOKEN
PNAME="cv-private-$(cv_suffix)"

# When
cv_step When "the customer posts a product and the catalog is read back" $LINENO
cv_post_product "$TOKEN" "$(jq -nc --arg n "$PNAME" '{name:$n,price:4}')"
POST_STATUS=$CV_HTTP_STATUS
POST_BODY=$CV_HTTP_BODY
POST_HEADERS=$(cat "$CV_HTTP_HEADERS_FILE")
PID=$(printf '%s' "$POST_BODY" | jq -r '.product.id // empty')
cv_http GET /products 200
LIST_BODY=$CV_HTTP_BODY
cv_post_product "$TOKEN" '{"name":"","price":-1}'
ERR_BODY=$CV_HTTP_BODY

# Then
cv_step Then "no password, password hash or token payload secret appears in any response" $LINENO
[ "$POST_STATUS" = "201" ] || cv_fail "expected 201 got $POST_STATUS" $LINENO
[ -n "$PID" ] || cv_fail "expected product id" $LINENO
for b in "$POST_BODY" "$LIST_BODY" "$ERR_BODY" "$POST_HEADERS"; do
  CV_HTTP_BODY=$b
  if cv_body_leaks "$PASSWORD" "$APP_JWT_SECRET"; then cv_fail "expected no password/secret in response got: $(printf '%s' "$b" | head -c 200)" $LINENO; fi
done
CV_HTTP_BODY=$POST_BODY
if cv_body_leaks "$TOKEN"; then cv_fail "expected bearer token not echoed in product response" $LINENO; fi

# Cleanup
cv_step Cleanup "nothing persistent to remove (in-memory store, no delete API)" $LINENO
echo "CODEVALID_TEST_ASSERTION_OK:password_not_exposed_in_products_requests_or_responses"
