#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

LLAMA_BIN_DIR="${LLAMA_BIN_DIR:-}"
LLAMA_MODEL_DIR="${LLAMA_MODEL_DIR:-}"
export LLAMA_BIN_DIR
export LLAMA_MODEL_DIR

LLAMA_BIN="${LLAMA_BIN:-/llama/bin/llama-cli}"
MODEL_PATH="${MODEL_PATH:-/llama/models/model.gguf}"
SHARDS="${SHARDS:-3}"

if [[ -z "$LLAMA_BIN_DIR" ]] || [[ ! -d "$LLAMA_BIN_DIR" ]]; then
  echo "LLAMA_BIN_DIR not found or not set: $LLAMA_BIN_DIR"
  echo "Set LLAMA_BIN_DIR to a folder containing a Linux llama-cli binary for Docker."
  exit 1
fi
if [[ -z "$LLAMA_MODEL_DIR" ]] || [[ ! -d "$LLAMA_MODEL_DIR" ]]; then
  echo "LLAMA_MODEL_DIR not found or not set: $LLAMA_MODEL_DIR"
  echo "Set LLAMA_MODEL_DIR to a folder containing model files for Docker."
  exit 1
fi

LLAMA_BIN_HOST="${LLAMA_BIN_DIR}/llama-cli"
if [[ ! -x "$LLAMA_BIN_HOST" ]]; then
  echo "LLAMA binary not found or not executable: $LLAMA_BIN_HOST"
  exit 1
fi
if [[ "${SKIP_LLAMA_BIN_CHECK:-0}" != "1" ]] && command -v file >/dev/null 2>&1; then
  FILE_INFO="$(file -b "$LLAMA_BIN_HOST" || true)"
  if [[ "$FILE_INFO" != *ELF* ]]; then
    echo "LLAMA binary is not a Linux ELF executable."
    echo "Docker containers are Linux-only. Build a Linux llama-cli and set LLAMA_BIN_DIR to it,"
    echo "or set SKIP_LLAMA_BIN_CHECK=1 to bypass this check."
    exit 1
  fi
fi

LLAMA_BIN="$LLAMA_BIN" MODEL_PATH="$MODEL_PATH" SHARDS="$SHARDS" \
  ./scripts/gen_workflow_llama_autosplit.sh

./scripts/compose_big_computer_up.sh

echo "Submitting llama autosplit workflow..."
./scripts/compose_submit.sh "scripts/workflow_llama_autosplit.json"
