#!/usr/bin/env bash
#
# ornith_dspark_server.sh
#
# Launch the local llama.cpp server that backs the `claude-ornith-dspark` alias.
# Serves AtomicChat/ornith-9b-GGUF on http://127.0.0.1:8080 so that
# ~/.claude/settings-ornith-dspark.json can route Claude Code at it.
#
# Usage:
#   ./ornith_dspark_server.sh            # plain ornith-9b (no acceleration)
#   DRAFT_MODEL=<hf-repo:quant> ./ornith_dspark_server.sh   # with speculative decoding
#
# Requirements: llama.cpp (`brew install llama.cpp`) providing `llama-server`.
#
# NOTE ON "DSpark" / SPECULATIVE DECODING
# ---------------------------------------
# The settings profile is named "dspark" and advertises "2x faster inference"
# via speculative decoding. Speculative decoding needs a small *draft* model
# whose tokenizer/vocab matches the target model. ornith-9b uses a custom
# vocab (n_vocab=248320), so a stock Qwen/Llama draft will NOT work. Until a
# compatible draft GGUF is identified, the server runs plain ornith-9b and the
# accelerator is inactive (server reports `speculative.types: none`).
# Set DRAFT_MODEL below once a matching draft model exists.

set -euo pipefail

MODEL="AtomicChat/ornith-9b-GGUF:Q4_K_M"
PORT="${PORT:-8080}"
CTX="${CTX:-32768}"

# Baseline args = the actual command that currently backs the alias.
args=(-hf "$MODEL" --jinja -c "$CTX" --port "$PORT")

# Optional speculative decoding. Provide a draft model with matching vocab.
#   DRAFT_MODEL="<hf-repo:quant>" ./ornith_dspark_server.sh
if [[ -n "${DRAFT_MODEL:-}" ]]; then
  args+=(-md "$DRAFT_MODEL" \
    --draft-max "${DRAFT_MAX:-16}" \
    --draft-min "${DRAFT_MIN:-5}" \
    --draft-p-min "${DRAFT_P_MIN:-0.75}")
  echo "Launching ornith-9b WITH speculative draft: $DRAFT_MODEL" >&2
else
  echo "Launching ornith-9b (no speculative draft; accelerator inactive)" >&2
fi

exec llama-server "${args[@]}"
