# Peer-OS

## One Big Computer for Distributed AI & High-Performance Workloads

Peer-OS is both a distributed compute runtime and a "One Big Computer" fabric. It can operate in two modes:

1. Distributed Compute Mode — where tasks are executed across multiple coordinated nodes.
2. One Big Computer Mode — where aggregated machines behave as a single logical system.

Peer-OS transforms clusters of machines — at home, in the office, on-prem, or in the cloud — into a unified execution system.

It aggregates CPU, RAM, disk, and network resources across multiple nodes and coordinates them as one logical computer.

Run faster. Scale wider. Use hardware better.

---

# What Is Peer-OS?

Peer-OS is a distributed compute runtime designed to:

* Combine multiple machines into one coordinated system
* Execute distributed workloads efficiently
* Accelerate AI and data-intensive tasks
* Run on commodity hardware
* Operate across home labs, enterprise clusters, and cloud environments

Whether you're running AI models at home or scaling commercial infrastructure, Peer-OS adapts to your environment.

---

# Key Benefits

## 🎛 Resource Optimization Across CPU, GPU, Memory, Disk, Storage, and Network

Peer-OS is built to optimize the *entire* resource envelope of a distributed system — not just CPU scheduling.

* **CPU optimization:** shardable workflows, parallel execution, and adaptive placement to maximize core utilization.
* **GPU optimization:** AI-oriented execution patterns (TP/PP-ready) and placement strategies that reduce idle GPU time and avoid unnecessary data movement.
* **Memory optimization:** coordinated memory behavior for data-heavy workloads, with support for large-model workflows and reduced duplication across nodes.
* **Disk & storage optimization:** disk-backed persistence and efficient object handling so large datasets and artifacts remain reusable across jobs.
* **Network optimization:** bandwidth-aware scheduling and high-throughput transfer patterns (including multi-path / multi-NIC scenarios where available).

The result: higher throughput, lower cost, and better utilization of existing hardware — from home labs to enterprise clusters.

---

## 🖥 One Big Computer Model

Peer-OS turns multiple machines into a unified compute fabric:

* Logical single-system behavior
* Coordinated resource allocation
* Distributed task execution
* Shared data movement optimization

Add nodes → increase capacity.
No complex orchestration redesign required.

---

## ⚡ Faster Distributed Workloads

Designed for performance-sensitive workloads:

* Parallel task execution
* AI-optimized scheduling
* Bandwidth-aware placement
* Reduced redundant data transfer
* Efficient multi-node coordination

Ideal for heavy workloads that exceed a single machine.

---

## 🧠 AI-Native Distributed Execution

Peer-OS is designed for modern AI workloads across inference, training, and large-scale model coordination.

### AI Workloads Supported

Peer-OS is framework-agnostic and can coordinate workloads built with virtually any AI or ML stack.

#### Supported AI Frameworks & Runtimes

* llama.cpp
* PyTorch
* TensorFlow
* ONNX Runtime
* JAX
* Hugging Face Transformers
* TensorRT-based runtimes
* OpenVINO
* MLX (Apple Silicon)
* Custom CUDA / ROCm workloads
* Custom C++ or Rust inference engines
* WASM-based AI operators

#### AI Workloads Supported

* Large Language Model (LLM) inference
* Tensor Parallel (TP) execution
* Pipeline Parallel (PP) execution
* Hybrid TP + PP configurations
* Multi-node model serving
* Batch and real-time inference
* Distributed ML training coordination
* GPU-accelerated data preprocessing
* Embedding generation pipelines
* Retrieval-Augmented Generation (RAG) backends
* Vector indexing and search workflows
* Fine-tuning and model refresh jobs
* AI batch scoring pipelines
* Multi-model ensemble inference
* AI-driven ETL and feature engineering
* Edge-to-cloud AI aggregation

### Parallelism & Scaling Models

Peer-OS supports AI execution patterns including:

* Tensor sharding across multiple nodes
* Pipeline stage distribution
* Workload autosplitting for large jobs
* Data-parallel batch distribution
* Coordinated GPU scheduling
* Mixed CPU/GPU workload coordination

This allows Peer-OS to function both as:

* A distributed AI runtime for inference and ML workloads
* A "One Big Computer" abstraction that aggregates GPU, CPU, memory, and bandwidth into a unified AI fabric

Peer-OS enables scalable AI on commodity hardware, on-prem clusters, cloud infrastructure, or hybrid environments — without requiring proprietary orchestration systems.

---

### Run Big AI Models on Small Machines — Or Across Many Machines

Peer-OS allows large AI models to run in two powerful modes:

#### 1️⃣ Large Models on Small Machines

* Split model workloads across CPU and GPU resources
* Distribute memory pressure across nodes
* Use tensor and pipeline partitioning to fit larger models than a single machine could normally support
* Enable inference on commodity or older hardware by coordinating resources across peers

This makes it possible to run advanced AI workloads even in constrained environments such as home labs, small servers, or limited GPU setups.

#### 2️⃣ Large Models Across Multiple Machines

* Aggregate GPU, CPU, RAM, disk, and bandwidth across nodes
* Coordinate tensor-parallel (TP) execution across GPUs
* Distribute pipeline-parallel (PP) stages across machines
* Scale inference throughput horizontally
* Support distributed training and large-batch processing

Peer-OS transforms multiple machines into a unified AI execution fabric, allowing organizations to scale from a single device to a multi-node cluster seamlessly.

---

## 💰 Better Hardware Utilization

Peer-OS maximizes resource efficiency:

* Aggregates idle CPU and RAM
* Coordinates disk and network resources
* Reduces overprovisioning
* Improves overall cluster throughput

Get more value from the hardware you already own.

---

## 🏠 Works on Commodity & Older Hardware — From Home Labs to Enterprise

Peer-OS is designed to run efficiently on:

* Commodity x86 and ARM machines
* Older generation servers
* Mixed hardware clusters
* Developer workstations
* Home lab environments
* On-prem enterprise infrastructure
* Cloud virtual machines
* Hybrid and edge deployments

It does not require specialized hardware or proprietary systems.

This makes Peer-OS ideal for:

* Individual developers and home labs
* Small startups optimizing limited infrastructure
* Research groups repurposing existing servers
* Mid-sized companies scaling gradually
* Large enterprises operating multi-node clusters

Start small with a few machines.
Scale to large commercial deployments without redesigning your architecture.

---

## ☁ Cloud + On-Prem + Hybrid

Infrastructure-agnostic by design:

* On-prem deployment
* Public cloud
* Multi-region clusters
* Hybrid infrastructure
* Mixed hardware environments

No vendor lock-in.

---

## 🗂 Distributed Object & Memory Layer

Peer-OS includes:

* Distributed object coordination
* Disk-backed persistence
* Efficient inter-node data handling
* Coordinated memory abstraction

Optimized for data-heavy workflows and AI pipelines.

---

## 🔄 Deterministic & Adaptive Scheduling

* Workflow-aware execution
* Predictable task placement
* Adaptive load balancing
* Resource-coordinated compute decisions

Designed for both reliability and performance.

---

# Use Cases

Peer-OS supports a wide range of distributed and "One Big Computer" scenarios, including:

* Daily ETL + scoring pipelines
* Distributed LLM inference (tensor-parallel / pipeline-ready)
* Multi-node AI training coordination
* Persistent shared dataset clusters
* High-throughput bulk data transfer across nodes
* Disk-backed large object processing
* Research compute clusters
* Home lab distributed experimentation
* Hybrid on-prem + cloud compute aggregation
* Multi-NIC bandwidth-aware workloads
* Observability-focused cluster environments
* Distributed memory (DSM-style) experiments
* Bootstrap clusters without centralized control

From hobbyist experimentation to large-scale commercial AI infrastructure.

---

## Complete Example Catalog (58 Scenarios)

Peer-OS includes a comprehensive example set covering distributed compute, One Big Computer aggregation, B2C scenarios, B2B workflows, and AI/video workloads.

### Core Distributed & Fabric Examples

* Daily ETL + scoring pipelines
* Ad-hoc LLM research prompts
* Persistent shared datasets
* High-throughput multi-NIC transfers
* Secure tensor/pipeline workflows
* Minimal single-host workflow execution
* Bootstrap-only clusters (no mDNS)
* Host supervisor mode with resource envelopes
* Disk-backed large object processing
* Multipath transport & relay scenarios
* Observability & cluster state validation
* Distributed shared memory workflows
* Tensor-parallel LLM execution
* Coordinator resilience & recovery
* Automation & regression gating
* Consumer AI assistant execution
* Personal notebook syncing
* Community dataset sharing
* Personalized streaming media pipelines

### Practical Real-World Examples

* Run tasks on remote machines
* Share large files peer-to-peer
* Daily report generation
* Training on spare GPUs
* Photo backup across peers
* Music library synchronization
* Home video encoding cluster
* Distributed web scraping
* Code compilation farm
* Gaming server compute sharing
* Phone-based sensor networks
* Raspberry Pi automation clusters
* Educational distributed compute experiments
* Live collaboration compute layer
* AI art generation events

### B2B Commercial Scenarios

* Cross-department data sharing without central IT
* Secure B2B data exchange
* Trade finance document exchange
* Research data marketplaces
* Multi-site clinical data aggregation
* Secure genomic collaboration
* Supplier collaboration networks
* Distributed loyalty systems
* Supply chain provenance tracking
* Predictive maintenance consortium
* Multi-carrier tracking networks
* Cold chain compliance monitoring

### AI & Media Workloads

* Distributed VFX render farms
* AI-powered rotoscoping
* Live sports AI enhancement
* Real-time video translation
* 24/7 industrial video analytics
* Construction progress AI monitoring
* AI upscaling for game streaming
* Virtual production compositing
* Surgical video AI analysis
* Remote patient monitoring with AI
* AI video generation for marketing
* Content moderation at scale

These examples demonstrate Peer-OS operating both as:

* A distributed compute runtime for parallel workloads
* A unified "One Big Computer" fabric that aggregates hardware resources across peers

Total documented examples: 58.

---

# Sector-Specific Use Cases

Peer-OS extends beyond general distributed workloads and supports industry-specific deployments leveraging its distributed runtime, QUIC/WebRTC transport, object-store replication, workflow-aware scheduling, AI shard orchestration, compression-aware data handling, and "One Big Computer" abstraction.

## 1. Healthcare (Hospitals & Medical Networks)

**Use Cases**

* Distributed medical imaging processing (MRI, CT)
* AI-assisted diagnostics across hospital nodes
* Secure image replication between facilities
* Real-time telemedicine streaming
* Federated learning across hospitals

**Peer-OS Value**

* Large dataset compression and replication efficiency
* On-prem AI inference mesh
* Encrypted QUIC-based transport
* Edge inference near imaging devices

---

## 2. Government / Public Sector

**Use Cases**

* Secure document distribution mesh
* Classified on-prem AI clusters
* National edge CDN-style deployments
* Disaster recovery replication networks
* Digital identity backend coordination

**Peer-OS Value**

* Air-gapped deployment capability
* Distributed storage without centralized cloud reliance
* Controlled workload placement
* Secure cross-site coordination

---

## 3. Energy & Utilities

**Use Cases**

* Smart grid data aggregation
* Real-time sensor stream ingestion
* Distributed analytics for substations
* Edge compute near power plants
* IoT anomaly detection

**Peer-OS Value**

* Low-latency transport support
* Edge scheduling
* Compressed telemetry replication
* Cross-site workload balancing

---

## 4. Manufacturing / Industry 4.0

**Use Cases**

* Machine vision AI inference at edge
* Factory-wide compute mesh
* Predictive maintenance analytics
* Robotics control coordination
* Digital twin simulation clusters

**Peer-OS Value**

* Local-first distributed compute
* Hybrid GPU/CPU orchestration
* Workflow-aware scheduling
* High-speed inter-node transport

---

## 5. E-commerce & Retail

**Use Cases**

* Real-time recommendation inference
* Distributed caching of product assets
* Event-driven flash sale scaling
* Inventory synchronization mesh
* Edge personalization engines

**Peer-OS Value**

* Media asset deduplication
* AI inference scaling without hyperscaler lock-in
* Latency-aware node allocation
* Distributed state coordination

---

## 6. Media Production & Post-Production

**Use Cases**

* Distributed video rendering
* Multi-node transcoding
* Asset deduplication across studios
* Collaborative editing backend
* Hybrid edge preview distribution

**Peer-OS Value**

* Compression-aware media handling
* GPU scheduling
* Snapshot restore for render pipelines
* High-throughput node mesh

---

## 7. Education & Universities

**Use Cases**

* Distributed research clusters
* Shared AI lab infrastructure
* Secure dataset replication
* Lecture streaming mesh
* Federated model training

**Peer-OS Value**

* Budget-friendly distributed compute
* On-campus distributed delivery
* AI model shard placement
* Shared resource pooling

---

## 8. Gaming & Interactive Platforms

**Use Cases**

* Edge game state synchronization
* Low-latency relay networking
* Distributed match servers
* Real-time asset streaming
* Anti-cheat AI inference nodes

**Peer-OS Value**

* Low-latency transport support
* Distributed object caching
* Edge compute near players
* Adaptive workload rebalancing

---

## 9. Logistics & Transportation

**Use Cases**

* Fleet telemetry ingestion
* Edge inference in vehicles
* Distributed route optimization
* Cross-warehouse synchronization
* Real-time port and airport video analytics

**Peer-OS Value**

* Edge node fabric
* Compressed telemetry streams
* Distributed AI scheduling
* Hybrid cloud + on-prem mesh

---

## 10. Cybersecurity

**Use Cases**

* Distributed threat detection engines
* Log ingestion mesh
* AI-based anomaly detection
* Secure distributed storage
* Rapid snapshot restore for forensics

**Peer-OS Value**

* Compression-aware log storage
* Workflow-based scanning pipelines
* Cross-node correlation
* Peer-to-peer replication resilience

---

## 11. Space / Satellite Networks

**Use Cases**

* Edge compute in ground stations
* Distributed satellite data ingestion
* Delayed-sync mesh coordination
* Remote site replication
* AI inference on orbital imagery

**Peer-OS Value**

* Store-and-forward synchronization
* Compression for high-latency links
* Autonomous workload placement
* Intermittent connectivity tolerance

---

## 12. Blockchain & Web3 Infrastructure

**Use Cases**

* Distributed validator coordination
* Edge RPC gateways
* Off-chain compute mesh
* Snapshot replication
* Distributed indexers

**Peer-OS Value**

* Peer-to-peer-first runtime
* Efficient snapshot handling
* Resource pooling
* Distributed state coordination

---

# Strategic Positioning

Peer-OS can be positioned as:

* A Private Programmable CDN
* A Distributed AI Fabric
* An Edge Compute Mesh
* An Adaptive Datacenter Orchestrator
* A Compression-Aware Distributed Runtime
* A Sovereign Infrastructure Alternative to Hyperscalers

---

# Why Peer-OS?

Modern workloads demand distributed compute.

Peer-OS provides:

* Performance-first distributed execution
* AI-optimized coordination
* Commodity hardware support
* Scalable architecture
* Unified compute abstraction

It treats infrastructure as one system — not a collection of isolated machines.

---

# Integrations & Ecosystem

Peer-OS is designed to work alongside existing infrastructure and tools — not replace everything you already use.

## Works With

* Kubernetes (as underlying node layer or workload environment)
* Docker & containerized workloads
* Cloud providers (AWS, Azure, GCP)
* On-prem virtualization platforms
* Slurm clusters
* CI/CD pipelines
* Standard Linux environments

## AI & Data Stack Compatibility

Peer-OS can coordinate workloads built with:

* PyTorch
* TensorFlow
* ONNX-based runtimes
* LLM serving stacks
* Custom AI inference engines
* Data processing pipelines

## Complementary to Existing Systems

Peer-OS can coexist with:

* Ray
* Spark
* Distributed training frameworks
* HPC schedulers

It focuses on compute fabric coordination and resource aggregation, enabling more efficient execution beneath or alongside higher-level frameworks.

Peer-OS is infrastructure-layer software — it enhances how compute resources are coordinated rather than competing at the application framework level.

---

# Roadmap

* Enhanced AI parallel runtime
* Expanded observability
* Advanced resource pooling
* Enterprise deployment tooling
* Extended hybrid support

---

Peer-OS

Distributed Compute. One Big Computer. AI-Optimized. Commodity Hardware Ready.

For contacts, enquiries, PoC, MvP, Demos, and app access mail to : peer-os@projectjob.net


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

## Benchmarks (Reliable, Deduplicated)

- Source: measured markdown reports only (`artifacts/*/benchmark_report.md` + `mesh_runtime/benchmark.md`).
- Excluded: failed rows, duplicated files, and external baseline comparison docs.
- Deduping applied on `(report_folder, benchmark)` and on benchmark IDs for latest-only table.

### Latest Per Benchmark ID

| Benchmark | Throughput (tasks/sec) | Completion (ms) | Efficiency | Source report | Generated (UTC) |
|---|---:|---:|---:|---|---|
| cluster_scaling | 47.573 | 0.00 | 0.999 | benchmark_suite_fixed_v1 | 2026-03-05 01:11:24Z |
| cpu_gpu_fallback | 31.648 | 252.78 | 0.000 | benchmark_suite_fixed_v1 | 2026-03-05 01:11:24Z |
| cpu_resource_aggregation | 62.884 | 508.88 | 1.057 | alloc_compare_20260305_034740_aggregate_s8 | 2026-03-05 02:48:39Z |
| distributed_memory_aggregation | 0.263 | 53140.76 | 0.000 | alloc_compare_20260305_034740_aggregate_s8 | 2026-03-05 02:48:39Z |
| distributed_task_aggregation | 63.658 | 251.34 | 0.000 | alloc_compare_20260305_034740_aggregate_s8 | 2026-03-05 02:48:39Z |
| resource_reallocation | 51.490 | 252.48 | 0.000 | benchmark_suite_fixed_v1 | 2026-03-05 01:11:24Z |

### Full Reliable Run Rows (Deduplicated)

| Report | Benchmark | Throughput (tasks/sec) | Completion (ms) | Efficiency | Generated (UTC) |
|---|---|---:|---:|---:|---|
| benchmark_suite_demo_adapt | resource_reallocation | 19.816 | 252.32 | 0.000 | 2026-03-04 18:57:06Z |
| benchmark_suite_formal | distributed_task_aggregation | 47.615 | 252.02 | 0.000 | 2026-03-04 19:04:11Z |
| benchmark_suite_formal_v2 | distributed_task_aggregation | 31.578 | 253.34 | 0.000 | 2026-03-04 19:10:28Z |
| benchmark_suite_formal_v3 | distributed_memory_aggregation | 0.134 | 74385.21 | 0.000 | 2026-03-04 19:15:17Z |
| benchmark_suite_formal_v3 | distributed_task_aggregation | 10.883 | 1010.74 | 0.000 | 2026-03-04 19:15:17Z |
| benchmark_suite_formal_v3_adapt | resource_reallocation | 55.450 | 252.48 | 0.000 | 2026-03-04 19:18:25Z |
| benchmark_suite_formal_v3_full | distributed_memory_aggregation | 0.143 | 83814.79 | 0.000 | 2026-03-04 19:22:03Z |
| benchmark_suite_formal_v3_full | distributed_task_aggregation | 59.400 | 252.53 | 0.000 | 2026-03-04 19:22:03Z |
| benchmark_suite_formal_v3_full | resource_reallocation | 63.547 | 251.78 | 0.000 | 2026-03-04 19:22:03Z |
| benchmark_suite_formal_v4_full | cluster_scaling | 31.578 | 0.00 | 0.500 | 2026-03-04 19:27:58Z |
| benchmark_suite_formal_v4_full | cpu_gpu_fallback | 31.653 | 252.74 | 0.000 | 2026-03-04 19:27:58Z |
| benchmark_suite_formal_v4_full | cpu_resource_aggregation | 60.526 | 512.17 | 0.966 | 2026-03-04 19:27:58Z |
| benchmark_suite_formal_v4_full | distributed_task_aggregation | 63.085 | 253.63 | 0.000 | 2026-03-04 19:27:58Z |
| benchmark_suite_formal_v4_full | resource_reallocation | 63.069 | 253.69 | 0.000 | 2026-03-04 19:27:58Z |
| benchmark_suite_fixed_v1 | cluster_scaling | 47.573 | 0.00 | 0.999 | 2026-03-05 01:11:24Z |
| benchmark_suite_fixed_v1 | cpu_gpu_fallback | 31.648 | 252.78 | 0.000 | 2026-03-05 01:11:24Z |
| benchmark_suite_fixed_v1 | cpu_resource_aggregation | 63.376 | 504.92 | 1.000 | 2026-03-05 01:11:24Z |
| benchmark_suite_fixed_v1 | distributed_memory_aggregation | 0.127 | 94399.82 | 0.000 | 2026-03-05 01:11:24Z |
| benchmark_suite_fixed_v1 | distributed_task_aggregation | 11.884 | 1262.23 | 0.000 | 2026-03-05 01:11:24Z |
| benchmark_suite_fixed_v1 | resource_reallocation | 51.490 | 252.48 | 0.000 | 2026-03-05 01:11:24Z |
| alloc_compare_20260305_033901_latency | cpu_resource_aggregation | 59.420 | 1009.76 | 0.557 | 2026-03-05 02:42:14Z |
| alloc_compare_20260305_033901_latency | distributed_task_aggregation | 30.766 | 1007.60 | 0.000 | 2026-03-05 02:42:14Z |
| alloc_compare_20260305_034217_aggregate | cpu_resource_aggregation | 63.095 | 1014.34 | 0.537 | 2026-03-05 02:45:23Z |
| alloc_compare_20260305_034217_aggregate | distributed_task_aggregation | 126.607 | 252.75 | 0.000 | 2026-03-05 02:45:23Z |
| alloc_compare_20260305_034548_latency_s8 | cpu_resource_aggregation | 61.167 | 506.81 | 1.031 | 2026-03-05 02:47:38Z |
| alloc_compare_20260305_034548_latency_s8 | distributed_memory_aggregation | 0.114 | 104970.19 | 0.000 | 2026-03-05 02:47:38Z |
| alloc_compare_20260305_034548_latency_s8 | distributed_task_aggregation | 63.126 | 253.46 | 0.000 | 2026-03-05 02:47:38Z |
| alloc_compare_20260305_034740_aggregate_s8 | cpu_resource_aggregation | 62.884 | 508.88 | 1.057 | 2026-03-05 02:48:39Z |
| alloc_compare_20260305_034740_aggregate_s8 | distributed_memory_aggregation | 0.263 | 53140.76 | 0.000 | 2026-03-05 02:48:39Z |
| alloc_compare_20260305_034740_aggregate_s8 | distributed_task_aggregation | 63.658 | 251.34 | 0.000 | 2026-03-05 02:48:39Z |

### mesh_runtime Mode Benchmarks (Measured)

| Mode | Runs | Workflows | Avg Latency (ms) | P50 (ms) | P95 (ms) | Throughput (tasks/s) | Split Balance |
|---|---:|---:|---:|---:|---:|---:|---:|
| autosplit | 2 | 4 | 358.0 | 348 | 371 | 55.87 | 0.386 |
| abi | 1 | 2 | 350.0 | 259 | 441 | 57.14 | 0.350 |
| base | 1 | 2 | 8.0 | 7 | 9 | 2500.00 | 0.400 |

### SSI Demo Latency Optimizations (Measured)

| Phase | Metric | Before | After | Delta |
|---|---|---:|---:|---|
| phase1_batched | Read avg latency per page (ms) | 0.449 | 0.436 | 2.9% lower |
| phase1_batched | Read avg latency per page (ms) | 0.609 | 0.449 | 26.3% lower |
| phase1_batched | Read avg latency per page (ms) | 6.589 | 0.609 | 10.82x lower |
| phase1_batched | Read request count | 128 | 4 | 32x fewer |
| phase1_batched | Write avg latency per page (ms) | 0.735 | 0.592 | 19.5% lower |
| phase1_batched | Write avg latency per page (ms) | 6.654 | 0.735 | 9.05x lower |
| phase1_batched | Write avg latency per page (ms) | 0.592 | 0.600 | -1.4% (slightly worse) |
| phase1_batched | Write request count | 64 | 2 | 32x fewer |

<!-- BENCHMARK_SECTION_END -->
