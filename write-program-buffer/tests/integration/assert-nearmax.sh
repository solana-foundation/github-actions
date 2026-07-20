#!/usr/bin/env bash
set -euo pipefail

RPC_URL="${RPC_URL:-http://127.0.0.1:8899}"
ARTIFACT="target/deploy/fixture-nearmax.so"
MAX_PERMITTED_DATA_LENGTH=10485760
PROGRAMDATA_METADATA_SIZE=45
MAX_PROGRAM_SIZE=$((MAX_PERMITTED_DATA_LENGTH - PROGRAMDATA_METADATA_SIZE))

fail() {
  echo "ASSERT FAIL: $1" >&2
  exit 1
}

[ -n "${BUFFER:-}" ] || fail "action did not output a buffer address"
[ -n "${PROGRAM_ID:-}" ] || fail "PROGRAM_ID env not set"
[ -n "${PRE_LEN:-}" ] || fail "PRE_LEN env not set"

POST_LEN=$(solana program show "$PROGRAM_ID" -u "$RPC_URL" | grep "Data Length:" | sed -E 's/.*Data Length: ([0-9]+).*/\1/' | cut -d ' ' -f1 || true)
[ -n "$POST_LEN" ] || fail "could not read data length of program $PROGRAM_ID"
[ "$POST_LEN" -eq "$MAX_PROGRAM_SIZE" ] || fail "program data length is $POST_LEN, expected the exact maximum $MAX_PROGRAM_SIZE"
echo "Program extended from $PRE_LEN to $POST_LEN (exact headroom of $((POST_LEN - PRE_LEN)) bytes)"

DUMP="$(mktemp)"
solana program dump "$BUFFER" "$DUMP" -u "$RPC_URL" || fail "could not dump buffer $BUFFER"
cmp -s "$ARTIFACT" "$DUMP" || fail "buffer contents differ from artifact"
rm -f "$DUMP"

echo "Near-max extend assertions passed"
