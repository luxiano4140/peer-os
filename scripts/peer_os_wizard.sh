#!/usr/bin/env bash
set -euo pipefail

DEFAULT_LOG_DIR="/tmp/peer_os_wizard_logs"
LOG_DIR="${LOG_DIR:-$DEFAULT_LOG_DIR}"
mkdir -p "$LOG_DIR"

BACKGROUND=1
PORT_OVERRIDE=""
PROFILE=""
SCENARIO=""

NODE_PORT_ORDER=()
NODE_PIDS=()
NODE_LOGS=()
NODE_LISTEN=()

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
  local listen="/ip4/127.0.0.1/tcp/$port"
  local log="$LOG_DIR/${role}-${port}.log"
  local profile_args=()
  if [[ -n "$PROFILE" ]]; then
    profile_args=(--profile "$PROFILE")
  fi
  printf '\nLaunching %s node on %s (logs: %s)\n' "$role" "$listen" "$log"
  (LISTEN="$listen" mesh_runtime serve "${profile_args[@]}") &> "$log" &
  local pid=$!
  NODE_PORT_ORDER+=("$port")
  NODE_PIDS+=("$pid")
  NODE_LOGS+=("$log")
  NODE_LISTEN+=("$listen")
  printf '  PID: %s\n' "$pid"
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
  gather_ports ports "${defaults[@]}"
  for port in "${ports[@]}"; do
    start_runtime "$port" "$role"
  done
  print_node_summary "$role" "${ports[@]}"
  print_next_step_commands "${ports[0]}"
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
}

function print_next_step_commands() {
  local port="$1"
  cat <<EOF
Next steps:
  1) Read the log file for the peer id: grep local_peer_id "$LOG_DIR"/*-${port}.log
  2) Submit a workflow (replace <peer_id>):\n     mesh_runtime submit-workflow /ip4/127.0.0.1/tcp/${port}/p2p/<peer_id> scripts/workflow_smoke.json
  3) Check status:\n     mesh_runtime workflow-status /ip4/127.0.0.1/tcp/${port}/p2p/<peer_id> <workflow_id>
  4) Read outputs:\n     mesh_runtime get-output /ip4/127.0.0.1/tcp/${port}/p2p/<peer_id> <output_key>
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
