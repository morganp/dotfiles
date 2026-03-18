#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
base_config="$script_dir/config.toml"
local_config="$script_dir/config.local.toml"
target_dir="${CODEX_HOME:-$HOME/.codex}"
target_config="$target_dir/config.toml"
tmp_config="$target_config.tmp"

mkdir -p "$target_dir"
cp "$base_config" "$tmp_config"

if [ -f "$local_config" ]; then
    printf '\n' >> "$tmp_config"
    cat "$local_config" >> "$tmp_config"
fi

mv "$tmp_config" "$target_config"
printf 'Wrote %s\n' "$target_config"
