#!/usr/bin/env bash
set -euo pipefail

BIN="${LLAMA_BIN:-llama-cli}"
MODEL="${LLAMA_MODEL:-}"
N_PREDICT="${LLAMA_N_PREDICT:-8}"
THREADS="${LLAMA_THREADS:-2}"
GPU_LAYERS="${LLAMA_GPU_LAYERS:-0}"
SHARD_ID="${MESH_SHARD_ID:-0}"
SHARD_COUNT="${MESH_SHARD_COUNT:-1}"
INPUT="$(cat || true)"

if [[ "$BIN" == */* ]]; then
  if [[ ! -x "$BIN" ]]; then
    echo "llama binary not executable: $BIN" >&2
    exit 127
  fi
else
  if ! command -v "$BIN" >/dev/null 2>&1; then
    echo "llama binary not found in PATH: $BIN" >&2
    echo "Set LLAMA_BIN to the llama-cli executable name or full path." >&2
    exit 127
  fi
fi

if [[ -z "$MODEL" ]]; then
  echo "LLAMA_MODEL is not set." >&2
  echo "Set LLAMA_MODEL to the path of a .gguf model file available on this node." >&2
  exit 2
fi
if [[ ! -f "$MODEL" ]]; then
  echo "llama model not found: $MODEL" >&2
  exit 2
fi

if [[ -n "${LLAMA_PROMPT:-}" ]]; then
  PROMPT="${LLAMA_PROMPT}"
elif [[ -n "${LLAMA_PROMPT_TEMPLATE:-}" ]]; then
  PROMPT="${LLAMA_PROMPT_TEMPLATE}"
  PROMPT="${PROMPT//\{\{shard_id\}\}/${SHARD_ID}}"
  PROMPT="${PROMPT//\{\{shard_count\}\}/${SHARD_COUNT}}"
  PROMPT="${PROMPT//\{\{input\}\}/${INPUT}}"
elif [[ -n "${INPUT}" ]]; then
  PROMPT="Shard ${SHARD_ID}/${SHARD_COUNT}. User: ${INPUT}. Assistant:"
else
  PROMPT="Shard ${SHARD_ID}/${SHARD_COUNT}: reply with exactly OK."
fi

exec "$BIN" \
  -m "$MODEL" \
  -p "$PROMPT" \
  -n "$N_PREDICT" \
  -t "$THREADS" \
  -ngl "$GPU_LAYERS" \
  --no-display-prompt
