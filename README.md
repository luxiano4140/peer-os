# Peer-OS — One Big Computer Runtime

Peer-OS is a distributed compute runtime that aggregates CPU, RAM, disk, and NIC resources across multiple nodes and presents them as a unified execution fabric.

This document reflects the current architecture including:

- Smart Aggregation Coordinator (v3)
- Automatic Monolithic App Sharding (Auto-Shard v1)
- NIC-aware scheduling
- DSM-based distributed memory
- Adaptive load balancing

Last updated: 2026-03-12

---

## Protocol Versioning Roadmap

Current cluster capability protocol: **v1**

Planned upgrade: **Capability Protocol v2**

v2 will introduce:

- Transport-aware metrics (QUIC / WebRTC / TCP)
- RTT-aware scheduling inputs
- Compression efficiency metrics (PUCE-aware)
- Explicit capability version envelope
- Backward-compatible deserialization
- Mixed-version cluster tolerance during rolling upgrades

This requires coordinated schema evolution across:

- NodeCapabilities
- ClusterResourcesView
- RPC::CapabilityAnnounce
- SmartCoordinator cost model
- Scheduler scoring layer

⚠️ v2 is a protocol evolution and will be implemented with version negotiation to avoid wire breakage.

---

## Latest Update (2026-03-12)

- Synced full project snapshot to both private repos:
  - `luxiano3990/Peer-Os` (full project)
  - `luxiano3990/peer-os-runtime` (runtime mirror branch currently carries the same snapshot)
- Completed GPU runtime coverage:
  - NVIDIA (`nvidia-smi`) + AMD/ROCm (`rocm-smi`) telemetry collectors (best-effort).
  - Per-device GPU placement/reservations and device binding env injection in `mesh_runtime/`.
- Expanded distributed LLM runtime paths:
  - Added adaptation engine and replicated orchestrator/workflow modules in `mesh_runtime/src/distributed_llm/`.
  - Upgraded TP/PP planner, collectives, KV cache, failure handling, and workflow assembly paths.
- Expanded scheduler/runtime surfaces in root runtime:
  - Updated `src/runtime.rs`, `src/main.rs`, `src/bin/peer.rs`, and related schema/network/memory paths.
- Added benchmark and validation tooling:
  - New benchmark harness scripts and benchmark suites under `scripts/` and `benchmarks/`.
  - Added new benchmark/docs reports under `docs/` and artifact captures under `artifacts/`.
- Added new integration areas:
  - `k8-adaptor/` scaffold and `external/obm/` workspace content.
  - Added `external/docker-vm-adaptor/` gateway for container/VM job translation into workflow submits.
- Updated user-facing documentation for latest runtime surfaces:
  - refreshed `docs/COMPLETE_EXAMPLES.md` with one-node vs multi-node resource adaptation map
  - expanded `use_cases.md` with runtime feature-first examples plus professional/enterprise, ML, and resource aggregation/adaptation use cases
  - refreshed `PROJECT_STATUS_SUMMARY.md` to align milestone wording and user-facing doc status
- Completed external OBM distributed-memory module paths (`external/obm`):
  - real agent-to-agent invalidation and distributed replica commit ACK paths
  - quorum/strict durability enforcement across OBM replicas
  - owner failover with epoch fencing, WAL replay, and replica promotion
  - authenticated OBM RPC envelope and signed lease tokens
  - runtime transport matrix for OBM RPC (TCP, QUIC, WebRTC)
  - chaos/perf/equivalence coverage and practical SDK examples (`rpc_smoke`, `perf_equivalence_smoke`, `obm_kv_demo`)

---

## Full Status Matrix (2026-03-12)

### Implemented and Active

- Core mesh runtime:
  - DAG submit/schedule/execute (`serve`, `submit-workflow`)
  - TCP transport baseline, optional QUIC/WebRTC builds
  - ownership + placement + scheduler admission paths
- Runtime data plane:
  - object store + replication modes
  - DSM lease/read/writeback/invalidate paths
  - PUCE object codec integration and profile toggles
- Distributed LLM paths:
  - TP/PP planning and rank workflow assembly
  - adaptive and replicated orchestration modules under `mesh_runtime/src/distributed_llm/`
  - distributed LLM integration tests
- Benchmarking/validation:
  - benchmark harnesses under `scripts/` and `benchmarks/`
  - cross-node/cross-platform artifact exports under `artifacts/` and `export_bundle/`
- Extended project modules:
  - `external/obm` module set is included, versioned, and end-to-end validated in-repo
  - OBM validation coverage now includes transport matrix runtime smokes (TCP/QUIC/WebRTC), auth-reject negative paths, multi-node failover/invalidation/quorum tests, and perf/equivalence regression scripts
  - `k8-adaptor/` module scaffold is included and versioned in-repo
  - `external/docker-vm-adaptor/` module scaffold is included for Docker/container/VM workflow integration

### In Progress / Partial

- GPU operations:
  - NVIDIA (`nvidia-smi`) + AMD/ROCm (`rocm-smi`) telemetry collectors (best-effort)
  - per-device placement/reservations + device binding env injection are implemented in `mesh_runtime/`
  - remaining gaps: richer cluster-level GPU free/used aggregation surfaces + Intel GPU collector
- Live migration:
  - migration control-plane state machine is present
  - full process/CRIU and full WASM runtime-state restore remain partial
- DSM migration optimization:
  - correctness path is present
  - dirty-page pre-copy optimization remains basic

### Known Gaps

- No consensus-backed durability protocol yet
- No full multi-machine bootstrap/join UX beyond current mechanisms
- `src/wasmrt.rs` execution path still requires deeper WASM/WASI runtime completion

### Where to Track Detailed State

- Root/full-project status: `status.md`
- Runtime technical depth: `mesh_runtime/status.md`
- Runtime incremental history: `mesh_runtime/CHANGELOG.txt`

---

---

## Core Capabilities

### 1. Resource Aggregation

Cluster-wide aggregation of:

- CPU cores
- Memory (local + DSM-backed)
- Disk-backed object store
- Network bandwidth (NIC-aware scheduling)

Cluster state is continuously propagated via capability announcements.

---

### 2. Smart Aggregation Coordinator (v3)

Deterministic leader (lowest NodeId) performs:

- Global resource monitoring
- Pressure detection (CPU / memory / task skew / NIC)
- Adaptive scheduling weight adjustments
- Hot node protection
- Stateless shard redistribution
- Predictive dampening

No single point of failure. Leadership re-elects automatically.

---

### 3. Automatic Monolithic App Sharding (Auto-Shard v1)

If `auto_split = true` and a workflow has a single task:

Peer-OS automatically:

1. Reads input size
2. Reads cluster resources
3. Computes optimal shard_count
4. Expands workflow
5. Schedules shards across nodes

Works for:

- Linux process/binary workloads
- WASM/WASI workloads

No manual shard configuration required.

---

### 4. Distributed Shared Memory (DSM)

Lease-based single-writer / multi-reader coherence model:

- DsmAcquireRead / DsmAcquireWrite
- DsmWriteback
- DsmInvalidate
- Batch operations
- Conflict telemetry

WASM shards can share distributed memory pages across nodes.

---

### 5. Adaptive Scheduling

Scheduler scoring considers:

- CPU cores
- Free memory
- Active tasks
- Network bandwidth
- Dynamic pressure penalties

Hot nodes automatically lose scheduling priority.

---

## Execution Model

Workflows → DAG → Scheduler → Distributed Execution

Execution targets:

- WASM (WASI)
- Native Linux processes

Ownership determined via rendezvous hashing with adaptive override.

---

## OBM + Resource Aggregation/Adaptation Use Cases

You can use OBM as a distributed shared-state layer (cache + coordination memory + checkpointed state), with no changes to core Peer-OS, while Peer-OS aggregates and adapts CPU/GPU/NIC/disk resources for end-to-end distributed execution.

Examples by resource:

- Memory (OBM/DSM): shared cache/session state, distributed coordination state, and durable checkpointed page state across nodes.
- CPU aggregation/adaptation: auto-shard batch jobs across CPU pools, keep latency-critical tasks local-first, and spill to helper nodes under pressure.
- GPU aggregation/adaptation: place inference/training units by VRAM/telemetry, run TP/PP distributed paths on capable GPU nodes, and degrade to CPU/hybrid pools when needed.
- NIC aggregation/adaptation: route bulk flows to high-bandwidth nodes/classes, use compression-aware transfer paths, and select transport/runtime paths (TCP/QUIC/WebRTC) per environment.
- Disk aggregation/adaptation: replicate objects/checkpoints across nodes, use disk-backed store/replay for recovery, and treat disk as a slower spill tier.

Combined resource examples:

- Distributed LLM serving: GPU for inference, CPU for orchestration/pre-post, OBM for shared session/control state, disk for checkpoints/WAL, NIC-aware placement for model/object movement.
- Real-time analytics pipeline: CPU ingest/parse, GPU scoring, OBM shared feature state, disk durability tier, and high-bandwidth NIC routing for shuffle-heavy stages.
- ML training + inference pipeline: autosplit preprocessing across CPU nodes, optional GPU-aware inference placement, explain-placement audits, and quorum/strict durability mode for model artifacts.
- Edge-to-core execution: low-latency local slice on edge node, cluster CPU/GPU overflow for heavy work, OBM shared state continuity, and disk/NIC policy-driven recovery and transfer.

---

## Run The Compiled Binary

Below, `mesh_runtime` means the compiled runtime binary already available on your machine.

```bash
mesh_runtime serve
```

Multi-node cluster can run on a single machine using multiple ports.

New here:

- Start with [docs/COMPLETE_EXAMPLES.md](docs/COMPLETE_EXAMPLES.md) for the binary-first user guide.
- Use [use_cases.md](use_cases.md) for complete one-node, multi-node, AI, professional, and resource-adaptation use cases.
- Use [docs/COMPLETE_EXAMPLES_IMPLEMENTATION.md](docs/COMPLETE_EXAMPLES_IMPLEMENTATION.md) when you want the full recipe catalog.
- For external distributed memory examples, see `external/obm/README.md` and run:
  - `./external/obm/scripts/smoke_rpc_path.sh`
  - `./external/obm/scripts/verify_transport_matrix.sh`
  - `./external/obm/scripts/verify_chaos_perf_equivalence.sh`
- For external container/VM integration examples, see `external/docker-vm-adaptor/README.md` and run:
  - `./external/docker-vm-adaptor/scripts/smoke_gateway_workflow.sh`

---

## Current Status

Implemented:

- CPU aggregation
- Memory aggregation
- Disk-backed store
- NIC resource awareness
- Auto-sharding monolithic apps
- Smart coordinator (adaptive scheduling)
- Stateless shard redistribution

Implemented (optional, profile-driven):

- GPU aggregation phase:
  - GPU metadata + runtime telemetry in node info/heartbeats
  - VRAM/device-aware placement admission reservations
  - Optional process GPU device binding (`CUDA_VISIBLE_DEVICES`/ROCm envs)
- Stateful live task migration phase:
  - Migration RPC state machine (`Prepare -> Snapshot -> Transfer -> Restore -> Cutover -> Verify -> Cleanup`)
  - Migration fencing token persistence + cutover enqueue path
- DSM page live migration phase:
  - `DsmMigrateBegin/Chunk/Commit/Abort` RPC flow
  - Owner/lease/version cutover and reader invalidation on commit

---

Peer-OS now operates as a self-optimizing distributed compute fabric — a functional "One Big Computer" control plane.

See `docs/PRODUCTION_STATUS.md` for the expanded production status, policy knobs, verification matrix, and chaos tooling that reflect the current runtime capabilities.

## Windows runtime deployment

When you need to update the Windows hosts, run `scripts/deploy_windows_runtime.sh`; it cross-compiles `mesh_runtime.exe` for `x86_64-pc-windows-gnu` (default QUIC-enabled features) and copies the resulting binary into `WIN1_MESH_DIR`/`WIN3_MESH_DIR` under `WIN1_HOST`/`WIN3_HOST`. The script also appends each host/directory pair to `./.windows_runtime_deploy.log`, so you can see the exact path that was used the last time the rollout ran.

## Benchmarking suite

Automated benchmarking instructions, data formats, and the five initial regressions (`bench_submit.sh`, `bench_autosplit.sh`, `bench_objects.sh`, `bench_network.sh`, `bench_failure.sh`) live in `docs/benchmark-suite.md`. That sheet also documents `scripts/bench_submit_local_matrix.sh` for true client submit ACK latency on the root runtime, while `bench_submit.sh` remains the scheduler/completion benchmark.

### Detailed implementation highlights

- Full mesh runtime stack (`serve`, `submit-workflow`, mDNS peer discovery, DAG scheduler with dependency inference, WASM and Linux process execution with per-OS arguments/shard env slicing, and semaphored parallelism) is production-ready (`mesh_runtime/status.md:9-33`).
- Storage/compression layer implements soft object replication, PUCE compression/backends, `MESH_PUCE_BACKEND`/`MESH_PUCE_DELEGATE_ONLY` toggles, and codec profiles on top of the disk store (`mesh_runtime/status.md:34-44`).
- Observability and host-supervisor mode expose `/metrics`, `/healthz`, `/readyz`, Prometheus counters, deterministic supervisor labels, and multi-transport support (TCP, QUIC, WebRTC) even though the README summary below is shorter (`mesh_runtime/status.md:48-75`).
- Cluster/placement tooling covers TTL-based cluster state, `NodeInfo`/`Heartbeat`, placement hints (`require_roles`, `min_ram_bytes`, `network_cost_class`, `avoid_nodes`), explain-placement/audit logs, conflict metrics, and distributed LLM TP/PP automation (`mesh_runtime/status.md:75-77`).
- Production controls include the budget-aware M4 policy plane, durability/security fences (checkpoint replay, signed RPCs, trust enforcement), benchmark matrix, chaos/soak tooling, and the `scripts/verify_*` harnesses (including big-NIC/Docker/benchmark toggles) noted later in this README (`mesh_runtime/status.md:77-95`).

### Remaining depth gaps

- GPU: automatic host telemetry collectors and deeper collective optimization policy are still incremental work (current telemetry can be explicitly provided via envs).
- Task migration: process-level CRIU snapshot/restore and full WASM runtime-state restore are not yet complete.
- DSM migration: pre-copy dirty-page delta optimization is still basic; stop-copy correctness path is the current default foundation.
