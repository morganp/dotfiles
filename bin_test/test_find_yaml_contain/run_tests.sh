#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TARGET_SCRIPT="$ROOT_DIR/bin/find_yaml_contain"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

assert_has_line() {
  local text="$1"
  local line="$2"
  printf '%s\n' "$text" | grep -Fqx "$line" || fail "Expected line '$line'"
}

assert_lacks_substring() {
  local text="$1"
  local needle="$2"
  if printf '%s\n' "$text" | grep -Fq "$needle"; then
    fail "Did not expect to find '$needle'"
  fi
}

run_in_fixtures() {
  local query="$1"
  (
    cd "$FIXTURES_DIR"
    "$TARGET_SCRIPT" "$query"
  )
}

[ -x "$TARGET_SCRIPT" ] || fail "Script not found or not executable: $TARGET_SCRIPT"

# Test 1: basic behavior and YAML-only filtering
out="$(run_in_fixtures alpha)"
assert_has_line "$out" "Looking for alpha in *.yaml files"
assert_has_line "$out" "match_one.yaml"
assert_has_line "$out" "match_two.yaml"
assert_lacks_substring "$out" "miss.yaml"
assert_lacks_substring "$out" "notes.txt"
assert_lacks_substring "$out" "txt_hit_should_be_ignored.txt"
assert_lacks_substring "$out" "txt_miss_should_be_ignored.txt"

echo "PASS: basic matching and YAML-only filtering"

# Test 2: case-insensitive matching
out="$(run_in_fixtures ALPHA)"
assert_has_line "$out" "Looking for ALPHA in *.yaml files"
assert_has_line "$out" "match_one.yaml"
assert_has_line "$out" "match_two.yaml"

echo "PASS: case-insensitive matching"

# Test 3: no-match behavior currently exits non-zero (grep semantics)
set +e
out="$(run_in_fixtures definitely_not_present 2>&1)"
status=$?
set -e

[ "$status" -eq 1 ] || fail "Expected exit status 1 for no matches, got $status"
assert_has_line "$out" "Looking for definitely_not_present in *.yaml files"

echo "PASS: no-match returns exit status 1"

echo "All tests passed."
