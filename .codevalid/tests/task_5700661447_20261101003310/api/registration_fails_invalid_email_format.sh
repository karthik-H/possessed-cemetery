#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_5700661447_20261101003310/api/_infra.sh

# Given
cv_step Given "malformed email addresses and a valid password" $LINENO
SFX=$(date +%s%N)
PASSWORD='ValidPass#123'
BAD_EMAILS=("user${SFX}example.com" "user${SFX}@" "@example.com" "user${SFX}@@example.com")

# When
cv_step When "registering with each malformed email" $LINENO
STATUSES=()
for E in "${BAD_EMAILS[@]}"; do
  cv_http POST /auth/register "$(reg_body "$E" "$PASSWORD")"
  STATUSES+=("$CV_HTTP_STATUS|$E|$(printf '%s' "$CV_HTTP_BODY" | jq -c '.details.email // empty' 2>/dev/null)")
done

# Then
cv_step Then "each request is rejected with a 400 validation error on email" $LINENO
for S in "${STATUSES[@]}"; do
  CODE=${S%%|*}; REST=${S#*|}; E=${REST%%|*}; DET=${REST#*|}
  [ "$CODE" = "400" ] || cv_fail "expected 400 for email '$E' got $CODE" $LINENO
  [ -n "$DET" ] || cv_fail "expected validation details for email field for '$E' got none" $LINENO
done

# Cleanup
cv_step Cleanup "nothing was created" $LINENO
cleanup_note
echo "CODEVALID_TEST_ASSERTION_OK:registration_fails_invalid_email_format"
