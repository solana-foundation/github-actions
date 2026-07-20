#!/usr/bin/env bash
set -euo pipefail

RPC_URL="${RPC_URL:-http://127.0.0.1:8899}"
ARTIFACT="target/deploy/fixture-delta.so"
MIN_EXTEND_SIZE=10240

fail() {
  echo "ASSERT FAIL: $1" >&2
  exit 1
}

[ -n "${BUFFER:-}" ] || fail "action did not output a buffer address"
[ -n "${PROGRAM_ID:-}" ] || fail "PROGRAM_ID env not set"
[ -n "${PRE_LEN:-}" ] || fail "PRE_LEN env not set"

REQUIRED_SIZE=$(wc -c < "$ARTIFACT" | tr -d ' ')
EXPECTED_GROWTH=$((REQUIRED_SIZE - PRE_LEN))
[ "$EXPECTED_GROWTH" -gt "$MIN_EXTEND_SIZE" ] || fail "scenario setup invalid: expected growth $EXPECTED_GROWTH must exceed $MIN_EXTEND_SIZE"

POST_LEN=$(solana program show "$PROGRAM_ID" -u "$RPC_URL" | grep "Data Length:" | sed -E 's/.*Data Length: ([0-9]+).*/\1/' | cut -d ' ' -f1)
GROWTH=$((POST_LEN - PRE_LEN))
[ "$GROWTH" -eq "$EXPECTED_GROWTH" ] || fail "program grew by $GROWTH bytes, expected the exact delta $EXPECTED_GROWTH"

DUMP="$(mktemp)"
solana program dump "$BUFFER" "$DUMP" -u "$RPC_URL" || fail "could not dump buffer $BUFFER"
cmp -s "$ARTIFACT" "$DUMP" || fail "buffer contents differ from artifact"
rm -f "$DUMP"

echo "Plain-delta extend assertions passed: program grew by exactly $EXPECTED_GROWTH bytes"
