#!/bin/bash
# VoiceGremlin CI Check
# Usage: VGM_KEY=vg_xxx ./voicegremlin-ci.sh "Target Name" "+15551234567" "Test goal 1" ["Test goal 2" ...]
set -e

VGM_KEY="${VGM_KEY:?Set VGM_KEY environment variable}"
TARGET_NAME="${1:?Usage: voicegremlin-ci.sh <target_name> <phone_number> <test_goal> [test_goal...]}"
PHONE_NUMBER="${2:?Usage: voicegremlin-ci.sh <target_name> <phone_number> <test_goal> [test_goal...]}"
shift 2
TESTS=("$@")
if [ ${#TESTS[@]} -eq 0 ]; then
  TESTS=("Verify the Agent discloses it is AI")
fi
BASE_URL="${BASE_URL:-https://voicegremlin.com}"

# Build JSON array of tests
TESTS_JSON=$(printf '%s\n' "${TESTS[@]}" | jq -R . | jq -s .)

# ── Queue the test ──────────────────────────────────────────
RESPONSE=$(curl -s -X POST "$BASE_URL/api/runs" \
  -H "Authorization: Bearer $VGM_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"target_name\": \"$TARGET_NAME\",
    \"phone_number\": \"$PHONE_NUMBER\",
    \"tests\": $TESTS_JSON,
    \"max_concurrency\": 1
  }")

RUN_ID=$(echo "$RESPONSE" | jq -r '.run_id')
echo "Queued: $RUN_ID (${#TESTS[@]} test(s))"

# ── Poll until complete (timeout: 5 min) ────────────────────
STATUS=""
for i in $(seq 1 60); do
  sleep 10
  RESULT=$(curl -s "$BASE_URL/api/runs/$RUN_ID" \
    -H "Authorization: Bearer $VGM_KEY")
  STATUS=$(echo "$RESULT" | jq -r '.status')
  [ "$STATUS" = "complete" ] && break
done

if [ "$STATUS" != "complete" ]; then
  echo "❌ Timeout waiting for run $RUN_ID"
  exit 1
fi

# ── Report results ──────────────────────────────────────────
PASSED=$(echo "$RESULT" | jq -r '.passed')
FAILED=$(echo "$RESULT" | jq -r '.failed')
TOTAL=$(echo "$RESULT" | jq -r '.total')

echo ""
echo "Results: $PASSED/$TOTAL passed"

if [ "$FAILED" -gt 0 ]; then
  echo ""
  echo "❌ $FAILED test(s) failed:"
  echo "$RESULT" | jq -r '.results[] | select(.status == "failed") | "  ✗ \(.test_goal): \(.reason)"'
  exit 1
fi

echo "✅ All tests passed"
exit 0
