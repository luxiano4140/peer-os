# Peer-OS  How-To

This guide is for someone who just wants to make Peer-OS work, step by step, without dealing with deep setup details.

Below, `mesh_runtime` means the compiled runtime binary you already have.

## What Peer-OS does

Peer-OS lets you:

- start one or more nodes
- send work to a node
- run normal command-line jobs
- split bigger jobs across nodes
- run WASM jobs
- check job status
- read job output
- use the same flow for home use or business use

The only tool you touch is the already-compiled `mesh_runtime` binary. There is no need to rebuild or edit source files before trying these steps.

## How Peer-OS decides where work runs

You do not need to switch modes by hand.

The normal flow is:

1. Start the nodes.
2. Submit a workflow.
3. Peer-OS chooses how to use the available machines.

In simple terms:

- if the job is small or better kept together, it keeps more of the work local
- if the job can be split, it can spread the work across multiple nodes
- it looks at available CPU, memory, disk, network, and current load

As soon as two nodes see each other, the Smart Dynamic Coordinator (v3) notices any imbalance and keeps the whole cluster acting like "one big computer" when that makes sense, or the "distributed compute engine" when the job is better lived across machines. The switch happens automatically during scheduling—no extra commands, no second runtime, and no duplication of features. The runtime keeps a single scheduler that knows both domains.

The coordinator watches CPU, RAM, disk, and NIC pressure and adapts the scoring used when a workflow arrives. It keeps work moving toward where the resources are free, re-assesses when a job grows, and shifts it between the two operational views without asking you to do anything.

Start a node manually by running the binary. Once it is running, peer discovery, balancing, and domain switching happen on their own.

## Step 1: Start the first node

Open terminal 1 and run:

```bash
LISTEN="/ip4/127.0.0.1/tcp/7001" mesh_runtime serve
```

Leave that terminal open.

When it starts, you will see a line like this:

```text
local_peer_id=...
```

Keep that value. You will need it when you submit work.

## Step 2: Start the second node

Open terminal 2 and run:

```bash
LISTEN="/ip4/127.0.0.1/tcp/7002" mesh_runtime serve
```

Leave this terminal open too.

Peer-OS starts nodes manually, but peer discovery and work balancing happen automatically after the nodes are running.

If you need another machine to join, run `mesh_runtime serve` there too. The built-in discovery is automatic, and no one has to assign a special role or port beyond the `LISTEN` address you choose at startup.

## Smart wizard script

Run `bash scripts/peer_os_wizard.sh` to see a goal-first wizard plus flags that match your needs (home quick start, commercial checklist, AI intent, benchmark mode, hybrid business mode). The wizard keeps you on the compiled `mesh_runtime` binary, prints the commands you need, exposes logs/status/stop info, and launches nodes in the background while the Smart Dynamic Coordinator handles adaptive behavior.
The script also starts `mesh_runtime serve` for you, logs to `/tmp/peer_os_wizard_logs/<role>-<port>.log`, and prints each PID. You can stop a node later with `kill <pid>` and read its `local_peer_id` in the log to build submit addresses.

## Step 3: Build the address of the node you want to use

If you want to send work to node 2, use this format:

```text
/ip4/127.0.0.1/tcp/7002/p2p/<peer_id_of_node_2>
```

This is the only value you need to replace by hand.

## Step 4: Run the first example

Use the basic smoke example first:

```bash
mesh_runtime submit-workflow \
  /ip4/127.0.0.1/tcp/7002/p2p/<peer_id_of_node_2> \
  scripts/workflow_smoke.json
```

If it worked, you will see:

- `ok ...` in the submit command
- `workflow done` in one of the node terminals

## Step 5: Check the result

Use the workflow id printed by the submit command:

```bash
mesh_runtime workflow-status \
  /ip4/127.0.0.1/tcp/7002/p2p/<peer_id_of_node_2> \
  <workflow_id>
```

Read one output:

```bash
mesh_runtime get-output \
  /ip4/127.0.0.1/tcp/7002/p2p/<peer_id_of_node_2> \
  out:smoke:0
```

## Step 6: Try the main features

Once the smoke example works, use the same command with a different workflow file.

You do not need to manually tell Peer-OS "stay local" or "go distributed".
The runtime chooses that while scheduling the job.

### 1. Basic check

```bash
mesh_runtime submit-workflow <addr> scripts/workflow_smoke.json
```

Use this when you want to confirm the runtime is alive.

### 2. Run a simple command-line job

```bash
mesh_runtime submit-workflow <addr> scripts/workflow_process_demo.json
```

Use this when you want to run a normal process-based task.

### 3. Split one larger job across nodes

```bash
mesh_runtime submit-workflow <addr> scripts/workflow_process_autosplit.json
```

Use this when the same job can be split into many pieces.

### 4. Run a WASM job

```bash
mesh_runtime submit-workflow <addr> scripts/workflow_wasm_demo.json
```

Use this when your task is packaged as WASM.

### 5. Split a WASM job across nodes

```bash
mesh_runtime submit-workflow <addr> scripts/workflow_wasm_autosplit.json
```

Use this when you want distributed WASM execution.

### 6. Submit many jobs in a row

```bash
mesh_runtime submit-workflow-batch <addr> scripts/workflow_smoke.json 10 250
```

Use this when you want to push repeated jobs without typing the command many times.

### 7. Check status at any time

```bash
mesh_runtime workflow-status <addr> <workflow_id>
```

### 8. Read output at any time

```bash
mesh_runtime get-output <addr> <output_key>
```

### 9. Advanced AI / LLM example

Peer-OS also includes LLM workflow examples under:

- `scripts/workflow_llama_local_autosplit.json`
- `scripts/workflow_llama_local_autosplit_2.json`
- `scripts/workflow_llama_chat_big2.json`

Use them only if the helper runner `scripts/llama_shard_runner.sh` is already packaged on your nodes.

## Step 7: Use the right example for your real use case

### If the user is a home user

Start with one of these:

- backup or file sync: `scripts/workflow_process_autosplit.json`
- media conversion: `scripts/workflow_process_autosplit.json`
- simple personal task runner: `scripts/workflow_process_demo.json`
- portable WASM task: `scripts/workflow_wasm_demo.json`

### If the user is a business or commercial client

Start with one of these:

- reporting or ETL: `scripts/workflow_process_autosplit.json`
- document conversion: `scripts/workflow_process_demo.json`
- media batch processing: `scripts/workflow_process_autosplit.json`
- repeated job submission: `mesh_runtime submit-workflow-batch <addr> scripts/workflow_smoke.json 10 250`

## Use case ideas

Here are a few concrete scenarios the wizard/graph covers:

- **Local dev/test**: single node, `workflow_process_demo.json`, keep logs in `~/peer-os/logs`.
- **Home media/backup**: start 2-3 nodes with `workflow_process_autosplit.json`, watch auto-shard migrate work.
- **AI/LLM inference**: run `workflow_llama_local_autosplit.json` with two nodes, rely on DSM and auto-shard for data-heavy models.
- **Business ETL/reporting**: multi-node cluster, `serve_with_profile.sh balanced`, `workflow_process_autosplit.json`, use `workflow-status`/`get-output`.
- **Benchmark validation**: use `--benchmark` plus `workflow_smoke.json` to verify throughput and scheduler behavior.
- **Distributed compute engine evaluation**: add nodes via wizard, submit `workflow_wasm_autosplit.json`, watch Smart Coordinator adapt between locality and distributed placements.

## Step 8: Adapt an example

You usually only need to change one thing:

- for process examples:
  - change the `program`
- for WASM examples:
  - change the `wasm_path`
- for autosplit examples:
  - change `preferred_parallelism`

Then run the same submit command again:

```bash
mesh_runtime submit-workflow <addr> <your_workflow.json>
```

## The short version

1. Start node 1.
2. Start node 2.
3. Copy the peer id of the node you want to use.
4. Submit `scripts/workflow_smoke.json`.
5. Check status.
6. Read output.
7. Switch to the example that matches the real use case.

## User action flow

The following flowchart maps every user-facing case, resource question, and feature decision that the wizard keeps track of. It stays rooted in the compiled `mesh_runtime` binary, the available workflow samples, and the Smart Dynamic Coordinator so each move toward another setup step is clear.

```mermaid
flowchart TD
    Start[Run `bash scripts/peer_os_wizard.sh`]
    Start --> Goal{Define your goal}
    Goal --> Single1[Run one node]
    Goal --> Multi[Run multiple nodes]
    Goal --> AI[Run AI/LLM workflow]

    Single1 --> ResourcesA{Which resources matter?}
    ResourcesA --> CPUA[CPU-only task]
    ResourcesA --> MemA[Memory-heavy]
    CPUA --> OneBig[Use "one big computer" (local scheduler keeps work close)]
    MemA --> OneBig

    Multi --> ResourcesB{What should be aggregated?}
    ResourcesB --> CPUB[CPU cores]
    ResourcesB --> GPUB[GPU or accelerator]
    ResourcesB --> NetB[NIC/bandwidth]
    ResourcesB --> MemB[Memory+DSM]
    (CPUB & GPUB & NetB & MemB) --> Aggregator[Smart Dynamic Coordinator aggregates & adapts]

    Aggregator --> Transports[Transport support (TCP / QUIC / WebRTC)]
    Aggregator --> Replication[Durability + replication ACK policies]
    Aggregator --> Monitoring[Observability: `/metrics`, `/healthz`, `/readyz`]

    Aggregator --> AutoShard[Auto-shard walks large tasks across nodes]
    AutoShard --> Distributed[Distributed compute engine mode]
    Aggregator --> DSM[DSM leasing shares pages]

    AI --> AIWorkflow[Select LLM workflow sample]
    AIWorkflow --> AutoShard

    Transports --> Submit
    Replication --> Submit
    Monitoring --> Submit

    OneBig --> Submit[Use `mesh_runtime submit-workflow` with workflow_sample]
    Distributed --> Submit
    DSM --> Submit

    Submit --> Monitor[Use `workflow-status` + `get-output`]
    Monitor --> Repeat[Adapt example or return to menu]
```

## Related files

- [../README.md](../README.md)
- [../status.md](../status.md)
- [COMPLETE_EXAMPLES_IMPLEMENTATION.md](COMPLETE_EXAMPLES_IMPLEMENTATION.md)
