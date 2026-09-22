#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
engine_bin="${GODOT_BIN:-godot}"
test_logs="$(mktemp -d "${TMPDIR:-/tmp}/nosafeblock-tests.XXXXXX")"
for suite in rules presentation ui controls integration city progression arsenal defenses effects enemies bosses expansion navigation_recovery combat; do
  "$engine_bin" --headless --path . --script "tests/test_${suite}.gd" 2>&1 | tee "$test_logs/$suite.log"
  unknown_warning="$(grep -E 'WARNING:' "$test_logs/$suite.log" | grep -Fv 'WARNING: ObjectDB instances leaked at exit (run with --verbose for details).' || true)"
  if grep -E 'SCRIPT ERROR:|ERROR:' "$test_logs/$suite.log" || [[ -n "$unknown_warning" ]]; then
    echo "Engine diagnostics in $suite; logs: $test_logs" >&2
    exit 1
  fi
done
echo "All suites passed. Logs: $test_logs"
