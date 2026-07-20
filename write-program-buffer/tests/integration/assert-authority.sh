#!/usr/bin/env bash
set -euo pipefail

RPC_URL="${RPC_URL:-http://127.0.0.1:8899}"
ARTIFACT="target/deploy/fixture-authority.so"

fail() {
  echo "ASSERT FAIL: $1" >&2
  exit 1
}

[ -n "${BUFFER:-}" ] || fail "action did not output a buffer address"
[ -n "${BUFFER_AUTHORITY:-}" ] || fail "BUFFER_AUTHORITY env not set"
[ -n "${DEPLOYER:-}" ] || fail "DEPLOYER env not set"

BUFFER_INFO=$(solana program show "$BUFFER" -u "$RPC_URL")
echo "$BUFFER_INFO"
AUTHORITY=$(echo "$BUFFER_INFO" | grep "Authority:" | awk '{print $2}' || true)
[ -n "$AUTHORITY" ] || fail "could not read authority of buffer $BUFFER"
[ "$AUTHORITY" = "$BUFFER_AUTHORITY" ] || fail "buffer authority is $AUTHORITY, expected $BUFFER_AUTHORITY"
[ "$AUTHORITY" != "$DEPLOYER" ] || fail "buffer authority still equals the deployer"

DUMP="$(mktemp)"
solana program dump "$BUFFER" "$DUMP" -u "$RPC_URL" || fail "could not dump buffer $BUFFER"
cmp -s "$ARTIFACT" "$DUMP" || fail "buffer contents differ from artifact"
rm -f "$DUMP"

echo "Authority transfer assertions passed"
