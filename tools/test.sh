#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
log_file=$(mktemp)
trap 'rm -f "$log_file"' EXIT
# Godot may return zero for script errors. Validate both its log and test marker.
test_status=0
timeout 30 ./tools/run.sh --headless -- --self-test > "$log_file" 2>&1 || test_status=$?
cat "$log_file"
if [[ "$test_status" != 0 ]]; then exit "$test_status"; fi
if rg -q 'SCRIPT ERROR|ERROR:|CHECKS FAILED' "$log_file"; then exit 1; fi
rg -q '^ALL INTEGRATION CHECKS PASSED$' "$log_file"
