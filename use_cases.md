# Peer-OS Use Cases (User-Centric)

This document lists common things people want to do with Peer-OS and the simplest commands to achieve them using the compiled `mesh_runtime` binary plus the ready-made workflow examples.

Peer-OS automatically balances between the two boundary domains:

- "One Big Computer": keep work close when locality wins
- "Distributed Compute Engine": spread work when parallelism wins

You do not switch these manually. The Smart Dynamic Coordinator adapts continuously while scheduling.

## Start Here (One Command)

Use the wizard when you want the simplest setup:

```bash
bash scripts/peer_os_wizard.sh
```

Common shortcuts:

```bash
bash scripts/peer_os_wizard.sh --home
bash scripts/peer_os_wizard.sh --multi-node
bash scripts/peer_os_wizard.sh --ai
bash scripts/peer_os_wizard.sh --benchmark
bash scripts/peer_os_wizard.sh --business
```

The wizard:

- starts one or more nodes (`mesh_runtime serve`)
- writes logs under `/tmp/peer_os_wizard_logs/`
- prints PIDs (stop with `kill <pid>`)
- tells you what to submit next

## Core Runtime Commands (What Users Actually Run)

These are the user-facing commands you will use for every use case:

- Start a node: `LISTEN="/ip4/0.0.0.0/tcp/<port>" mesh_runtime serve`
- Submit a workflow: `mesh_runtime submit-workflow <peer_multiaddr> <workflow.json>`
- Submit many times: `mesh_runtime submit-workflow-batch <peer_multiaddr> <workflow.json> <count> <sleep_ms>`
- Check status: `mesh_runtime workflow-status <peer_multiaddr> <workflow_id>`
- Read output: `mesh_runtime get-output <peer_multiaddr> <output_key>`
- Explain placement (why a node was chosen): `mesh_runtime explain-placement <peer_multiaddr> <work_unit.json>`

## How To Build The `<peer_multiaddr>`

When a node starts, it prints its peer id (look for `local_peer_id=...` in the log).

Multiaddr format:

```text
/ip4/<ip>/tcp/<port>/p2p/<peer_id>
```

Example pattern:

```text
/ip4/127.0.0.1/tcp/7001/p2p/<peer_id>
```

## Runtime Examples (Feature Tour)

Use this section as a quick tour of the main runtime features. After that, the use cases reuse the same commands.

### 1) One-node "one big computer" start

```bash
bash scripts/peer_os_wizard.sh --home
```

Or start it directly:

```bash
LISTEN="/ip4/127.0.0.1/tcp/7001" mesh_runtime serve
```

### 2) Two-node start (resource aggregation + automatic balancing)

```bash
bash scripts/peer_os_wizard.sh --multi-node
```

### 3) Submit + status + output (basic end-to-end)

```bash
mesh_runtime submit-workflow <addr> scripts/workflow_smoke.json
mesh_runtime workflow-status <addr> <workflow_id>
mesh_runtime get-output <addr> out:smoke:0
```

### 4) Run a normal command-line job (process workload)

```bash
mesh_runtime submit-workflow <addr> scripts/workflow_process_demo.json
```

### 5) Auto-shard a job across nodes (distributed compute)

```bash
mesh_runtime submit-workflow <addr> scripts/workflow_process_autosplit.json
```

### 6) WASM run (single node)

```bash
mesh_runtime submit-workflow <addr> scripts/workflow_wasm_demo.json
```

### 7) WASM auto-shard across nodes

```bash
mesh_runtime submit-workflow <addr> scripts/workflow_wasm_autosplit.json
```

### 8) Batch submit (repeat jobs without retyping)

```bash
mesh_runtime submit-workflow-batch <addr> scripts/workflow_smoke.json 10 250
```

### 9) Explain placement (why a node was chosen)

```bash
mesh_runtime explain-placement <addr> <work_unit.json>
```

### 10) AI / LLM workflow samples (if helper runner is available on the nodes)

```bash
bash scripts/peer_os_wizard.sh --ai
mesh_runtime submit-workflow <addr> scripts/workflow_llama_local_autosplit.json
```

Notes:

- Some AI samples expect helper runners to already exist on the nodes.
- Use the `_safe.json` variants when available.
- For rank-planned TP/PP (distributed LLM) with an external llama backend, use the dedicated CLI commands:

```bash
# IK backend (ik_llama.cpp) — graph split for TP/hybrid presets
mesh_runtime submit-llama-distributed <addr> <model.gguf> "hello" \
  --llama-bin <path-to-llama-cli> \
  --ai-mode tp \
  --llama-backend ik_llama_cpp \
  --split-mode graph

# RPC worker mode (llama.cpp rpc-server)
mesh_runtime submit-llama-rpc <addr> <model.gguf> "hello" \
  --llama-bin <path-to-llama-cli> \
  --workers 2
```

Real cluster notes (multi-machine):

- Control-plane transport is whatever your nodes listen on (`LISTEN=...`); QUIC requires a QUIC-enabled build and a `/udp/.../quic-v1` listen address.
- IK TP data-plane is direct rank↔rank. Set `MESH_NODE_LABELS="ik.tp.host=<LAN_IP>"`, pick `MESH_IK_TP_TRANSPORT=quic|tcp`, and open `MESH_IK_TP_BASE_PORT..+world_size-1` (default base `61000`; UDP for QUIC).

### 11) Optional durability modes (simple knob)

If you want stronger durability behavior, set a mode before starting nodes:

```bash
MESH_DURABILITY_MODE=best_effort LISTEN="/ip4/127.0.0.1/tcp/7001" mesh_runtime serve
MESH_DURABILITY_MODE=quorum LISTEN="/ip4/127.0.0.1/tcp/7001" mesh_runtime serve
MESH_DURABILITY_MODE=strict LISTEN="/ip4/127.0.0.1/tcp/7001" mesh_runtime serve
```

## Resource Aggregation/Adaptation Use Cases (1 Node to N Nodes)

This section is focused on resource behavior first: CPU, memory/DSM, NIC, and optional GPU.

### RA-1) One node, local-first adaptation

Goal: keep jobs local, avoid network overhead, and still get automatic scheduler pressure control.

```bash
bash scripts/peer_os_wizard.sh --home --profile balanced
mesh_runtime submit-workflow <addr> scripts/workflow_process_demo.json
```

Expected behavior: no cross-node movement; scheduler still adapts to CPU/memory pressure on that node.

### RA-2) Two nodes, burst adaptation

Goal: run normally local, then spill to a helper node when load increases.

```bash
bash scripts/peer_os_wizard.sh --multi-node --ports 7001,7002 --profile balanced
mesh_runtime submit-workflow <addr> scripts/workflow_process_autosplit.json
```

Expected behavior: coordinator starts near the "one big computer" side, then shifts toward hybrid/distributed when queue depth or pressure rises.

### RA-3) Three nodes, full CPU+memory aggregation

Goal: aggregate compute and memory capacity for larger autosplit jobs.

```bash
bash scripts/peer_os_wizard.sh --business --ports 7001,7002,7003 --profile balanced
mesh_runtime submit-workflow <addr> scripts/workflow_process_autosplit.json
mesh_runtime submit-workflow <addr> scripts/workflow_wasm_autosplit.json
```

Expected behavior: shard placement uses available CPU and free memory; hot nodes are penalized automatically.

### RA-4) GPU-aware adaptation in mixed clusters

Goal: reserve GPU paths for GPU-capable tasks and keep CPU-only tasks on other nodes.

```bash
bash scripts/peer_os_wizard.sh --business --gpu 0 --profile balanced
mesh_runtime submit-workflow <addr> scripts/workflow_llama_local_autosplit_2_safe.json
mesh_runtime explain-placement <addr> <work_unit.json>
```

Expected behavior: scheduler favors GPU-capable owners for AI workloads while non-AI work can stay on CPU nodes.

### RA-5) NIC-aware adaptation for transfer-heavy jobs

Goal: keep transfer-heavy workloads on better network paths while preserving locality for small jobs.

```bash
bash scripts/peer_os_wizard.sh --business --profile balanced
mesh_runtime submit-workflow-batch <addr> scripts/workflow_smoke.json 25 100
mesh_runtime explain-placement <addr> <work_unit.json>
```

Expected behavior: network pressure contributes to scoring; placements adapt as NIC pressure changes.

### RA-6) Durability adaptation for important outputs

Goal: increase durability guarantees while still using adaptive placement.

```bash
MESH_DURABILITY_MODE=quorum bash scripts/peer_os_wizard.sh --business --profile strict
mesh_runtime submit-workflow <addr> scripts/workflow_process_autosplit.json
```

Expected behavior: scheduler and replication ACK rules trade throughput for stronger durability policy.

## Use Cases (Home / Simple)

### 1) "Just run a command on my computer"

Goal: run a basic command-line job, keep things simple.

```bash
bash scripts/peer_os_wizard.sh --home
mesh_runtime submit-workflow <addr> scripts/workflow_process_demo.json
```

Features used: process execution, scheduler, outputs.

### 2) "Speed up a big folder job" (backup/sync/media conversion)

Goal: split the same job into pieces and run them across nodes automatically.

```bash
bash scripts/peer_os_wizard.sh --multi-node
mesh_runtime submit-workflow <addr> scripts/workflow_process_autosplit.json
```

Features used: auto-shard, resource aggregation, adaptive scheduling.

### 3) "Run a portable task" (WASM)

Goal: run a WASM workload (portable, sandbox-friendly).

```bash
bash scripts/peer_os_wizard.sh --home
mesh_runtime submit-workflow <addr> scripts/workflow_wasm_demo.json
```

Features used: WASM path, outputs.

### 4) "Run WASM across multiple nodes"

Goal: split a WASM workload across nodes.

```bash
bash scripts/peer_os_wizard.sh --multi-node
mesh_runtime submit-workflow <addr> scripts/workflow_wasm_autosplit.json
```

Features used: auto-shard + distributed execution; DSM may be used by the workflow if it references shared pages.

## Use Cases (Business / Production-Like)

### 5) ETL / reporting batch

Goal: run a batch workload with predictable repeatability and easy status checks.

```bash
bash scripts/peer_os_wizard.sh --business --profile balanced
mesh_runtime submit-workflow <addr> scripts/workflow_process_autosplit.json
```

Features used: coordinator-driven adaptation, autosplit, status/output retrieval.

### 6) Document conversion pipeline

Goal: run a repeated process demo pattern for conversion tasks.

```bash
bash scripts/peer_os_wizard.sh --business
mesh_runtime submit-workflow <addr> scripts/workflow_process_demo.json
```

Features used: process execution, scheduling, outputs.

### 7) High-volume job submission (load test)

Goal: prove the submit path and scheduler behavior under repeated load.

```bash
bash scripts/peer_os_wizard.sh --business
mesh_runtime submit-workflow-batch <addr> scripts/workflow_smoke.json 10 250
```

Features used: submit path, scheduler, adaptive hot-node protection under load.

## Use Cases (Professional / Enterprise)

### Pro-1) Shared compute pool for a team (simple internal platform)

Goal: run a small cluster that multiple people can submit to, with predictable defaults.

```bash
bash scripts/peer_os_wizard.sh --business --profile balanced
mesh_runtime submit-workflow <addr> scripts/workflow_process_demo.json
```

Operational habit: standardize on one submit address and use `workflow-status`/`get-output` for every run.

### Pro-2) Durability-focused batch runs (stronger safety)

Goal: use stronger durability behavior for important batch outputs.

```bash
MESH_DURABILITY_MODE=strict bash scripts/peer_os_wizard.sh --business --profile strict
mesh_runtime submit-workflow <addr> scripts/workflow_process_autosplit.json
```

Note: this improves durability expectations but it is not a consensus-backed database; plan for retries and test failure scenarios.

### Pro-3) "Keep data local unless you must" (network-constrained sites)

Goal: stay closer to the "one big computer" boundary when bandwidth/latency is costly.

```bash
bash scripts/peer_os_wizard.sh --home
mesh_runtime submit-workflow <addr> scripts/workflow_process_demo.json
```

Then add nodes only when you need throughput:

```bash
bash scripts/peer_os_wizard.sh --multi-node
mesh_runtime submit-workflow <addr> scripts/workflow_process_autosplit.json
```

### Pro-4) Placement and capacity governance (audit-friendly behavior)

Goal: understand and justify scheduling decisions in operational terms.

```bash
mesh_runtime explain-placement <addr> <work_unit.json>
mesh_runtime workflow-status <addr> <workflow_id>
```

Use this when a customer asks: "Why did this run there?"

### Pro-5) Controlled performance validation (SLO regression check)

Goal: validate "submit + execute" behavior repeatedly after changes.

```bash
bash scripts/peer_os_wizard.sh --benchmark --profile fast
mesh_runtime submit-workflow-batch <addr> scripts/workflow_smoke.json 25 100
```

### Pro-6) Mixed workload cluster (ETL + WASM + AI in one pool)

Goal: keep a single cluster that can run process jobs, WASM jobs, and AI samples with the same submit flow.

```bash
bash scripts/peer_os_wizard.sh --business --profile balanced
mesh_runtime submit-workflow <addr> scripts/workflow_process_autosplit.json
mesh_runtime submit-workflow <addr> scripts/workflow_wasm_autosplit.json
```

If AI helper runners are available:

```bash
mesh_runtime submit-workflow <addr> scripts/workflow_llama_local_autosplit.json
```

### Pro-7) Blue/green node refresh (safe-ish maintenance)

Goal: restart or replace nodes without stopping all submissions.

```bash
bash scripts/peer_os_wizard.sh --business --ports 7001,7002
```

Start new nodes on new ports, then submit new workflows to the new address while the old nodes drain.

### Pro-8) LAN cluster today, multi-subnet later (known limit callout)

Goal: run a cluster on a single LAN now, with a clear understanding of the current boundary.

```bash
bash scripts/peer_os_wizard.sh --business
```

Current limitation: discovery/membership is mDNS-first, so multi-subnet and explicit bootstrap UX is still evolving.

### Pro-9) Observability-first operations (metrics + health checks)

Goal: integrate Peer-OS into a basic SRE loop (health checks and metrics scraping).

Run the cluster:

```bash
bash scripts/peer_os_wizard.sh --business --profile balanced
```

Then use the node's HTTP endpoints (if enabled in your runtime build):

- `/metrics`
- `/healthz`
- `/readyz`

### Pro-10) Heterogeneous fleet (big node + small nodes)

Goal: mix machines with different CPU/RAM/NIC and let the scheduler adapt.

```bash
bash scripts/peer_os_wizard.sh --business --profile balanced
mesh_runtime submit-workflow <addr> scripts/workflow_process_autosplit.json
mesh_runtime explain-placement <addr> <work_unit.json>
```

Use `explain-placement` to confirm the scheduler is preferring the right owners as pressure changes.

### Pro-11) Incident response checklist (what to run when something looks stuck)

Goal: have a simple operational playbook with user-facing commands only.

```bash
mesh_runtime workflow-status <addr> <workflow_id>
mesh_runtime get-output <addr> <output_key>
mesh_runtime explain-placement <addr> <work_unit.json>
```

If a node is unhealthy, stop it and restart:

```bash
kill <pid>
bash scripts/peer_os_wizard.sh --business
```

### Pro-12) Controlled change rollout (upgrade validation loop)

Goal: upgrade nodes and confirm behavior is stable before moving on.

```bash
bash scripts/peer_os_wizard.sh --benchmark --profile fast
mesh_runtime submit-workflow-batch <addr> scripts/workflow_smoke.json 25 100
```

Watch for steady submit acks and consistent completion times; use `workflow-status` to spot regressions.

### Pro-13) Air-gapped or offline lab (no external services)

Goal: run Peer-OS entirely inside a closed LAN for security/compliance testing.

```bash
bash scripts/peer_os_wizard.sh --business
mesh_runtime submit-workflow <addr> scripts/workflow_smoke.json
```

This stays within the compiled binary and local workflows. Peer discovery is LAN-local.

## Use Cases (AI + Parallel Workloads)

Peer-OS can run AI workloads as normal workflows. The simplest path is: start nodes, set the model env vars, submit a prepared AI workflow, and let the Smart Dynamic Coordinator adapt placement as the cluster gets busy.

### AI-0) One-time setup for AI samples (easy + explicit)

The default AI workflow samples run `./scripts/llama_shard_runner.sh`.

Set these on every node that will run shards:

- `LLAMA_BIN`: the `llama-cli` binary name (in PATH) or a full path
- `LLAMA_MODEL`: path to a `.gguf` model file available on that node

Optional performance knobs:

- `LLAMA_THREADS`
- `LLAMA_GPU_LAYERS`
- `LLAMA_N_PREDICT`

### AI-1) Home user: 1 node AI run (simple local)

```bash
export LLAMA_BIN=llama-cli
export LLAMA_MODEL=<MODEL_FILE.gguf>
bash scripts/peer_os_wizard.sh --ai --ports 7001
mesh_runtime submit-workflow <addr> scripts/workflow_llama_local_autosplit_2_safe.json
```

Why this is easy: even with one node, the workflow still uses the same shard runner contract, so you can scale out later without changing how you submit.

### AI-2) Home user: 2 nodes AI run (faster, still simple)

```bash
export LLAMA_BIN=llama-cli
export LLAMA_MODEL=<MODEL_FILE.gguf>
bash scripts/peer_os_wizard.sh --ai --ports 7001,7002
mesh_runtime submit-workflow <addr> scripts/workflow_llama_local_autosplit_2_safe.json
```

### AI-3) Small team: 3 nodes AI run (more parallelism)

```bash
export LLAMA_BIN=llama-cli
export LLAMA_MODEL=<MODEL_FILE.gguf>
bash scripts/peer_os_wizard.sh --ai
mesh_runtime submit-workflow <addr> scripts/workflow_llama_local_autosplit.json
```

Tip: `scripts/workflow_llama_local_autosplit.json` targets 3 shards (`preferred_parallelism: 3`). Use the `_2.json` variants when you want 2 shards.

### AI-4) Medium org: shared inference pool (repeatable operation)

Goal: one cluster that multiple users can submit to, with consistent defaults.

```bash
export LLAMA_BIN=llama-cli
export LLAMA_MODEL=<MODEL_FILE.gguf>
bash scripts/peer_os_wizard.sh --business --profile balanced
mesh_runtime submit-workflow-batch <addr> scripts/workflow_llama_local_autosplit_2_safe.json 20 250
```

Use `workflow-status` and `get-output` for every job; use `explain-placement` when you want to confirm the cluster is choosing the best owners under pressure.

### AI-5) Large org: adaptive pool (resource aggregation + automatic adaptation)

Goal: let the runtime continuously trade off locality vs distribution as CPU/memory/network pressure changes.

```bash
export LLAMA_BIN=llama-cli
export LLAMA_MODEL=<MODEL_FILE.gguf>
bash scripts/peer_os_wizard.sh --business --profile balanced
mesh_runtime submit-workflow <addr> scripts/workflow_llama_local_autosplit_2_safe.json
mesh_runtime submit-workflow <addr> scripts/workflow_process_autosplit.json
```

This is the normal "hybrid" path: AI shards can spread out while other autosplit jobs compete for CPU, and the coordinator adapts priorities automatically.

### PAR-1) Parallel non-AI workloads (process + WASM)

```bash
bash scripts/peer_os_wizard.sh --multi-node --profile balanced
mesh_runtime submit-workflow <addr> scripts/workflow_process_autosplit.json
mesh_runtime submit-workflow <addr> scripts/workflow_wasm_autosplit.json
```

### PAR-2) Validate the parallel path under load (smoke, then batch)

```bash
bash scripts/peer_os_wizard.sh --business --profile balanced
mesh_runtime submit-workflow <addr> scripts/workflow_smoke.json
mesh_runtime submit-workflow-batch <addr> scripts/workflow_smoke.json 25 100
```


## Use Cases (ML Workloads)

Peer-OS can run classic ML flows (preprocessing, training shards, inference batches) using the same submit/status/output commands.

### ML-1) Single-node ML preprocessing

Goal: run preprocessing locally before scaling out.

```bash
bash scripts/peer_os_wizard.sh --home --profile balanced
mesh_runtime submit-workflow <addr> scripts/workflow_process_demo.json
```

### ML-2) Multi-node feature/preprocessing pipeline

Goal: split heavy preprocessing across nodes.

```bash
bash scripts/peer_os_wizard.sh --multi-node --profile balanced
mesh_runtime submit-workflow <addr> scripts/workflow_process_autosplit.json
```

### ML-3) Batch inference at scale (CPU/GPU mixed cluster)

Goal: run repeated inference jobs with adaptive placement.

```bash
bash scripts/peer_os_wizard.sh --business --profile balanced
mesh_runtime submit-workflow-batch <addr> scripts/workflow_llama_local_autosplit_2_safe.json 20 250
mesh_runtime workflow-status <addr> <workflow_id>
```

Use `mesh_runtime explain-placement <addr> <work_unit.json>` to verify resource-driven decisions.

### ML-4) Durability-focused training/inference artifacts

Goal: keep stronger protection for intermediate and final model outputs.

```bash
MESH_DURABILITY_MODE=quorum bash scripts/peer_os_wizard.sh --business --profile strict
mesh_runtime submit-workflow <addr> scripts/workflow_process_autosplit.json
mesh_runtime get-output <addr> <output_key>
```

### ML-5) Hybrid ML + non-ML workload pool

Goal: run ML jobs and standard process/WASM jobs on one cluster.

```bash
bash scripts/peer_os_wizard.sh --business --profile balanced
mesh_runtime submit-workflow <addr> scripts/workflow_llama_local_autosplit.json
mesh_runtime submit-workflow <addr> scripts/workflow_wasm_autosplit.json
mesh_runtime submit-workflow <addr> scripts/workflow_process_autosplit.json
```
## Use Cases (Debugging / Understanding Decisions)

### 9) "Why did it choose that node?"

Goal: see the scoring and acceptance reasons for a work unit placement.

```bash
mesh_runtime explain-placement <addr> <work_unit.json>
```

What you get: a scored candidate breakdown and the selected owner (or reject reason).

### 10) "Is my cluster healthy?"

Goal: check that workflows are running and outputs are coming back.

```bash
mesh_runtime workflow-status <addr> <workflow_id>
mesh_runtime get-output <addr> <output_key>
```

## Use Cases (Benchmarking)

### 11) Quick runtime validation

Goal: verify "submit, schedule, execute, outputs" end-to-end.

```bash
bash scripts/peer_os_wizard.sh --benchmark --profile fast
mesh_runtime submit-workflow <addr> scripts/workflow_smoke.json
```

## Use Cases (One Big Computer Boundary)

These are setups where you want strong locality: minimal moving parts, low latency, and data staying close to the machine that is running it.

### OBC-1) Single computer task runner (fast feedback)

```bash
bash scripts/peer_os_wizard.sh --home --profile fast
mesh_runtime submit-workflow <addr> scripts/workflow_process_demo.json
```

### OBC-2) Local-only WASM (portable job, no cluster needed)

```bash
bash scripts/peer_os_wizard.sh --home
mesh_runtime submit-workflow <addr> scripts/workflow_wasm_demo.json
```

### OBC-3) Offline or air-gapped single machine validation

```bash
bash scripts/peer_os_wizard.sh --home
mesh_runtime submit-workflow <addr> scripts/workflow_smoke.json
```

## Use Cases (Distributed Compute Engine Boundary)

These are setups where you want throughput: auto-shard, parallelism, and work spread across nodes when the job benefits from it.

### DCE-1) CPU throughput burst (autosplit across nodes)

```bash
bash scripts/peer_os_wizard.sh --multi-node --profile balanced
mesh_runtime submit-workflow <addr> scripts/workflow_process_autosplit.json
```

### DCE-2) WASM throughput burst (distributed WASM)

```bash
bash scripts/peer_os_wizard.sh --multi-node --profile balanced
mesh_runtime submit-workflow <addr> scripts/workflow_wasm_autosplit.json
```

### DCE-3) AI/LLM shard workflows (if helper runner is available on the nodes)

```bash
bash scripts/peer_os_wizard.sh --ai --profile balanced
mesh_runtime submit-workflow <addr> scripts/workflow_llama_local_autosplit.json
```

### DCE-4) Sustained throughput (repeated submissions)

```bash
bash scripts/peer_os_wizard.sh --business --profile balanced
mesh_runtime submit-workflow-batch <addr> scripts/workflow_smoke.json 50 100
```

## Use Cases (Dynamic Resource Allocation / Aggregation / Adaptation)

These are setups where you rely on the runtime to continuously rebalance between the two boundary domains based on real pressure (CPU, memory, network, active tasks, shardability, and data movement cost).

### DYN-1) Scale out only when needed (start local, then add nodes)

Start local:

```bash
bash scripts/peer_os_wizard.sh --home
mesh_runtime submit-workflow <addr> scripts/workflow_process_demo.json
```

When you need throughput, add nodes and switch to autosplit:

```bash
bash scripts/peer_os_wizard.sh --multi-node
mesh_runtime submit-workflow <addr> scripts/workflow_process_autosplit.json
```

### DYN-2) Hot-node protection under load (automatic weight reduction)

```bash
bash scripts/peer_os_wizard.sh --business --profile balanced
mesh_runtime submit-workflow-batch <addr> scripts/workflow_smoke.json 25 100
mesh_runtime explain-placement <addr> <work_unit.json>
```

Run `explain-placement` when the cluster is cold and again under load to see scoring shifts.

### DYN-3) Heterogeneous nodes (automatic best-owner selection)

```bash
bash scripts/peer_os_wizard.sh --business --profile balanced
mesh_runtime submit-workflow <addr> scripts/workflow_process_autosplit.json
mesh_runtime explain-placement <addr> <work_unit.json>
```

### DYN-4) Network-aware tradeoff (locality vs distribution)

If the network is constrained, prefer the locality boundary:

```bash
bash scripts/peer_os_wizard.sh --home
mesh_runtime submit-workflow <addr> scripts/workflow_process_demo.json
```

If the network is good and the job is shardable, prefer the distributed boundary:

```bash
bash scripts/peer_os_wizard.sh --multi-node
mesh_runtime submit-workflow <addr> scripts/workflow_process_autosplit.json
```

### DYN-5) Hybrid day-to-day cluster (mixed workloads without mode switches)

```bash
bash scripts/peer_os_wizard.sh --business --profile balanced
mesh_runtime submit-workflow <addr> scripts/workflow_process_demo.json
mesh_runtime submit-workflow <addr> scripts/workflow_process_autosplit.json
mesh_runtime workflow-status <addr> <workflow_id>
```

## Use Cases (Distributed Memory: OBM)

OBM (One Big Memory) is an optional distributed shared-state layer (cache + coordination memory + checkpointed state) that can sit next to Peer-OS without changing core Peer-OS internals. OBM durability artifacts can be stored through a live Peer-OS node via `ObjPut`/`ObjGet`.

### OBM-0) Minimal OBM bring-up (binaries only)

1) Start a Peer-OS node (used as the durability object store):

```bash
LISTEN="/ip4/127.0.0.1/tcp/7001" mesh_runtime serve
```

2) Start OBM controller and agent (assuming you have the compiled OBM binaries available):

```bash
obm-controller --listen 127.0.0.1:8900 --state-file .obm-controller-state.json
obm-agent --listen 127.0.0.1:8800 --controller 127.0.0.1:8900 --peeros-store-peer <addr>
```

3) Your app (or a small helper tool) uses OBM as memory:

- `alloc` shared state
- `read` / `write` updates
- `barrier` / coordination
- `checkpoint` when you want recoverable state

### Home

- Smart-home state bus: device status, automations, last sensor values shared across hubs
- Family media progress sync: watch/listen position and recommendations across TV/tablet/phone
- Local game session state: shared world/session data across home nodes

### Personal

- Personal AI memory: store recent context, embeddings, and tool state across your laptop + homelab node
- Cross-device workspace state: notes, drafts, clipboard-like shared memory
- Hobby analytics: rolling metrics/state for self-hosted dashboards

### Business (SMB/Startup)

- Live app session/cache layer: carts, session flags, feature toggles
- Ops dashboard state: job progress, queue counters, SLA timers
- Edge telemetry buffer: store and replicate recent IoT/device windows before durable export

### Enterprise

- Real-time feature/state cache for ML inference services
- Distributed workflow state: task progress, intermediate blobs, recovery checkpoints
- Multi-node control-plane memory: shared policy/config snapshots with failover and fencing

### Durability mode guidance

- `best_effort`: home/personal, low-risk transient state
- `quorum`: most business workloads
- `strict`: enterprise-critical flows needing stronger replica ACK guarantees

### Where OBM is not the right primary store

Financial ledgers, compliance records, or global transactions that require full consensus database semantics as system-of-record. Use OBM as a fast distributed memory tier in front of those systems.

## Practical Aggregation/Adaptation Examples (User-Oriented)

### Memory (OBM + DSM)

- Shared cache/session state across nodes: alloc/read/write/checkpoint through OBM, large buffers/pages through DSM
- Distributed workflow coordination state: leases, barriers, ownership hints in OBM
- Checkpointed state that survives node loss: OBM replicas + WAL + checkpoints stored via Peer-OS object store

### CPU aggregation/adaptation

- Auto-shard batch jobs across many CPU nodes for throughput: submit `scripts/workflow_process_autosplit.json`
- Keep latency-sensitive tasks local-first, then overflow under pressure: start `--home`, later switch to `--multi-node`
- Degrade GPU-intended work to CPU paths when GPU admission is unavailable: run the CPU workflow variant (process or WASM) while the cluster is GPU-constrained

### GPU aggregation/adaptation

- Place inference units on nodes with free VRAM and healthy GPU telemetry: rely on placement scoring and check decisions with `explain-placement`
- Split model execution across GPU nodes (TP/PP-style sharded flows): choose a workflow with higher `preferred_parallelism` and run more nodes
- Hybrid fallback in heterogeneous clusters: GPU on strong nodes, CPU on helper nodes for pre/post processing

### NIC aggregation/adaptation

- Route bulk-transfer workflows to high-bandwidth nodes: use NIC-aware placement; if your work units support a `network_cost_class` hint, use `bulk`/`high`
- Reduce network pressure for object movement: prefer compression-aware transfers when available and keep locality when bandwidth is limited
- Prefer pools with better transport characteristics: run the same workload and let the coordinator pick the best path among supported transports

### Disk aggregation/adaptation

- Replicate objects/checkpoints across nodes for durability and recovery: use `MESH_DURABILITY_MODE=quorum|strict` when it matters
- Use disk-backed store as a persistence tier with restart replay: store important artifacts as objects and re-fetch on restart
- Treat disk as a slower spill tier when memory pressure rises: let the coordinator bias away from hot/memory-starved nodes

### Combined memory+CPU+GPU+disk+NIC adaptation

- Distributed LLM serving: GPU for inference shards, CPU for pre/post, OBM for shared session state, disk for checkpoints, NIC-aware placement for model/object transfer
- Real-time analytics pipeline: CPU ingest/parse, GPU scoring, OBM shared feature state, disk WAL/checkpoints, high-bandwidth nodes for shuffle stages
- Edge-to-core deployment: local node handles low-latency slice, heavy compute spills to cluster CPUs/GPUs, OBM keeps global state coherent, disk/NIC policies manage durability and transfer cost

## Use Cases (Web3 / Blockchain)

Peer-OS is not a blockchain and does not provide consensus or a ledger. It is useful for running Web3 workloads (nodes, indexers, provers, batch jobs) and for providing fast distributed state (OBM) in front of systems-of-record.

### WEB3-1) Run a full node or RPC stack (DevNet / staging)

Goal: run one or more blockchain services as normal process workloads.

```bash
bash scripts/peer_os_wizard.sh --business --profile balanced
mesh_runtime submit-workflow <addr> scripts/workflow_process_demo.json
```

Replace the workflow program with your client binary (examples: execution client, consensus client, RPC gateway).

### WEB3-2) Indexer / ETL across blocks (throughput-first)

Goal: parse blocks/events and build a search index or analytics tables.

```bash
bash scripts/peer_os_wizard.sh --multi-node --profile balanced
mesh_runtime submit-workflow <addr> scripts/workflow_process_autosplit.json
```

Use autosplit when the work can be sharded by block range or partition key.

### WEB3-3) Off-chain workers / keepers (many small periodic jobs)

Goal: run lots of small jobs reliably (price feeds, rebalancers, watchers).

```bash
bash scripts/peer_os_wizard.sh --business --profile balanced
mesh_runtime submit-workflow-batch <addr> scripts/workflow_smoke.json 50 250
```

Swap the smoke workflow for your worker workflow once it is validated.

### WEB3-4) Shared session/cache/state for Web3 services (OBM)

Goal: share hot state across a Web3 service tier (rate limits, session flags, last-seen block, fast caches).

```bash
obm-controller --listen 127.0.0.1:8900 --state-file .obm-controller-state.json
obm-agent --listen 127.0.0.1:8800 --controller 127.0.0.1:8900 --peeros-store-peer <addr>
```

Use OBM as the fast state tier; keep final records in a real database or chain state.

### WEB3-5) Prover / batch verification workloads (parallel compute)

Goal: run provers/verifiers as parallel shards when the workload supports partitioning.

```bash
bash scripts/peer_os_wizard.sh --business --profile balanced
mesh_runtime submit-workflow <addr> scripts/workflow_wasm_autosplit.json
```

WASM is a good fit for portable verifier/prover components.

## Use Cases (Media / Broadcast / Streaming)

Peer-OS is a good fit for media pipelines because many tasks are shardable and benefit from CPU/GPU aggregation, plus NIC-aware placement when moving large assets.

### MEDIA-1) Video transcoding farm (batch)

Goal: split a big batch of transcodes across nodes automatically.

```bash
bash scripts/peer_os_wizard.sh --multi-node --profile balanced
mesh_runtime submit-workflow <addr> scripts/workflow_process_autosplit.json
```

Replace the workflow program with your transcoder (ffmpeg-like) and shard by file list or time slices.

### MEDIA-2) Live clipping and highlights (low latency + burst)

Goal: keep low latency local-first, then burst to helpers when the load spikes.

```bash
bash scripts/peer_os_wizard.sh --home --profile fast
mesh_runtime submit-workflow <addr> scripts/workflow_process_demo.json
```

When bursts happen:

```bash
bash scripts/peer_os_wizard.sh --multi-node --profile balanced
mesh_runtime submit-workflow <addr> scripts/workflow_process_autosplit.json
```

### MEDIA-3) Audio normalization / loudness pipeline (parallel CPU)

```bash
bash scripts/peer_os_wizard.sh --multi-node --profile balanced
mesh_runtime submit-workflow <addr> scripts/workflow_process_autosplit.json
```

### MEDIA-4) Packaging and manifest generation (DASH/HLS style)

Goal: run packaging jobs near where the media objects are stored, then replicate outputs as objects.

```bash
bash scripts/peer_os_wizard.sh --business --profile balanced
mesh_runtime submit-workflow <addr> scripts/workflow_process_demo.json
```

### MEDIA-5) Broadcast graphics / render bursts (CPU/GPU mixed)

Goal: run CPU pre/post work on helper nodes and schedule render shards where GPU is available.

```bash
bash scripts/peer_os_wizard.sh --business --profile balanced
mesh_runtime submit-workflow <addr> scripts/workflow_process_autosplit.json
mesh_runtime explain-placement <addr> <work_unit.json>
```

Use `explain-placement` to confirm the cluster is choosing the right owners under load.

## Picking The Right Setup (Simple Rules)

- If you have 1 machine: start with `--home`.
- If you have 2+ machines or want speed: use `--multi-node` (or `--business`).
- If the job can split: use an `*_autosplit.json` workflow.
- If you want to keep data close: use 1 node or reduce node count; the coordinator will still adapt when pressure changes.
- If the job is AI/LLM: use `--ai` and the `workflow_llama_*.json` samples.
