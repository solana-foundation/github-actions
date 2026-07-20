#!/usr/bin/env bash
set -euo pipefail

RPC_URL="${RPC_URL:-http://127.0.0.1:8899}"
FIXTURES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../fixtures" && pwd)"
SCENARIO_DIR="${RUNNER_TEMP:-/tmp}/scenario-authority"

mkdir -p "$SCENARIO_DIR" target/deploy

solana-keygen new -s --no-bip39-passphrase --force -o "$SCENARIO_DIR/deployer.json" >/dev/null
solana-keygen new -s --no-bip39-passphrase --force -o "$SCENARIO_DIR/program-id.json" >/dev/null
solana-keygen new -s --no-bip39-passphrase --force -o "$SCENARIO_DIR/authority-target.json" >/dev/null
DEPLOYER=$(solana-keygen pubkey "$SCENARIO_DIR/deployer.json")
PROGRAM_ID=$(solana-keygen pubkey "$SCENARIO_DIR/program-id.json")
AUTHORITY_TARGET=$(solana-keygen pubkey "$SCENARIO_DIR/authority-target.json")

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

cp "$FIXTURES_DIR/program-small.so" target/deploy/fixture-authority.so

echo "Prepared authority scenario: deployer=$DEPLOYER program-id=$PROGRAM_ID authority-target=$AUTHORITY_TARGET"
{
  echo "keypair=$(cat "$SCENARIO_DIR/deployer.json")"
  echo "deployer=$DEPLOYER"
  echo "program-id=$PROGRAM_ID"
  echo "buffer-authority=$AUTHORITY_TARGET"
} >> "$GITHUB_OUTPUT"
