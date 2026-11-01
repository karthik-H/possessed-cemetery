#!/usr/bin/env bash
set -uo pipefail
source .codevalid/tests/task_2182581265_20261101003310/api/_infra.sh

cv_step Given "user A registers and adds an internal draft product" $LINENO
SFX=$(cv_suffix)
EMAIL=$(cv_unique_email seclist)
cv_http POST /auth/register "$(jq -nc --arg e "$EMAIL" '{email:$e,password:"Passw0rd!123",name:"CV SecList"}')"
[ "$CV_HTTP_STATUS" = "201" ] || { echo "setup register failed $CV_HTTP_STATUS"; exit 1; }
TOK=$(printf '%s' "$CV_HTTP_BODY" | jq -r .token)
UIDA=$(printf '%s' "$CV_HTTP_BODY" | jq -r .user.id)
cv_http POST /products "$(jq -nc --arg n "CV internal draft $SFX" '{name:$n,description:"draft internal",price:1,visibility:"private",draft:true}')" -H "Authorization: Bearer $TOK"
[ "$CV_HTTP_STATUS" = "201" ] || { echo "setup product failed $CV_HTTP_STATUS"; exit 1; }
PID=$(printf '%s' "$CV_HTTP_BODY" | jq -r .product.id)
STORED_FLAGS=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.product | has("visibility") or has("draft")')

cv_step When "control as owner then attack as anonymous" $LINENO
cv_http GET /products -H "Authorization: Bearer $TOK"
CS=$CV_HTTP_STATUS
CF=$(printf '%s' "$CV_HTTP_BODY" | jq -r --arg id "$PID" 'any(.products[]?; .id == $id)')
printf 'CV_SECURITY_CONTROL|user|%s|own product listed=%s\n' "$CS" "$CF"
cv_http GET /products
AS=$CV_HTTP_STATUS
AF=$(printf '%s' "$CV_HTTP_BODY" | jq -r --arg id "$PID" 'any(.products[]?; .id == $id)')
OWN=$(printf '%s' "$CV_HTTP_BODY" | jq -r --arg id "$PID" '[.products[]? | select(.id == $id) | .createdBy][0] // ""')
printf 'CV_SECURITY_ATTACK|anonymous|%s|product listed=%s createdBy=%s\n' "$AS" "$AF" "$OWN"

cv_step Then "verdict" $LINENO
T="Product listing endpoint exposes all products without ownership or visibility filtering"
# The app has no draft/private concept: visibility flags are dropped on create (stored=$STORED_FLAGS),
# so every product is public by design. Only a restricted item leaking would be a gain.
if [ "$STORED_FLAGS" = "true" ] && [ "$AF" = "true" ]; then
  printf 'CV_SECURITY|vulnerable|access|%s|private flag stored yet anonymous %s lists product %s like owner %s\n' "$T" "$AS" "$PID" "$CS"
else
  printf 'CV_SECURITY|secure|access|%s|no private or draft flag is stored so the product is public by design - owner %s listed=%s and anonymous %s listed=%s owner id %s\n' "$T" "$CS" "$CF" "$AS" "$AF" "$UIDA"
fi
exit 0
