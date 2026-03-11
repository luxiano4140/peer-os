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

### 11) Optional durability modes (simple knob)

If you want stronger durability behavior, set a mode before starting nodes:

```bash
MESH_DURABILITY_MODE=best_effort LISTEN="/ip4/127.0.0.1/tcp/7001" mesh_runtime serve
MESH_DURABILITY_MODE=quorum LISTEN="/ip4/127.0.0.1/tcp/7001" mesh_runtime serve
MESH_DURABILITY_MODE=strict LISTEN="/ip4/127.0.0.1/tcp/7001" mesh_runtime serve
```

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

## Use Cases (AI / LLM Workflows)

### 8) LLM autosplit run (two or more nodes)

Goal: run the prepared LLM workflow samples.

```bash
bash scripts/peer_os_wizard.sh --ai
mesh_runtime submit-workflow <addr> scripts/workflow_llama_local_autosplit.json
```

Notes:

- Some AI samples require helper runners that must already be available to the nodes (the wizard prints what to use).
- Use the `_safe.json` variants when available.

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

## Picking The Right Setup (Simple Rules)

- If you have 1 machine: start with `--home`.
- If you have 2+ machines or want speed: use `--multi-node` (or `--business`).
- If the job can split: use an `*_autosplit.json` workflow.
- If you want to keep data close: use 1 node or reduce node count; the coordinator will still adapt when pressure changes.
- If the job is AI/LLM: use `--ai` and the `workflow_llama_*.json` samples.
