#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONNECT_MACHINE="${CONNECT_MACHINE:-$ROOT/scripts/connect_machine.sh}"
CONFIG_FILE="${CONFIG_FILE:-$ROOT/scripts/connections_access.env}"

if [[ ! -f "$CONNECT_MACHINE" ]]; then
  echo "Missing connect_machine.sh at $CONNECT_MACHINE" >&2
  exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Missing connections_access.env at $CONFIG_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$CONFIG_FILE"

MAC_EXTERNAL_IP="${MAC_EXTERNAL_IP:-}"
if [[ -z "$MAC_EXTERNAL_IP" ]]; then
  echo "MAC_EXTERNAL_IP not set in $CONFIG_FILE" >&2
  exit 1
fi

MAC_NODE="${MAC_NODE:-macA}"
WIN1_NODE="${WIN1_NODE:-winB}"
WIN2_NODE="${WIN2_NODE:-winC}"
CLUSTER_ID="${CLUSTER_ID:-bigcross}"
WORKFLOW_JSON="${WORKFLOW_JSON:-$ROOT/mesh_runtime/cross_real.json}"
INPUT_KEY="${INPUT_KEY:-in:real_cross}"
INPUT_PLACEHOLDER="${INPUT_PLACEHOLDER:-/tmp/mesh_empty_input}"

MAC_LOG="${MAC_LOG:-/tmp/mesh_runtime_macA.log}"
MAC_PID_FILE="${MAC_PID_FILE:-/tmp/mesh_runtime_macA.pid}"

WIN1_BIND="${WIN1_BIND:-/ip4/0.0.0.0/tcp/7101}"
WIN2_BIND="${WIN2_BIND:-/ip4/0.0.0.0/tcp/7102}"
MAC_BIND="${MAC_BIND:-/ip4/0.0.0.0/tcp/7100}"

cd "$ROOT/mesh_runtime"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

start_mac() {
  rm -rf "$HOME/.mesh_runtime"
  pkill -f "mesh_runtime -- serve --node-id $MAC_NODE" >/dev/null 2>&1 || true
  nohup env RUST_LOG="info" MESH_CLUSTER_ID="$CLUSTER_ID" ENABLE_MDNS=0 \
    cargo run --bin mesh_runtime -- serve \
    --node-id "$MAC_NODE" \
    --bind-addr "$MAC_BIND" \
    --resources cpu=1,mem=512MB \
    >"$MAC_LOG" 2>&1 &
  echo "$!" >"$MAC_PID_FILE"
  for i in {1..40}; do
    PEER_LINE="$(grep -m1 local_peer_id= "$MAC_LOG" 2>/dev/null || true)"
    if [[ -n "$PEER_LINE" ]]; then
      MAC_PEER_ID="${PEER_LINE#*=}"
      echo "macA peer id: $MAC_PEER_ID"
      return 0
    fi
    sleep 0.5
  done
  cat "$MAC_LOG"
  fail "macA did not emit a peer id"
}

start_win1() {
  local bootstrap_addr="/ip4/$MAC_EXTERNAL_IP/tcp/7100/p2p/${MAC_PEER_ID:-}"
  if [[ -z "${MAC_PEER_ID:-}" ]]; then
    fail "missing macA peer id"
  fi
  CONFIG_FILE="$CONFIG_FILE" "$CONNECT_MACHINE" ssh-win \
    "cmd /V:ON /C \"taskkill /IM mesh_runtime.exe /F >NUL 2>&1 & \
set MESH_CLUSTER_ID=$CLUSTER_ID&& \
set ENABLE_MDNS=0&& \
set MESH_NODE_ROLES=worker&& \
set BOOTSTRAP_PEERS=$bootstrap_addr&& \
cd /d C:\\Users\\lux\\scripts\\peer-os\\mesh_runtime&& \
cargo run --bin mesh_runtime -- serve --node-id $WIN1_NODE \
--bind-addr $WIN1_BIND --resources cpu=0-3,mem=2GB\""
}

start_win2() {
  local bootstrap_addr="/ip4/$MAC_EXTERNAL_IP/tcp/7100/p2p/${MAC_PEER_ID:-}"
  if [[ -z "${MAC_PEER_ID:-}" ]]; then
    fail "missing macA peer id"
  fi
  local cmd="cmd /V:ON /C \"taskkill /IM mesh_runtime.exe /F >NUL 2>&1 & \
set MESH_CLUSTER_ID=$CLUSTER_ID&& \
set ENABLE_MDNS=0&& \
set MESH_NODE_ROLES=worker&& \
set BOOTSTRAP_PEERS=$bootstrap_addr&& \
cd /d C:\\Users\\lux\\scripts\\peer-os\\mesh_runtime&& \
cargo run --bin mesh_runtime -- serve --node-id $WIN2_NODE \
--bind-addr $WIN2_BIND --resources cpu=0-3,mem=2GB\""

  if [[ "${WIN2_USE_PASSWORD:-0}" == "1" ]]; then
    CONFIG_FILE="$CONFIG_FILE" "$CONNECT_MACHINE" ssh-win2-pass "$cmd"
  else
    CONFIG_FILE="$CONFIG_FILE" "$CONNECT_MACHINE" ssh-win2 "$cmd"
  fi
}

wait_for_cluster() {
  until cargo run --bin mesh_runtime -- cluster-snapshot /ip4/127.0.0.1/tcp/7100 | grep -q "\"node_name\": \"$WIN1_NODE\""; do
    echo "waiting for $WIN1_NODE to join"
    sleep 1
  done
  until cargo run --bin mesh_runtime -- cluster-snapshot /ip4/127.0.0.1/tcp/7100 | grep -q "\"node_name\": \"$WIN2_NODE\""; do
    echo "waiting for $WIN2_NODE to join"
    sleep 1
  done
}

submit_workflow() {
  printf '' >"$INPUT_PLACEHOLDER"
  cargo run --bin mesh_runtime -- put-object /ip4/127.0.0.1/tcp/7100 "$INPUT_KEY" "$INPUT_PLACEHOLDER"
  cargo run --bin mesh_runtime -- submit-workflow /ip4/127.0.0.1/tcp/7100 "$WORKFLOW_JSON"
}

trap 'pkill -F "$MAC_PID_FILE" >/dev/null 2>&1 || true' EXIT

echo "starting macA node..."
start_mac
echo "bootstrapping winB via connect_machine.sh..."
start_win1
echo "bootstrapping winC via connect_machine.sh..."
start_win2
echo "waiting for cluster to report both windows nodes..."
wait_for_cluster
echo "submitting cross-OS workflow..."
submit_workflow
echo "workflow submitted; monitor logs for completion."
