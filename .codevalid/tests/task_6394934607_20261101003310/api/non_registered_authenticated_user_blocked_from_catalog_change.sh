#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_6394934607_20261101003310/api/_infra.sh

# Given
cv_step Given "a correctly signed token whose subject is not a registered customer" $LINENO
GHOST_ID="00000000-0000-4000-8000-$(printf '%012d' $((RANDOM*RANDOM)))"
GHOST_EMAIL=$(cv_unique_email ghost)
cv_login "$GHOST_EMAIL" "Ghost-$(cv_suffix)-pw"
[ "$CV_HTTP_STATUS" = "401" ] || cv_fail "expected ghost email not registered (login 401) got $CV_HTTP_STATUS" $LINENO
NOW=$(date +%s)
TOKEN=$(cv_jwt_hs256 "$APP_JWT_SECRET" "$(jq -nc --arg s "$GHOST_ID" --arg e "$GHOST_EMAIL" --argjson i "$NOW" --argjson x $((NOW+3600)) '{sub:$s,email:$e,iat:$i,exp:$x}')")
PNAME="cv-ghost-$(cv_suffix)"

# When
cv_step When "the non-registered identity posts a catalog change" $LINENO
cv_post_product "$TOKEN" "$(jq -nc --arg n "$PNAME" '{name:$n,price:9}')"

# Then
cv_step Then "the request is denied (401/403) and the catalog is not modified" $LINENO
case "$CV_HTTP_STATUS" in 401|403) ;; *) cv_fail "expected 401 or 403 got $CV_HTTP_STATUS" $LINENO ;; esac
[ "$(cv_product_count_named "$PNAME")" = "0" ] || cv_fail "expected no product $PNAME created" $LINENO

# Cleanup
cv_step Cleanup "nothing persistent to remove (nothing was created)" $LINENO
echo "CODEVALID_TEST_ASSERTION_OK:non_registered_authenticated_user_blocked_from_catalog_change"
