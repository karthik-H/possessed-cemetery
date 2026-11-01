#!/usr/bin/env bash
set -uo pipefail
source .codevalid/tests/task_9240828655_20261101003310/api/_infra.sh

CAT="access"
TITLE="Lack of authentication allows scraping of complete product details"
PUBLIC_KEYS='["id","name","description","price","createdAt"]'

cv_step Given "owner registers and creates a product" $LINENO
SFX=$(cv_suffix)
cv_http POST /auth/register "{\"email\":\"cv_sec_${SFX}@example.com\",\"password\":\"Passw0rd!${SFX}\",\"name\":\"CV Owner\"}"
[ "$CV_HTTP_STATUS" = "201" ] || { echo "setup failed: register $CV_HTTP_STATUS"; exit 1; }
TOKEN=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.token // empty')
OWNER_ID=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.user.id // empty')
[ -n "$TOKEN" ] || { echo "setup failed: no token"; exit 1; }
cv_http POST /products/ "{\"name\":\"cvsec-${SFX}\",\"description\":\"probe\",\"price\":9.99}" -H "Authorization: Bearer $TOKEN"
[ "$CV_HTTP_STATUS" = "201" ] || { echo "setup failed: create product $CV_HTTP_STATUS"; exit 1; }
PID=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.product.id // empty')
[ -n "$PID" ] || { echo "setup failed: no product id"; exit 1; }

cv_step When "control as owner then attack as anonymous" $LINENO
cv_http GET "/products/${PID}" -H "Authorization: Bearer $TOKEN"
C_STATUS=$CV_HTTP_STATUS
C_KEYS=$(printf '%s' "$CV_HTTP_BODY" | jq -r '(.product // {}) | keys | join(",")' 2>/dev/null || echo "")
printf 'CV_SECURITY_CONTROL|user|%s|product keys: %s\n' "$C_STATUS" "$C_KEYS"

cv_http GET "/products/${PID}"
A_STATUS=$CV_HTTP_STATUS
A_BODY=$CV_HTTP_BODY
A_KEYS=$(printf '%s' "$A_BODY" | jq -r '(.product // {}) | keys | join(",")' 2>/dev/null || echo "")
EXTRA=$(printf '%s' "$A_BODY" | jq -r --argjson pub "$PUBLIC_KEYS" '(.product // {}) | keys - $pub | join(",")' 2>/dev/null || echo "")
A_CREATOR=$(printf '%s' "$A_BODY" | jq -r '.product.createdBy // empty' 2>/dev/null || echo "")
printf 'CV_SECURITY_ATTACK|anonymous|%s|product keys: %s; non-public: %s\n' "$A_STATUS" "$A_KEYS" "${EXTRA:-none}"

cv_step Then "decide verdict" $LINENO
if [ "$A_STATUS" = "200" ] && [ -n "$EXTRA" ]; then
  LEAK=""
  [ -n "$A_CREATOR" ] && [ "$A_CREATOR" = "$OWNER_ID" ] && LEAK=" (createdBy equals owner user id)"
  printf 'CV_SECURITY|vulnerable|%s|%s|control %s and anonymous %s both return full object; anonymous got non-public fields %s%s\n' \
    "$CAT" "$TITLE" "$C_STATUS" "$A_STATUS" "$EXTRA" "$LEAK"
else
  printf 'CV_SECURITY|secure|%s|%s|control %s keys %s; anonymous %s got no non-public fields\n' \
    "$CAT" "$TITLE" "$C_STATUS" "$C_KEYS" "$A_STATUS"
fi
exit 0
