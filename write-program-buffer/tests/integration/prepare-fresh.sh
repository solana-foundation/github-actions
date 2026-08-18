#!/usr/bin/env bash
set -euo pipefail

RPC_URL="${RPC_URL:-http://127.0.0.1:8899}"
FIXTURES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../fixtures" && pwd)"
SCENARIO_DIR="${RUNNER_TEMP:-/tmp}/scenario-fresh"

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

cp "$FIXTURES_DIR/program-small.so" target/deploy/fixture-fresh.so

echo "Prepared fresh scenario: deployer=$DEPLOYER program-id=$PROGRAM_ID"
{
  echo "keypair=$(cat "$SCENARIO_DIR/deployer.json")"
  echo "deployer=$DEPLOYER"
  echo "program-id=$PROGRAM_ID"
  echo "buffer-authority=$DEPLOYER"
} >> "$GITHUB_OUTPUT"
