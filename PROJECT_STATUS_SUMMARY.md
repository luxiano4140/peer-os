# Peer-OS Mesh Runtime – Implementation Status Summary

Last updated: 2026-03-12

## Repo Layout (Two Runtimes)

This repo currently contains **two separate Rust packages** (both named `mesh_runtime`):

- `./` (repo root): minimal runtime + basic GPU aggregation/binding.
- `./mesh_runtime/`: full Peer-OS runtime (cluster snapshot/budgets, distributed LLM, per-device GPU placement/binding).

## Workflow Sharding Model
Peer-OS/mesh_runtime can dispatch a single workflow task across multiple nodes by expanding the task into shard units when `auto_split=true` and `preferred_parallelism > 1`. Each shard is scheduled independently.

All shards execute the same binary or process. The application must therefore be shard-aware (or wrapped with a thin adapter) so that it:
- Consumes shard IDs or input slices
- Produces per-shard outputs
- Supports later aggregation/merge of results

The runtime does not automatically parallelize internal regions of a binary or decompile processes into parallel segments.

## CLI Feature Coverage
The current Peer-OS CLI implements the full command set described in the README, including:
- host serve
- serve
- workflow submissions (with idempotency keys)
- submit-llama-distributed
- put-object
- get-object
- get-output
- cluster-state
- cluster-snapshot
- PUCE/tensor-parallel helpers

## Milestone Status
According to IMPLEMENTATION_BACKLOG.md:
- M0 through M7: DONE
- M5.5 (Adaptive Micro-Batching): IMPLEMENTED (initial + early closed-loop feedback); calibration/tuning follow-up remains

All core infrastructure components are implemented, including:
- Runtime and scheduling
- Storage layer
- Distributed Shared Memory (DSM)
- Conflict resolution
- Aggregation pipelines
- Tensor/pipe parallel execution

Remaining work is largely refinement/tuning (profile defaults, SLO calibration, and higher-fidelity telemetry), not missing core subsystems.

## AI Workloads
- The distributed llama/TP-PP path is marked DONE in the backlog (M5): rank-aware workflow planning, model refs, shard loaders, collectives, KV replication, submit-llama-distributed CLI, and local/demo runners all exist.
- Adaptive micro-batching (M5.5) is implemented; remaining work is tuning thresholds/guardrails using real traces and tightening SLO-gated defaults per hardware class.

## “One Big Computer” Support
Peer-OS exposes the aggregation toolbox required to present a unified compute surface across heterogeneous nodes (macOS, Windows, Linux), including:
- Resource envelopes
- Multipath/bulk transfer
- Distributed Shared Memory (DSM) and cache
- Scheduler conflict management
- Tensor/pipe parallel orchestration (TP/PP)

Heavy smoke and benchmark gates (scripts/verify_heavy.sh, scripts/bench_matrix.sh, multi-node demos) continuously validate the multi-node “big computer” behavior.

Adaptation note: the repo includes **LLM/runtime-specific adaptation** (pool-aware placement + optional dtype downshift in distributed collectives), but **generic cross-resource adaptation** (CPU↔GPU, memory↔disk, etc.) is not implemented as a first-class scheduler feature yet.

## Autosplit for Ordinary Binaries
Auto-split works for standard binaries/processes provided they are made shard-friendly. When `auto_split=true` and `preferred_parallelism` is set, the runtime expands a workflow task into multiple shards and injects shard metadata (e.g., `MESH_SHARD_ID`).

With `shard_input_bytes=true`, stdin can be sliced per shard. Each shard must:
- Read its assigned slice (via environment variables or stdin)
- Produce a shard-specific output key
- Optionally participate in a merge/reduce step

Cross-node orchestration, scheduling, and shard distribution are handled by the runtime.

## Core Features

### Distributed Workflow Execution
- Start runtime: `cargo run -- serve`
- Multi-node host control: `host serve --config <host.json>`
- Submit DAGs: `cargo run -- submit-workflow <peer_multiaddr> <workflow.json>`

The runtime schedules tasks locally or on peers, routes object gets/puts, and persists scheduler profiles and telemetry in the store.

### Autosplit / Process Sharding
Set:
- `auto_split=true`
- `preferred_parallelism>1`
- Optional: `shard_env=true`, `shard_input_bytes=true`

A single task expands into shard units with `MESH_SHARD_*` environment metadata. Wrapper scripts can be used for explicit input slicing. Results can be merged via dependent tasks.

### LLM TP/PP Distributed Workloads
Submit with:

`cargo run -- submit-llama-distributed <peer> <model> "<prompt>"`

Optional flags:
- `--tp`
- `--pp`
- `--rank-model-refs`
- `--puce-ai-manifest`

The planner builds rank-aware TP/PP workflows. PUCE runtimes load shards via `LLAMA_SHARD_*` environment variables, and collectives/merge strategies maintain coherent outputs.

### PUCE Integration & Compression Controls
Compile with:

`--features puce_runtime`

Control via environment variables:
- `MESH_PUCE_ENABLE`
- `MESH_PUCE_BACKEND`
- `MESH_PUCE_STORE`
- `MESH_PUCE_RUNTIME`
- `MESH_PUCE_TRANSPORT_PROFILE`

Provides compression/decompression and runtime tensor hooks with safe defaults.

### Transport & Aggregation Modes
- Default: TCP
- Optional features: `p2p_quic`, `p2p_webrtc`
- Configure `LISTEN` multiaddrs (TCP/UDP/QUIC)

Multipath and bulk policies allow striping large transfers across direct and relay links.

### DSM / Coherent Memory
MemoryManager tracks:
- Regions/pages
- Leases
- Cache states (`Invalid`, `Shared`, `Exclusive`)

Runtime hooks support owner redirection and conflict management. Conflict telemetry (e.g., `conflict_wait_ms`) is exported.

### Resource Envelopes & Scheduling
Nodes advertise CPU/RAM/GPU/disk/NIC quotas via CLI/env (`--resources`, `MESH_NODE_*`, labels, cost classes).

Scheduler enforces:
- Admission control
- Fairness (interactive vs batch)
- Conflict backoffs
- Placement cooldowns

GPU notes:
- Telemetry collectors support NVIDIA (`nvidia-smi`) and AMD/ROCm (`rocm-smi`) (best-effort).
- The `./mesh_runtime/` runtime supports per-device GPU placement/reservations and injects device binding env (`CUDA_VISIBLE_DEVICES`/`HIP_VISIBLE_DEVICES`/`ROCR_VISIBLE_DEVICES`).

### Observability & Cluster Registry
Endpoints:
- `/metrics`
- `/healthz`
- `/readyz`

RPCs (`NodeInfo`, `ClusterState`, etc.) expose telemetry and counters. Validation scripts include `scripts/smoke_metrics_multipath.sh`.

### Autosplit & Benchmark Tooling
- `scripts/smoke_process_autosplit.sh`
- `bench_wasm_distributed.sh`
- `scripts/bench_multipath_vs_singlepath.sh`
- `bench_matrix.sh`
- `scripts/compose_big_computer_*`

Used for split demos, throughput regression checks, and multi-node orchestration validation.

### Durability & Security
Implemented features:
- Persistent store
- Chunked bulk transfer (`ObjPutChunk`)
- Replay protection
- Signed metadata
- Durable runtime checkpoints

CLI helpers:
- `put-object`
- `get-object`
- `cluster-snapshot`

### AI Micro-Batching (Current Status)
Adaptive micro-batching (M5.5) is implemented with initial closed-loop behavior:
- Per-model queueing and early dynamic sizing paths
- Feedback-driven adaptation hooks in distributed runtime flows
- Ongoing work focused on calibration/tuning per hardware class and stricter SLO defaults

All other core infrastructure milestones are complete.

## User-Facing Documentation Status

User-facing docs are aligned with current binary-first operation:
- `README.md` tracks latest runtime/module integration status and capability matrix
- `docs/COMPLETE_EXAMPLES.md` provides the simple how-to path and 1-node vs multi-node resource adaptation map
- `use_cases.md` provides runtime feature-first examples plus home/business/professional/ML use cases
