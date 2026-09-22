#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
engine_bin="${GODOT_BIN:-godot}"
test_logs="$(mktemp -d "${TMPDIR:-/tmp}/nosafeblock-tests.XXXXXX")"
for suite in rules presentation ui controls integration; do
  "$engine_bin" --headless --path . --script "tests/test_${suite}.gd" 2>&1 | tee "$test_logs/$suite.log"
  if grep -E 'SCRIPT ERROR:|ERROR:|WARNING:' "$test_logs/$suite.log"; then
    echo "Engine diagnostics in $suite; logs: $test_logs" >&2
    exit 1
  fi
done
echo "All five suites passed. Logs: $test_logs"
