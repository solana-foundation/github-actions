#!/usr/bin/env bash
set -euo pipefail

RPC_URL="${RPC_URL:-http://127.0.0.1:8899}"
ARTIFACT="target/deploy/fixture-fresh.so"

fail() {
  echo "ASSERT FAIL: $1" >&2
  exit 1
}

[ -n "${BUFFER:-}" ] || fail "action did not output a buffer address"
[ -n "${PROGRAM_ID:-}" ] || fail "PROGRAM_ID env not set"
[ -n "${DEPLOYER:-}" ] || fail "DEPLOYER env not set"

DUMP="$(mktemp)"
solana program dump "$BUFFER" "$DUMP" -u "$RPC_URL" || fail "could not dump buffer $BUFFER"
cmp -s "$ARTIFACT" "$DUMP" || fail "buffer contents differ from artifact"
rm -f "$DUMP"

BUFFER_INFO=$(solana program show "$BUFFER" -u "$RPC_URL")
echo "$BUFFER_INFO"
AUTHORITY=$(echo "$BUFFER_INFO" | grep "Authority:" | awk '{print $2}')
[ "$AUTHORITY" = "$DEPLOYER" ] || fail "buffer authority is $AUTHORITY, expected deployer $DEPLOYER"

ABSENCE_CHECK=$(solana program show "$PROGRAM_ID" -u "$RPC_URL" 2>&1 || true)
if ! echo "$ABSENCE_CHECK" | grep -q "Unable to find the account"; then
  fail "program $PROGRAM_ID unexpectedly exists or the absence check errored: $ABSENCE_CHECK"
fi

echo "Fresh-program scenario assertions passed"
