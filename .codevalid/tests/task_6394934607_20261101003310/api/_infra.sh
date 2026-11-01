#!/usr/bin/env bash
# Shared helpers for this feature's API tests. Sourced first by every script.
export BASE_URL="${BASE_URL:-http://app:6713}"

# --- CodeValid diagnosis markers (parsed by the test runner; do not edit) ---
# cv_step  <Given|When|Then|Cleanup> "<what this section does>" $LINENO
# cv_prereq "<setup being done>" $LINENO
# cv_http  <METHOD> <url|/path> [json-body] [expected-status] [extra curl args, e.g. -H "Authorization: Bearer $T"]
#          performs the request (relative paths go to $BASE_URL), prints REQUEST_*/RESPONSE_*
#          and CV_HTTP|METHOD|url|status|ms, sets CV_HTTP_STATUS CV_HTTP_BODY CV_HTTP_MS
#          CV_HTTP_BODY_FILE CV_HTTP_HEADERS_FILE. Call it directly, never inside $(...).
#          A 3-digit expected-status (with or without a body) is asserted: a different status
#          fails the test via cv_fail. Omit it to assert on $CV_HTTP_STATUS yourself.
# cv_http  <METHOD> <url> <http_status>          (legacy: marker only, right after your own curl)
# cv_fail  "<expected X got Y>" $LINENO           (prints marker, exits 1)
cv_step() { printf 'CV_STEP|%s|%s|line=%s\n' "${1:-}" "${2:-}" "${3:-}"; }
cv_prereq() { printf 'CV_PREREQ|%s|line=%s\n' "${1:-}" "${2:-}"; }
cv_fail() { printf 'CV_ASSERT_FAIL|%s|line=%s\n' "${1:-}" "${2:-}"; exit 1; }
_cv_is_int() { case "${1:-}" in ''|*[!0-9]*) return 1 ;; *) return 0 ;; esac; }
_cv_now_ms() {
  _cv_n=${EPOCHREALTIME:-}
  if [ -n "$_cv_n" ]; then _cv_secs_to_ms "$_cv_n"; return 0; fi
  _cv_n=$(date +%s%3N 2>/dev/null || true)
  _cv_is_int "$_cv_n" || _cv_n=$(( $(date +%s) * 1000 ))
  printf '%s' "$_cv_n"
}
_cv_ms_file() { printf '%s/.cv_last_ms.%s' "${TMPDIR:-/tmp}" "$$"; }
curl() {
  _cv_t0=$(_cv_now_ms)
  _cv_rc=0
  command curl "$@" || _cv_rc=$?
  _cv_t1=$(_cv_now_ms)
  printf '%s' "$((_cv_t1 - _cv_t0))" > "$(_cv_ms_file)" 2>/dev/null || :
  return $_cv_rc
}
# psql without a connection falls back to a local socket seed-test does not have; when
# DATABASE_URL is set and the call names no connection, connect through it.
psql() {
  if [ -n "${DATABASE_URL:-}" ]; then
    case " $* " in
      *" $DATABASE_URL "*|*" -h "*|*" --host"*|*" -d "*|*" --dbname"*|*"postgres://"*|*"postgresql://"*) ;;
      *) command psql "$DATABASE_URL" "$@"; return $? ;;
    esac
  fi
  command psql "$@"
}
_cv_secs_to_ms() {
  _cv_t=$(printf '%s' "${1:-0}" | tr ',' '.')
  _cv_s=${_cv_t%%.*}
  case "$_cv_t" in *.*) _cv_f=${_cv_t#*.}000 ;; *) _cv_f=000 ;; esac
  _cv_f=${_cv_f%"${_cv_f#???}"}
  while [ "${_cv_f#0}" != "$_cv_f" ]; do _cv_f=${_cv_f#0}; done
  _cv_is_int "$_cv_s" || _cv_s=0
  _cv_is_int "$_cv_f" || _cv_f=0
  printf '%s' "$(( _cv_s * 1000 + _cv_f ))"
}
_cv_is_status() { _cv_is_int "${1:-}" && [ ${#1} -eq 3 ]; }
cv_http() {
  if [ $# -ge 3 ] && [ $# -le 4 ] && _cv_is_status "$3" && { [ $# -eq 3 ] || _cv_is_int "$4"; }      && { [ -n "${4:-}" ] || [ -f "$(_cv_ms_file)" ]; }; then
    _cv_ms=${4:-}
    if [ -z "$_cv_ms" ] && [ -f "$(_cv_ms_file)" ]; then
      _cv_ms=$(cat "$(_cv_ms_file)" 2>/dev/null || true)
      rm -f "$(_cv_ms_file)" 2>/dev/null || :
    fi
    _cv_is_int "$_cv_ms" || _cv_ms=''
    printf 'CV_HTTP|%s|%s|%s%s\n' "$1" "$2" "$3" "${_cv_ms:+|$_cv_ms}"
    return 0
  fi
  _cv_method=${1:-GET}
  _cv_url=${2:-/}
  _cv_data=''
  _cv_expect=''
  if [ $# -ge 2 ]; then shift 2; else shift $#; fi
  if [ $# -ge 1 ] && ! _cv_is_status "$1"; then
    case "$1" in -*) ;; *) _cv_data=$1; shift ;; esac
  fi
  if [ $# -ge 1 ] && _cv_is_status "$1"; then _cv_expect=$1; shift; fi
  case "$_cv_url" in /*) _cv_url="${BASE_URL:-http://app:6713}$_cv_url" ;; esac
  CV_HTTP_BODY_FILE="${TMPDIR:-/tmp}/cv_http_body.$$"
  CV_HTTP_HEADERS_FILE="${TMPDIR:-/tmp}/cv_http_headers.$$"
  : > "$CV_HTTP_BODY_FILE"; : > "$CV_HTTP_HEADERS_FILE"
  printf 'REQUEST_HEADERS:\n%s %s\n' "$_cv_method" "$_cv_url"
  printf 'REQUEST_BODY:\n%s\n' "$_cv_data"
  if [ -n "$_cv_data" ]; then
    _cv_w=$(command curl -sS -X "$_cv_method" -H 'Content-Type: application/json' --data "$_cv_data" \
      -D "$CV_HTTP_HEADERS_FILE" -o "$CV_HTTP_BODY_FILE" -w '%{http_code} %{time_total}' "$@" "$_cv_url") || true
  else
    _cv_w=$(command curl -sS -X "$_cv_method" \
      -D "$CV_HTTP_HEADERS_FILE" -o "$CV_HTTP_BODY_FILE" -w '%{http_code} %{time_total}' "$@" "$_cv_url") || true
  fi
  CV_HTTP_STATUS=${_cv_w%% *}
  _cv_is_int "$CV_HTTP_STATUS" || CV_HTTP_STATUS=000
  case "$_cv_w" in *' '*) CV_HTTP_MS=$(_cv_secs_to_ms "${_cv_w#* }") ;; *) CV_HTTP_MS=0 ;; esac
  CV_HTTP_BODY=$(cat "$CV_HTTP_BODY_FILE" 2>/dev/null || true)
  printf 'RESPONSE_HEADERS:\n'; cat "$CV_HTTP_HEADERS_FILE" 2>/dev/null || true
  printf 'RESPONSE_BODY:\n%s\n' "$CV_HTTP_BODY"
  rm -f "$(_cv_ms_file)" 2>/dev/null || :
  printf 'CV_HTTP|%s|%s|%s|%s\n' "$_cv_method" "$_cv_url" "$CV_HTTP_STATUS" "$CV_HTTP_MS"
  if [ -n "$_cv_expect" ] && [ "$CV_HTTP_STATUS" != "$_cv_expect" ]; then
    cv_fail "expected HTTP $_cv_expect from $_cv_method $_cv_url got $CV_HTTP_STATUS: $(printf '%s' "$CV_HTTP_BODY" | head -c 300)" ""
  fi
  return 0
}
# --- end CodeValid diagnosis markers ---

# --- feature helpers (task_6394934607_20261101003310) ---
# cv_clean_evidence <text> -> evidence safe for a CV_SECURITY line (letters, digits, space, , . _ -)
cv_clean_evidence() { printf '%s' "$1" | tr '=:' '  ' | tr -cd 'A-Za-z0-9 ,._-' | tr -s ' '; }
# Stack facts: the app keeps users/products in memory (src/store.ts); there is no DB and no
# delete endpoint, so Cleanup has nothing to remove beyond local temp files.
# APP_CONTROL_URL is the test-infra supervisor (.codevalid/supervisor.mjs): POST /restart kills
# the node process and starts a fresh one (simulates a service restart).
export APP_CONTROL_URL="${APP_CONTROL_URL:-http://app:6714}"
export APP_JWT_SECRET="${APP_JWT_SECRET:-codevalid-test-jwt-secret-0f3a9c1e7b}"

cv_suffix() { printf '%s%s' "$(date +%s%N)" "$RANDOM"; }
cv_unique_email() { printf 'cv_%s_%s@example.test' "${1:-user}" "$(cv_suffix)"; }

# cv_register_user <email> <password> [name] -> sets CV_USER_ID CV_TOKEN (fails on non-201)
cv_register_user() {
  local body
  body=$(jq -nc --arg e "$1" --arg p "$2" --arg n "${3:-CV User}" '{email:$e,password:$p,name:$n}')
  cv_http POST /auth/register "$body"
  [ "$CV_HTTP_STATUS" = "201" ] || cv_fail "register $1 expected 201 got $CV_HTTP_STATUS" "${4:-$LINENO}"
  CV_USER_ID=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.user.id // empty')
  CV_TOKEN=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.token // empty')
  [ -n "$CV_USER_ID" ] || cv_fail "register $1 expected user.id in body" "${4:-$LINENO}"
}

# cv_login <email> <password>   (no status assertion; inspect CV_HTTP_STATUS / CV_HTTP_BODY)
cv_login() {
  local body
  body=$(jq -nc --arg e "$1" --arg p "$2" '{email:$e,password:$p}')
  cv_http POST /auth/login "$body"
  CV_LOGIN_TOKEN=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.token // empty' 2>/dev/null || true)
}

# cv_post_product <token|""> <json-body>   (no status assertion)
cv_post_product() {
  if [ -n "${1:-}" ]; then
    cv_http POST /products "$2" -H "Authorization: Bearer $1"
  else
    cv_http POST /products "$2"
  fi
}

# cv_product_count -> prints the number of products from GET /products (public listing)
cv_product_count() {
  command curl -sS "$BASE_URL/products" | jq '.products | length'
}

# cv_product_count_named <name> -> number of products with exactly that name
cv_product_count_named() {
  command curl -sS "$BASE_URL/products" | jq --arg n "$1" '[.products[] | select(.name == $n)] | length'
}

# cv_restart_app -> restarts the app process (fresh in-memory state); fails if not healthy
cv_restart_app() {
  cv_http POST "$APP_CONTROL_URL/restart"
  [ "$CV_HTTP_STATUS" = "200" ] || cv_fail "app restart expected 200 got $CV_HTTP_STATUS" "${1:-$LINENO}"
}

_cv_b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }
# cv_jwt_hs256 <secret> <payload-json> -> prints a signed HS256 JWT
cv_jwt_hs256() {
  local h p s
  h=$(printf '%s' '{"alg":"HS256","typ":"JWT"}' | _cv_b64url)
  p=$(printf '%s' "$2" | _cv_b64url)
  s=$(printf '%s' "$h.$p" | openssl dgst -sha256 -hmac "$1" -binary | _cv_b64url)
  printf '%s.%s.%s' "$h" "$p" "$s"
}

# cv_body_leaks <text...> -> returns 0 if CV_HTTP_BODY contains any of the given literals
# or a password / passwordHash field
cv_body_leaks() {
  local t
  if printf '%s' "$CV_HTTP_BODY" | jq -e '(if type == "object" then del(.details) else . end) | [.. | objects | keys[]] | any(. == "password" or . == "passwordHash")' >/dev/null 2>&1; then
    return 0
  fi
  for t in "$@"; do
    [ -n "$t" ] && case "$CV_HTTP_BODY" in *"$t"*) return 0 ;; esac
  done
  case "$CV_HTTP_BODY" in *'$2a$'*|*'$2b$'*) return 0 ;; esac
  return 1
}
