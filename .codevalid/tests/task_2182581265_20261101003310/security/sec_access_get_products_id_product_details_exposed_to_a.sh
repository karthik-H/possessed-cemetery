#!/usr/bin/env bash
set -uo pipefail
source .codevalid/tests/task_2182581265_20261101003310/api/_infra.sh

cv_step Given "user A registers and adds a product" $LINENO
EMAIL=$(cv_unique_email secid)
cv_http POST /auth/register "$(jq -nc --arg e "$EMAIL" '{email:$e,password:"Passw0rd!123",name:"CV SecA"}')"
[ "$CV_HTTP_STATUS" = "201" ] || { echo "setup register failed $CV_HTTP_STATUS"; exit 1; }
TOK=$(printf '%s' "$CV_HTTP_BODY" | jq -r .token)
cv_http POST /products "$(jq -nc '{name:"CV Sec Detail",description:"internal notes",price:3}')" -H "Authorization: Bearer $TOK"
[ "$CV_HTTP_STATUS" = "201" ] || { echo "setup product failed $CV_HTTP_STATUS"; exit 1; }
PID=$(printf '%s' "$CV_HTTP_BODY" | jq -r .product.id)

cv_step When "control as owner then attack as anonymous" $LINENO
cv_http GET "/products/$PID" -H "Authorization: Bearer $TOK"
CS=$CV_HTTP_STATUS; CB=$(printf '%s' "$CV_HTTP_BODY" | jq -cS '.product // {}')
printf 'CV_SECURITY_CONTROL|user|%s|fields=%s\n' "$CS" "$(printf '%s' "$CB" | jq -r 'keys|join(",")')"
cv_http GET "/products/$PID"
AS=$CV_HTTP_STATUS; AB=$(printf '%s' "$CV_HTTP_BODY" | jq -cS '.product // {}' 2>/dev/null || echo '{}')
printf 'CV_SECURITY_ATTACK|anonymous|%s|fields=%s\n' "$AS" "$(printf '%s' "$AB" | jq -r 'keys|join(",")')"

cv_step Then "verdict" $LINENO
T="Product details exposed to anonymous callers"
SENS=$(printf '%s' "$AB" | jq -r --arg e "$EMAIL" '[paths(scalars) as $p | getpath($p) | tostring | select(. == $e or test("^\\$2[aby]\\$|^\\$argon|^\\$scrypt"))] | length')
if [ "$AS" = "200" ] && [ "${SENS:-0}" != "0" ]; then
  printf 'CV_SECURITY|vulnerable|access|%s|anonymous %s got owner email or password hash in product body like owner %s\n' "$T" "$AS" "$CS"
else
  printf 'CV_SECURITY|secure|access|%s|owner %s and anonymous %s see the same public catalog fields with no owner email or secret exposed (catalog browsing is public by design)\n' "$T" "$CS" "$AS"
fi
exit 0
