# Peer-OS

Last updated: 2026-03-10

## Latest Project Status

Peer-OS is currently operating as a distributed workflow runtime with these implemented capabilities:

- Distributed execution with DAG scheduling (`serve`, `submit-workflow`, `explain-placement`).
- Multi-transport networking: TCP (default), QUIC (`--features p2p_quic`), WebRTC compile-check (`--features p2p_webrtc`).
- Placement scoring with audit/explain outputs and cluster-state TTL membership.
- Workflow execution targets: WASM/WASI and host process workloads.
- Auto-dependency inference + conflict-aware parallel scheduling.
- Replication and durability policy modes (`best_effort|quorum|strict`).
- Strict-mode security preflight for signing/trust enforcement.
- DSM lease/writeback/invalidate coherence path with metrics.
- Runtime profile presets (`fast|balanced|strict`) and profile matrix verification.
- Distributed LLM TP/PP and llama.cpp RPC workflow path.
- M4 control-plane features: fairness queues, budget admission, overload reject, forwarding fallback.
- M6 durability/security features: checkpoint replay, metadata/workflow replication, signed RPC paths.
- M7 benchmark/SLO harness integrated with verify scripts.

Current known gaps:

- No consensus-backed durability/read-repair quorum protocol yet.
- CRIU-backed process migration and full WASM runtime-state migration are not complete.
- DSM migration pre-copy optimization is basic.

## Benchmark Summary

### Benchmark Suite Fixed V1 (7/7 OK)

| Benchmark | Result |
|---|---|
| CPU resource aggregation | 63.38 tasks/s, scaling efficiency 0.9997, exec spread 14/18 |
| Distributed task aggregation | 11.88 tasks/s, placement skew 0.20, exec spread 9/6 |
| Distributed memory aggregation | 0.127 tasks/s, remote access latency 157.05 ms, derived bandwidth 6.68 MB/s |
| Disk-as-memory adaptation | Constrained run succeeded at 48 MiB/node (32 MiB timed out) |
| CPU-as-GPU fallback | 31.65 tasks/s, fallback latency 326.50 ms |
| Resource reallocation | 51.49 tasks/s, reallocation ratio 1.0 (high-memory node absorbed work) |
| Cluster scaling (1 -> 2 nodes) | 31.74 -> 63.40 tasks/s, speedup 1.9976, min efficiency 0.9988 |

### M1/M2 Scoring Matrix (2-node local)

| Workload | Scoring mode | Submit p50 (ms) | Submit p95 (ms) | Completion p50 (ms) |
|---|---|---:|---:|---:|
| base | accurate | 67.84 | 77.34 | 2422 |
| base | auto | 63.02 | 68.13 | 1811 |
| base | fast | 65.52 | 73.57 | 2059 |
| autosplit | accurate | 68.93 | 75.12 | 2782 |
| autosplit | auto | 64.47 | 64.56 | 2373 |
| autosplit | fast | 60.40 | 63.80 | 2307 |

### Real Submit ACK Matrix (2-node local, latest)

| Profile bucket | Submit p50 (ms) | Submit p95 (ms) | Completion p50 (ms) | Throughput avg (tasks/s) |
|---|---:|---:|---:|---:|
| accurate | 69.38 | 73.07 | 2504 | 8.00 |
| auto | 66.28 | 71.33 | 2081 | 9.61 |
| fast | 67.38 | 68.67 | 2726 | 2.99 |

### Heterogeneous 3-node Autosplit (macOS + Windows + Windows)

- Submit latency: p50 173.41 ms, p95 174.12 ms
- Completion latency: p50 264 ms
- Throughput: avg 51.50 tasks/s
- Active exec node ratio: avg 0.889
- Output fetch success ratio: 1.0

### Real llama.cpp RPC Benchmark (latest run)

- Runs: 1
- Submit ACK latency: 363.07 ms
- Request latency: 2500.00 ms
- Client request latency: 3306.18 ms
- TTFT: 2180.89 ms
- ITL: 13.74 ms
- Output tokens/s: 9.60
- Generation tokens/s: 86.5

## Data Sources Used For This README Update

- `status.md` (latest runtime/project status)
- `artifacts/benchmark_suite_fixed_v1/benchmark_results.json`
- `benchmarks/results/m1_m2_*/*/summary.json`
- `benchmarks/results/submit_local_base_*/*/summary.json`
- `benchmarks/results/heterogeneous_cluster_process_autosplit_3node/*/summary.json`
- `benchmarks/results/llama_rpc_real/*/summary.json`
