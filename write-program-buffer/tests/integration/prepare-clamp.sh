#!/usr/bin/env bash
set -euo pipefail

RPC_URL="${RPC_URL:-http://127.0.0.1:8899}"
FIXTURES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../fixtures" && pwd)"
SCENARIO_DIR="${RUNNER_TEMP:-/tmp}/scenario-clamp"

SMALL_SIZE=$(wc -c < "$FIXTURES_DIR/program-small.so" | tr -d ' ')
BIG_SIZE=$(wc -c < "$FIXTURES_DIR/program-big.so" | tr -d ' ')
DELTA=$((BIG_SIZE - SMALL_SIZE))
if [ "$DELTA" -le 0 ] || [ "$DELTA" -ge 10240 ]; then
  echo "Fixture drift: big-small delta of $DELTA bytes is outside (0, 10240)" >&2
  exit 1
fi

mkdir -p "$SCENARIO_DIR" target/deploy

solana-keygen new -s --no-bip39-passphrase --force -o "$SCENARIO_DIR/deployer.json" >/dev/null
solana-keygen new -s --no-bip39-passphrase --force -o "$SCENARIO_DIR/program-id.json" >/dev/null
DEPLOYER=$(solana-keygen pubkey "$SCENARIO_DIR/deployer.json")
PROGRAM_ID=$(solana-keygen pubkey "$SCENARIO_DIR/program-id.json")

for i in 1 2 3; do
  solana airdrop 100 "$DEPLOYER" -u "$RPC_URL" && break
  if [ "$i" -eq 3 ]; then
    echo "Airdrop failed after 3 attempts" >&2
    exit 1
  fi
  sleep 2
done

solana program deploy "$FIXTURES_DIR/program-small.so" \
  --program-id "$SCENARIO_DIR/program-id.json" \
  -u "$RPC_URL" -k "$SCENARIO_DIR/deployer.json" \
  --commitment confirmed

PRE_LEN=$(solana program show "$PROGRAM_ID" -u "$RPC_URL" | grep "Data Length:" | sed -E 's/.*Data Length: ([0-9]+).*/\1/' | cut -d ' ' -f1 || true)
if [ -z "$PRE_LEN" ]; then
  echo "Could not read deployed program size" >&2
  exit 1
fi

DEPLOY_SLOT=$(solana slot -u "$RPC_URL")
for i in $(seq 1 30); do
  CURRENT_SLOT=$(solana slot -u "$RPC_URL")
  [ "$CURRENT_SLOT" -gt "$DEPLOY_SLOT" ] && break
  if [ "$i" -eq 30 ]; then
    echo "Validator did not advance past slot $DEPLOY_SLOT" >&2
    exit 1
  fi
  sleep 1
done

cp "$FIXTURES_DIR/program-big.so" target/deploy/fixture-clamp.so

echo "Prepared clamp scenario: deployer=$DEPLOYER program-id=$PROGRAM_ID pre-len=$PRE_LEN"
{
  echo "keypair=$(cat "$SCENARIO_DIR/deployer.json")"
  echo "deployer=$DEPLOYER"
  echo "program-id=$PROGRAM_ID"
  echo "buffer-authority=$DEPLOYER"
  echo "pre-len=$PRE_LEN"
} >> "$GITHUB_OUTPUT"
