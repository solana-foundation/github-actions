#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

command -v cargo-build-sbf >/dev/null || {
  echo "cargo-build-sbf is required, install the agave tool suite first" >&2
  exit 1
}

build() {
  local variant="$1" feature="$2"
  local args=(--arch v3 --manifest-path program/Cargo.toml --sbf-out-dir program/out)
  if [ -n "$feature" ]; then
    args+=(--features "$feature")
  fi
  cargo-build-sbf "${args[@]}"
  cp program/out/fixture_program.so "program-$variant.so"
  rm -rf program/out program/target
}

build small ""
build medium medium
build big big
build huge huge

SMALL=$(wc -c < program-small.so | tr -d ' ')
MEDIUM=$(wc -c < program-medium.so | tr -d ' ')
BIG=$(wc -c < program-big.so | tr -d ' ')
HUGE=$(wc -c < program-huge.so | tr -d ' ')
echo "small=$SMALL medium=$MEDIUM big=$BIG huge=$HUGE"

if [ "$BIG" -le "$SMALL" ] || [ $((BIG - SMALL)) -ge 10240 ]; then
  echo "Size band violated: big-small delta must be in (0, 10240)" >&2
  exit 1
fi
if [ $((MEDIUM - SMALL)) -le 10240 ]; then
  echo "Size band violated: medium-small delta must exceed 10240" >&2
  exit 1
fi
if [ "$HUGE" -le 10477475 ] || [ "$HUGE" -gt 10485715 ]; then
  echo "Size band violated: huge must be in (10477475, 10485715]" >&2
  exit 1
fi

gzip -9 -n -c program-huge.so > program-huge.so.gz
rm program-huge.so
echo "Fixtures rebuilt"
