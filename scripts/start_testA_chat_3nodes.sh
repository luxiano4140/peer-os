#!/usr/bin/env bash
set -euo pipefail

# 3-node Peer-OS + QUIC + PUCE + ik llama chat bootstrap.
# - Starts 1 macOS Peer-OS node
# - Auto-SSH starts 2 Windows Peer-OS worker nodes
# - Starts rpc-server workers (mac + windows)
# - Starts llama-server chat web UI on :8080 using RPC workers

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MESH_DIR="${MESH_DIR:-$ROOT_DIR/mesh_runtime}"

SSH_KEY="${SSH_KEY:-$HOME/.ssh/l2p2p_win}"
WIN1_USER="${WIN1_USER:-lux}"
WIN1_HOST="${WIN1_HOST:-192.168.1.203}"
WIN1_MESH_DIR="${WIN1_MESH_DIR:-C:\\Users\\lux\\scripts\\peer-os\\mesh_runtime}"
WIN2_USER="${WIN2_USER:-Gebruiker}"
WIN2_HOST="${WIN2_HOST:-192.168.1.133}"
WIN2_MESH_DIR="${WIN2_MESH_DIR:-C:\\Users\\Gebruiker\\scripts\\peer-os\\mesh_runtime}"

CLUSTER_ID="${CLUSTER_ID:-chat3}"
MAC_NODE_ID="${MAC_NODE_ID:-mac-chat}"
WIN1_NODE_ID="${WIN1_NODE_ID:-win1-chat}"
WIN2_NODE_ID="${WIN2_NODE_ID:-win2-chat}"

MAC_TCP_PORT="${MAC_TCP_PORT:-7931}"
WIN1_TCP_PORT="${WIN1_TCP_PORT:-7932}"
WIN2_TCP_PORT="${WIN2_TCP_PORT:-7933}"

MAC_RPC_PORT="${MAC_RPC_PORT:-50051}"
WIN1_RPC_PORT="${WIN1_RPC_PORT:-50052}"
WIN2_RPC_PORT="${WIN2_RPC_PORT:-50053}"

CHAT_PORT="${CHAT_PORT:-8080}"
LLAMA_SERVER_BIN="${LLAMA_SERVER_BIN:-llama-server}"
LLAMA_RPC_BIN="${LLAMA_RPC_BIN:-rpc-server}"
MODEL_PATH="${MODEL_PATH:-}"

LOG_DIR="${LOG_DIR:-/tmp/peeros-chat3}"
MAC_NODE_LOG="$LOG_DIR/mesh-mac.log"
MAC_RPC_LOG="$LOG_DIR/rpc-mac.log"
CHAT_LOG="$LOG_DIR/chat-8080.log"
MAC_NODE_PID="$LOG_DIR/mesh-mac.pid"
CHAT_PID="$LOG_DIR/chat.pid"

SSH_OPTS=(
  -o BatchMode=yes
  -o IdentitiesOnly=yes
  -o ConnectTimeout=8
  -i "$SSH_KEY"
)

die() {
  echo "ERROR: $*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing command: $1"
}

ssh_win() {
  local user="$1"
  local host="$2"
  shift 2
  ssh "${SSH_OPTS[@]}" "${user}@${host}" "$@"
}

ensure_prereqs() {
  need_cmd cargo
  need_cmd ssh
  [[ -d "$MESH_DIR" ]] || die "mesh_runtime dir not found: $MESH_DIR"
  if [[ "$LLAMA_SERVER_BIN" == */* ]]; then
    [[ -x "$LLAMA_SERVER_BIN" ]] || die "llama-server not executable: $LLAMA_SERVER_BIN"
  else
    need_cmd "$LLAMA_SERVER_BIN"
  fi
  if [[ "$LLAMA_RPC_BIN" == */* ]]; then
    [[ -x "$LLAMA_RPC_BIN" ]] || die "rpc-server not executable: $LLAMA_RPC_BIN"
  else
    need_cmd "$LLAMA_RPC_BIN"
  fi
  [[ -n "$MODEL_PATH" ]] || die "MODEL_PATH is not set (must point to a .gguf model file)"
  [[ -f "$MODEL_PATH" ]] || die "model not found: $MODEL_PATH"
  [[ -f "$SSH_KEY" ]] || die "ssh key not found: $SSH_KEY"
  mkdir -p "$LOG_DIR"
}

start_mac_node() {
  echo "[1/6] Starting mac Peer-OS node..."
  pkill -f "mesh_runtime -- serve --node-id $MAC_NODE_ID" >/dev/null 2>&1 || true
  (
    cd "$MESH_DIR"
    env \
      MESH_CLUSTER_ID="$CLUSTER_ID" \
      ENABLE_MDNS=0 \
      MESH_PUCE_STACK_ENABLE=1 \
      MESH_PUCE_LAYER_OBJECTS_ENABLE=1 \
      MESH_PUCE_LAYER_LARGE_TRANSFER_ENABLE=1 \
      MESH_PUCE_LAYER_MODELS_ENABLE=1 \
      MESH_PUCE_LAYER_MEMORY_ENABLE=1 \
      MESH_PUCE_LAYER_TENSOR_KV_ENABLE=1 \
      MESH_PUCE_LAYER_PLANNER_ENABLE=1 \
      MESH_HETERO_DATA_PLANE=1 \
      cargo run --features p2p_quic --bin mesh_runtime -- serve \
        --node-id "$MAC_NODE_ID" \
        --bind-addr "/ip4/0.0.0.0/tcp/$MAC_TCP_PORT,/ip4/0.0.0.0/udp/$MAC_TCP_PORT/quic-v1" \
        --resources "cpu=0-9,mem=8GB" \
        >"$MAC_NODE_LOG" 2>&1 &
    echo "$!" >"$MAC_NODE_PID"
  )

  local peer_line mac_peer_id
  for _ in {1..80}; do
    peer_line="$(grep -m1 "local_peer_id=" "$MAC_NODE_LOG" 2>/dev/null || true)"
    if [[ -n "$peer_line" ]]; then
      mac_peer_id="${peer_line#*=}"
      echo "$mac_peer_id"
      return 0
    fi
    sleep 0.25
  done
  die "mac node did not emit local_peer_id (see $MAC_NODE_LOG)"
}

start_win_node() {
  local user="$1" host="$2" node_id="$3" bind_port="$4" mesh_dir="$5" bootstrap="$6" log_file="$7"
  echo "    -> starting $node_id on $host"
  ssh_win "$user" "$host" "powershell -NoProfile -Command -" <<PS
\$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force C:\\peer-os\\logs | Out-Null
Get-Process mesh_runtime -ErrorAction SilentlyContinue | Stop-Process -Force
\$cmd = \"cd /d $mesh_dir && set MESH_CLUSTER_ID=$CLUSTER_ID && set ENABLE_MDNS=0 && set BOOTSTRAP_PEERS=$bootstrap && set MESH_PUCE_STACK_ENABLE=1 && set MESH_PUCE_LAYER_OBJECTS_ENABLE=1 && set MESH_PUCE_LAYER_LARGE_TRANSFER_ENABLE=1 && set MESH_PUCE_LAYER_MODELS_ENABLE=1 && set MESH_PUCE_LAYER_MEMORY_ENABLE=1 && set MESH_PUCE_LAYER_TENSOR_KV_ENABLE=1 && set MESH_PUCE_LAYER_PLANNER_ENABLE=1 && set MESH_HETERO_DATA_PLANE=1 && cargo run --features p2p_quic --bin mesh_runtime -- serve --node-id $node_id --bind-addr /ip4/0.0.0.0/tcp/$bind_port,/ip4/0.0.0.0/udp/$bind_port/quic-v1 --resources cpu=0-3,mem=4GB > $log_file 2>&1\"
Start-Process -FilePath cmd.exe -ArgumentList '/c', \$cmd -WindowStyle Hidden
Start-Sleep -Seconds 2
netstat -ano | findstr :$bind_port
PS
}

start_rpc_workers() {
  echo "[3/6] Starting rpc-server workers..."
  pkill -f "rpc-server.*$MAC_RPC_PORT" >/dev/null 2>&1 || true
  nohup "$LLAMA_RPC_BIN" -H 0.0.0.0 -p "$MAC_RPC_PORT" >"$MAC_RPC_LOG" 2>&1 &

  ssh_win "$WIN1_USER" "$WIN1_HOST" "powershell -NoProfile -Command \"Get-Process rpc-server -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Process -FilePath C:\\ik_llama\\bin\\rpc-server.exe -ArgumentList @('-H','0.0.0.0','-p','$WIN1_RPC_PORT') -WorkingDirectory C:\\ik_llama\\bin -WindowStyle Hidden; Start-Sleep -Seconds 1; netstat -ano | findstr :$WIN1_RPC_PORT\""
  ssh_win "$WIN2_USER" "$WIN2_HOST" "powershell -NoProfile -Command \"Get-Process rpc-server -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Process -FilePath C:\\ik_llama\\bin\\rpc-server.exe -ArgumentList @('-H','0.0.0.0','-p','$WIN2_RPC_PORT') -WorkingDirectory C:\\ik_llama\\bin -WindowStyle Hidden; Start-Sleep -Seconds 1; netstat -ano | findstr :$WIN2_RPC_PORT\""
}

start_chat_server() {
  echo "[4/6] Starting chat web server on :$CHAT_PORT ..."
  pkill -f "llama-server.*--port $CHAT_PORT" >/dev/null 2>&1 || true
  nohup "$LLAMA_SERVER_BIN" \
    --model "$MODEL_PATH" \
    --host 0.0.0.0 \
    --port "$CHAT_PORT" \
    --rpc "127.0.0.1:$MAC_RPC_PORT,$WIN1_HOST:$WIN1_RPC_PORT,$WIN2_HOST:$WIN2_RPC_PORT" \
    --ctx-size 4096 \
    --n-gpu-layers 99 \
    >"$CHAT_LOG" 2>&1 &
  echo "$!" >"$CHAT_PID"
  sleep 2
}

print_summary() {
  echo "[5/6] Runtime summary"
  echo "  cluster_id: $CLUSTER_ID"
  echo "  mac node log: $MAC_NODE_LOG"
  echo "  chat log: $CHAT_LOG"
  echo "  chat URL: http://0.0.0.0:$CHAT_PORT"
  echo "  rpc workers: 127.0.0.1:$MAC_RPC_PORT, $WIN1_HOST:$WIN1_RPC_PORT, $WIN2_HOST:$WIN2_RPC_PORT"
  echo
  echo "[6/6] Quick health checks"
  curl -fsS "http://127.0.0.1:$CHAT_PORT/health" || true
  echo
}

stop_all_local() {
  if [[ -f "$CHAT_PID" ]]; then
    kill "$(cat "$CHAT_PID")" >/dev/null 2>&1 || true
  fi
  if [[ -f "$MAC_NODE_PID" ]]; then
    kill "$(cat "$MAC_NODE_PID")" >/dev/null 2>&1 || true
  fi
  pkill -f "rpc-server.*$MAC_RPC_PORT" >/dev/null 2>&1 || true
}

main() {
  ensure_prereqs
  local mac_peer_id bootstrap
  mac_peer_id="$(start_mac_node)"
  bootstrap="/ip4/$(ipconfig getifaddr en0 2>/dev/null || echo 127.0.0.1)/tcp/$MAC_TCP_PORT/p2p/$mac_peer_id"

  echo "[2/6] Starting Windows Peer-OS nodes over SSH..."
  start_win_node "$WIN1_USER" "$WIN1_HOST" "$WIN1_NODE_ID" "$WIN1_TCP_PORT" "$WIN1_MESH_DIR" "$bootstrap" "C:\\peer-os\\logs\\mesh-win1.log"
  start_win_node "$WIN2_USER" "$WIN2_HOST" "$WIN2_NODE_ID" "$WIN2_TCP_PORT" "$WIN2_MESH_DIR" "$bootstrap" "C:\\peer-os\\logs\\mesh-win2.log"

  start_rpc_workers
  start_chat_server
  print_summary
}

if [[ "${1:-start}" == "stop" ]]; then
  stop_all_local
  echo "Stopped local chat/mac processes. Remote windows processes remain running."
  exit 0
fi

main "$@"
