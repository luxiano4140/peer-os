#!/usr/bin/env bash
set -euo pipefail

DEFAULT_LOG_DIR="/tmp/peer_os_wizard_logs"
LOG_DIR="${LOG_DIR:-$DEFAULT_LOG_DIR}"
mkdir -p "$LOG_DIR"

BACKGROUND=1
PORT_OVERRIDE=""
PROFILE=""
SCENARIO=""
GPU_ALL=""
GPU_PER_NODE=""
ENABLE_OBM=0
ENABLE_K8=0
K8_MODE="workflow"
K8_LISTEN="0.0.0.0:8082"

NODE_PORT_ORDER=()
NODE_PIDS=()
NODE_LOGS=()
NODE_LISTEN=()
NODE_GPU=()
NODE_PEER_ID=()
NODE_ADDR=()

OBM_CONTROLLER_PID=""
OBM_AGENT_PID=""
K8_PID=""

function usage() {
  cat <<'EOF' >&2
Usage: bash scripts/peer_os_wizard.sh [options]

Options:
  --single, --home        Start a single-node home/small setup
  --multi-node            Start a two-node cluster
  --ai                   Start nodes tuned for AI/LLM workflow samples
  --benchmark            Start a benchmark-ready node
  --business             Start a business/production-like multi-node setup
  --ports <list>         Override the ports for nodes (comma-separated)
  --profile <name>       Pass a mesh_runtime profile (fast|balanced|strict)
  --gpu <ids>             Set CUDA_VISIBLE_DEVICES for all nodes (example: "0" or "0,1")
  --gpu-per-node <list>   Set CUDA_VISIBLE_DEVICES per node (example: "0,1,none")
  --obm                   Start OBM (distributed shared state) connected to the first node
  --k8                    Start peer-k8-gateway (Kubernetes-like HTTP API) targeting the first node
  --k8-mode <mode>        peer-k8-gateway mode: workflow|direct (default: workflow)
  --k8-listen <addr>      peer-k8-gateway listen addr (default: 0.0.0.0:8082)
  --logs-dir <path>      Store logs in <path> instead of ${DEFAULT_LOG_DIR}
  --background           (default) Launch mesh_runtime serve in the background
  --help                 Show this help text
EOF
  exit 0
}

function parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --single|--home) SCENARIO="home"; shift ;;
      --multi-node) SCENARIO="multi"; shift ;;
      --ai) SCENARIO="ai"; shift ;;
      --benchmark) SCENARIO="benchmark"; shift ;;
      --business) SCENARIO="business"; shift ;;
      --ports) shift; PORT_OVERRIDE="$1"; shift ;;
      --profile) shift; PROFILE="$1"; shift ;;
      --gpu) shift; GPU_ALL="$1"; shift ;;
      --gpu-per-node) shift; GPU_PER_NODE="$1"; shift ;;
      --obm) ENABLE_OBM=1; shift ;;
      --k8) ENABLE_K8=1; shift ;;
      --k8-mode) shift; K8_MODE="$1"; shift ;;
      --k8-listen) shift; K8_LISTEN="$1"; shift ;;
      --logs-dir) shift; LOG_DIR="$1"; mkdir -p "$LOG_DIR"; shift ;;
      --background) BACKGROUND=1; shift ;;
      --help|-h) usage ;;
      *) echo "Unknown option: $1" >&2; usage ;;
    esac
  done
}

function start_runtime() {
  local port="$1"
  local role="$2"
  local gpu_ids="${3:-}"
  local listen="/ip4/127.0.0.1/tcp/$port"
  local log="$LOG_DIR/${role}-${port}.log"
  local profile_args=()
  if [[ -n "$PROFILE" ]]; then
    profile_args=(--profile "$PROFILE")
  fi
  printf '\nLaunching %s node on %s (logs: %s)\n' "$role" "$listen" "$log"
  if [[ -n "$gpu_ids" ]] && [[ "$gpu_ids" != "none" ]]; then
    (LISTEN="$listen" CUDA_VISIBLE_DEVICES="$gpu_ids" MESH_NODE_GPU="$gpu_ids" mesh_runtime serve "${profile_args[@]}") &> "$log" &
  else
    (LISTEN="$listen" mesh_runtime serve "${profile_args[@]}") &> "$log" &
  fi
  local pid=$!
  NODE_PORT_ORDER+=("$port")
  NODE_PIDS+=("$pid")
  NODE_LOGS+=("$log")
  NODE_LISTEN+=("$listen")
  NODE_GPU+=("${gpu_ids:-}")
  printf '  PID: %s\n' "$pid"
}

function wait_for_peer_id() {
  local log="$1"
  local tries="${2:-80}"
  local line=""
  for _ in $(seq 1 "$tries"); do
    line="$(grep -m1 'local_peer_id=' "$log" 2>/dev/null || true)"
    if [[ -n "$line" ]]; then
      printf '%s' "${line#*=}"
      return 0
    fi
    sleep 0.25
  done
  return 1
}

function resolve_addrs() {
  NODE_PEER_ID=()
  NODE_ADDR=()
  for idx in "${!NODE_PORT_ORDER[@]}"; do
    local log="${NODE_LOGS[$idx]}"
    local listen="${NODE_LISTEN[$idx]}"
    local peer_id=""
    peer_id="$(wait_for_peer_id "$log" 80 || true)"
    NODE_PEER_ID+=("$peer_id")
    if [[ -n "$peer_id" ]]; then
      NODE_ADDR+=("${listen}/p2p/${peer_id}")
    else
      NODE_ADDR+=("")
    fi
  done
}

function start_obm_if_requested() {
  if [[ "$ENABLE_OBM" != "1" ]]; then
    return 0
  fi
  local target_addr="${NODE_ADDR[0]:-}"
  if [[ -z "$target_addr" ]]; then
    echo "OBM requested, but the first node peer id is not available yet (check logs)." >&2
    return 0
  fi
  if ! command -v obm-controller >/dev/null 2>&1; then
    echo "OBM requested, but obm-controller is not in PATH." >&2
    echo "Tip: OBM is an external module; install/provide the compiled obm binaries, then re-run with --obm." >&2
    return 0
  fi
  if ! command -v obm-agent >/dev/null 2>&1; then
    echo "OBM requested, but obm-agent is not in PATH." >&2
    echo "Tip: OBM is an external module; install/provide the compiled obm binaries, then re-run with --obm." >&2
    return 0
  fi
  local c_log="$LOG_DIR/obm-controller.log"
  local a_log="$LOG_DIR/obm-agent.log"
  echo
  echo "Starting OBM controller + agent (distributed shared-state)..."
  (obm-controller --listen 127.0.0.1:8900 --state-file "$LOG_DIR/obm-controller-state.json") &> "$c_log" &
  OBM_CONTROLLER_PID="$!"
  (obm-agent --listen 127.0.0.1:8800 --controller 127.0.0.1:8900 --peeros-store-peer "$target_addr") &> "$a_log" &
  OBM_AGENT_PID="$!"
  echo "  obm-controller PID: $OBM_CONTROLLER_PID (log $c_log)"
  echo "  obm-agent PID: $OBM_AGENT_PID (log $a_log)"
}

function start_k8_if_requested() {
  if [[ "$ENABLE_K8" != "1" ]]; then
    return 0
  fi
  if ! command -v peer-k8-gateway >/dev/null 2>&1; then
    echo "K8 gateway requested, but peer-k8-gateway is not in PATH." >&2
    echo "Tip: provide the compiled peer-k8-gateway binary, then re-run with --k8." >&2
    return 0
  fi
  local target_addr="${NODE_ADDR[0]:-}"
  if [[ "$K8_MODE" == "workflow" ]] && [[ -z "$target_addr" ]]; then
    echo "K8 gateway requested, but the first node peer id is not available yet (check logs)." >&2
    return 0
  fi
  local k8_log="$LOG_DIR/peer-k8-gateway.log"
  echo
  echo "Starting peer-k8-gateway on $K8_LISTEN (mode=$K8_MODE)..."
  if [[ "$K8_MODE" == "workflow" ]]; then
    (peer-k8-gateway --listen "$K8_LISTEN" --mode workflow --workflow-target "$target_addr") &> "$k8_log" &
  else
    (peer-k8-gateway --listen "$K8_LISTEN" --mode direct) &> "$k8_log" &
  fi
  K8_PID="$!"
  echo "  peer-k8-gateway PID: $K8_PID (log $k8_log)"
  local k8_port="${K8_LISTEN##*:}"
  echo "  health: http://127.0.0.1:${k8_port}/healthz"
}

function gather_ports() {
  local target="$1"
  shift
  local defaults=("$@")
  local ports=()
  if [[ -n "$PORT_OVERRIDE" ]]; then
    IFS=',' read -ra ports <<< "$PORT_OVERRIDE"
  else
    ports=("${defaults[@]}")
  fi
  eval "$target=(\"\${ports[@]}\")"
}

function start_nodes_for_role() {
  local role="$1"
  shift
  local defaults=("$@")
  local ports=()
  local gpu_list=()
  gather_ports ports "${defaults[@]}"
  if [[ -n "$GPU_PER_NODE" ]]; then
    IFS=',' read -ra gpu_list <<< "$GPU_PER_NODE"
  fi
  for port in "${ports[@]}"; do
    local idx="${#NODE_PORT_ORDER[@]}"
    local gpu_ids=""
    if [[ -n "$GPU_PER_NODE" ]]; then
      gpu_ids="${gpu_list[$idx]:-}"
    elif [[ -n "$GPU_ALL" ]]; then
      gpu_ids="$GPU_ALL"
    fi
    start_runtime "$port" "$role" "$gpu_ids"
  done
  resolve_addrs
  print_node_summary "$role" "${ports[@]}"
  print_next_step_commands "${ports[0]}"
  start_obm_if_requested
  start_k8_if_requested
  print_status_stop
}

function scenario_home() {
  print_banner "Home / single node"
  printf 'Goal: keep work local, let the Smart Dynamic Coordinator stay in the "one big computer" part of the continuum while still allowing autosplit later.\n'
  start_nodes_for_role "home" 7001
}

function scenario_multi() {
  print_banner "Multi-node cluster"
  printf 'Goal: aggregate CPU, RAM, NIC resources across nodes and let the coordinator adapt toward hybrid/distributed execution as needed.\n'
  start_nodes_for_role "cluster" 7001 7002
}

function scenario_ai() {
  print_banner "AI / LLM workflow"
  printf 'Goal: give AI workloads a dedicated node plus a shard helper and rely on auto-shard + DSM to keep data coherent.\n'
  start_nodes_for_role "ai" 7001 7002 7003
}

function scenario_benchmark() {
  print_banner "Benchmark ready node"
  printf 'Goal: use the benchmark profile path (fast/balanced/strict) and verify throughput with repeated submits.\n'
  start_nodes_for_role "benchmark" 7001
  printf 'Hint: tail the log and watch for `workflow done` lines.\n'
}

function scenario_business() {
  print_banner "Business / production-like"
  printf 'Goal: combine multiple nodes, transport awareness, replication policies, and observability for production-ready behavior.\n'
  start_nodes_for_role "business" 7001 7002 7003
}

function print_banner() {
  local title="$1"
  printf '\n=== %s ===\n' "$title"
}

function print_node_summary() {
  local role="$1"
  shift
  printf '\nSpawned %s nodes on ports: %s\n' "$role" "$*"
  printf 'Logs directory: %s\n' "$LOG_DIR"
  printf 'Addresses:\n'
  for idx in "${!NODE_PORT_ORDER[@]}"; do
    local port="${NODE_PORT_ORDER[$idx]}"
    local addr="${NODE_ADDR[$idx]}"
    local gpu="${NODE_GPU[$idx]}"
    if [[ -n "$gpu" ]]; then
      printf '  - %s -> %s (GPU=%s)\n' "$port" "$addr" "$gpu"
    else
      printf '  - %s -> %s\n' "$port" "$addr"
    fi
  done
}

function print_next_step_commands() {
  local port="$1"
  local addr="${NODE_ADDR[0]:-}"
  if [[ -z "$addr" ]]; then
    addr="/ip4/127.0.0.1/tcp/${port}/p2p/<peer_id>"
  fi
  cat <<EOF
Next steps:
  1) Submit smoke:\n     mesh_runtime submit-workflow ${addr} scripts/workflow_smoke.json
  2) Check status:\n     mesh_runtime workflow-status ${addr} <workflow_id>
  3) Read outputs:\n     mesh_runtime get-output ${addr} <output_key>

Feature quick starts:
  - GPU: re-run with --gpu <ids> or --gpu-per-node <list> to set CUDA_VISIBLE_DEVICES per node.
  - Distributed memory: re-run with --obm to start OBM (controller+agent) connected to this cluster.
  - Kubernetes-like API: re-run with --k8 to start peer-k8-gateway targeting this cluster.
EOF
  printf 'The Smart Dynamic Coordinator will adaptively shift toward distributed execution on overload; check the log for notes when that transition happens.\n'
}

function print_status_stop() {
  printf '\nNode control:\n'
  for idx in "${!NODE_PORT_ORDER[@]}"; do
    local port="${NODE_PORT_ORDER[$idx]}"
    local pid="${NODE_PIDS[$idx]}"
    local log="${NODE_LOGS[$idx]}"
    printf '  Port %s -> PID %s (log %s). Stop with `kill %s`.\n' "$port" "$pid" "$log" "$pid"
  done
  if [[ -n "$OBM_CONTROLLER_PID" ]]; then
    printf '  OBM controller -> PID %s. Stop with `kill %s`.\n' "$OBM_CONTROLLER_PID" "$OBM_CONTROLLER_PID"
  fi
  if [[ -n "$OBM_AGENT_PID" ]]; then
    printf '  OBM agent -> PID %s. Stop with `kill %s`.\n' "$OBM_AGENT_PID" "$OBM_AGENT_PID"
  fi
  if [[ -n "$K8_PID" ]]; then
    printf '  peer-k8-gateway -> PID %s. Stop with `kill %s`.\n' "$K8_PID" "$K8_PID"
  fi
}

function print_flowchart_notice() {
  printf '\nGraph: see docs/COMPLETE_EXAMPLES.md for the full decision graph covering all scenarios and features.\n'
}

function interactive_menu() {
  print_banner "Peer-OS setup wizard"
  cat <<'EOF'
This wizard runs the compiled mesh_runtime binary and exposes each feature step-by-step.
Choose an option:
  1) Home / single node
  2) Multi-node cluster
  3) AI / LLM workflow
  4) Benchmark node
  5) Business / production-like cluster
  6) Exit
EOF
  read -rp "Choice: " choice
  case "$choice" in
    1) scenario_home ;;
    2) scenario_multi ;;
    3) scenario_ai ;;
    4) scenario_benchmark ;;
    5) scenario_business ;;
    6) echo "Exiting wizard."; exit 0 ;;
    *) echo "Invalid option."; interactive_menu ;;
  esac
  print_flowchart_notice
}

function run_scenario() {
  case "$1" in
    home) scenario_home ;;
    multi) scenario_multi ;;
    ai) scenario_ai ;;
    benchmark) scenario_benchmark ;;
    business) scenario_business ;;
    *) echo "Unknown scenario: $1" >&2; usage ;;
  esac
  print_flowchart_notice
}

parse_args "$@"
if [[ -n "$SCENARIO" ]]; then
  run_scenario "$SCENARIO"
else
  interactive_menu
fi
