# Peer-OS — One Big Computer Runtime

Peer-OS is a distributed compute runtime that aggregates CPU, RAM, disk, and NIC resources across multiple nodes and presents them as a unified execution fabric.

This document reflects the current architecture including:

- Smart Aggregation Coordinator (v3)
- Automatic Monolithic App Sharding (Auto-Shard v1)
- NIC-aware scheduling
- DSM-based distributed memory
- Adaptive load balancing

Last updated: 2026-03-04

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

## Build & Run

```bash
cargo build
cargo run -- serve
```

Multi-node cluster can run on a single machine using multiple ports.

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
