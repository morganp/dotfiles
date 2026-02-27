#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_SCRIPT="$ROOT_DIR/bin/find_file"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

assert_has_substring() {
  local text="$1"
  local needle="$2"
  printf '%s\n' "$text" | grep -Fq "$needle" || fail "Expected to find '$needle'"
}

assert_lacks_substring() {
  local text="$1"
  local needle="$2"
  if printf '%s\n' "$text" | grep -Fq "$needle"; then
    fail "Did not expect to find '$needle'"
  fi
}

[ -x "$TARGET_SCRIPT" ] || fail "Script not found or not executable: $TARGET_SCRIPT"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/work/.git_hidden" "$TMP_DIR/work/.svn_hidden" "$TMP_DIR/work/.SYNC_hidden" "$TMP_DIR/work/visible"

# Filename hits (different cases to verify -iname behavior).
: > "$TMP_DIR/work/visible/target_file.txt"
: > "$TMP_DIR/work/visible/TARGET-NOTES.md"

# Content-only hit: should not match because name does not include the token.
cat > "$TMP_DIR/work/visible/content_only.txt" <<'TEXT'
This file content mentions target but its filename does not.
TEXT

# These should be pruned even though names include the token.
: > "$TMP_DIR/work/.git_hidden/target_in_git.txt"
: > "$TMP_DIR/work/.svn_hidden/target_in_svn.txt"
: > "$TMP_DIR/work/.SYNC_hidden/target_in_sync.txt"

out="$((cd "$TMP_DIR/work" && "$TARGET_SCRIPT" target) | sed 's#^\./##')"

assert_has_substring "$out" "visible/target_file.txt"
assert_has_substring "$out" "visible/TARGET-NOTES.md"
assert_lacks_substring "$out" "visible/content_only.txt"
assert_lacks_substring "$out" ".git_hidden/target_in_git.txt"
assert_lacks_substring "$out" ".svn_hidden/target_in_svn.txt"
assert_lacks_substring "$out" ".SYNC_hidden/target_in_sync.txt"

echo "PASS: find_file matches by filename (case-insensitive) and prunes .git/.svn/.SYNC paths"
