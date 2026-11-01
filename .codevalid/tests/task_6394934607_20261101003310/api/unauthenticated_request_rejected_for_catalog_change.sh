#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_6394934607_20261101003310/api/_infra.sh

# Given
cv_step Given "a unique product name not yet in the catalog" $LINENO
PNAME="cv-unauth-$(cv_suffix)"
[ "$(cv_product_count_named "$PNAME")" = "0" ] || cv_fail "expected product $PNAME absent before test" $LINENO

# When
cv_step When "POST /products is called without any authentication" $LINENO
cv_post_product "" "$(jq -nc --arg n "$PNAME" '{name:$n,price:5}')"
NOAUTH=$CV_HTTP_STATUS
cv_http POST /products "$(jq -nc --arg n "$PNAME" '{name:$n,price:5}')" -H "Authorization: Basic Zm9vOmJhcg=="
BASIC=$CV_HTTP_STATUS
cv_http POST /products "$(jq -nc --arg n "$PNAME" '{name:$n,price:5}')" -H "Authorization: Bearer "
EMPTY=$CV_HTTP_STATUS

# Then
cv_step Then "requests are rejected with 401 and no product is created" $LINENO
[ "$NOAUTH" = "401" ] || cv_fail "expected 401 without auth got $NOAUTH" $LINENO
[ "$BASIC" = "401" ] || cv_fail "expected 401 with non-bearer auth got $BASIC" $LINENO
[ "$EMPTY" = "401" ] || cv_fail "expected 401 with empty bearer got $EMPTY" $LINENO
[ "$(cv_product_count_named "$PNAME")" = "0" ] || cv_fail "expected no product $PNAME created" $LINENO

# Cleanup
cv_step Cleanup "nothing persistent to remove (nothing was created)" $LINENO
echo "CODEVALID_TEST_ASSERTION_OK:unauthenticated_request_rejected_for_catalog_change"
