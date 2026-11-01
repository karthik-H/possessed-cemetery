#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_6394934607_20261101003310/api/_infra.sh

# Given
cv_step Given "a registered customer and expired, tampered, wrongly signed and garbage tokens for them" $LINENO
EMAIL=$(cv_unique_email expired)
PASSWORD="Pw-$(cv_suffix)-exp"
cv_register_user "$EMAIL" "$PASSWORD" "Expired" $LINENO
USER_ID=$CV_USER_ID
VALID=$CV_TOKEN
NOW=$(date +%s)
EXPIRED=$(cv_jwt_hs256 "$APP_JWT_SECRET" "$(jq -nc --arg s "$USER_ID" --arg e "$EMAIL" --argjson i $((NOW-7200)) --argjson x $((NOW-3600)) '{sub:$s,email:$e,iat:$i,exp:$x}')")
WRONGSIG=$(cv_jwt_hs256 "not-the-app-secret-$(cv_suffix)" "$(jq -nc --arg s "$USER_ID" --argjson i "$NOW" '{sub:$s,iat:$i}')")
SIG=${VALID##*.}
C=${SIG:5:1}
[ "$C" = "A" ] && R=B || R=A
TAMPERED="${VALID%.*}.${SIG:0:5}${R}${SIG:6}"
GARBAGE="not.a.jwt"
PNAME="cv-badtoken-$(cv_suffix)"
BODY=$(jq -nc --arg n "$PNAME" '{name:$n,price:7}')

# When
cv_step When "POST /products is called with each invalid or expired token" $LINENO
STATUSES=""
for t in "$EXPIRED" "$WRONGSIG" "$TAMPERED" "$GARBAGE"; do
  cv_post_product "$t" "$BODY"
  STATUSES="$STATUSES $CV_HTTP_STATUS"
done

# Then
cv_step Then "every request is rejected with 401 and no product is created" $LINENO
for s in $STATUSES; do
  [ "$s" = "401" ] || cv_fail "expected 401 for every invalid token got statuses:$STATUSES" $LINENO
done
[ "$(cv_product_count_named "$PNAME")" = "0" ] || cv_fail "expected no product $PNAME created" $LINENO

# Cleanup
cv_step Cleanup "nothing persistent to remove (in-memory store, no delete API)" $LINENO
echo "CODEVALID_TEST_ASSERTION_OK:invalid_or_expired_authentication_rejected_for_catalog_change"
