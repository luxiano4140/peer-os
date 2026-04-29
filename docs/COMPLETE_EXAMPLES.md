# Peer-OS How-To

This guide explains how to get started with Peer-OS at a practical level.

It is intended for users who want to run Peer-OS, submit workloads, check results, and understand the basic operating flow without needing to study internal implementation details.

## What Peer-OS Does

Peer-OS helps you:

- start one or more runtime nodes
- submit workloads
- run command-line jobs
- run distributed workloads
- run portable workloads
- check workload status
- retrieve workload output
- use similar workflows for home, development, business, and AI use cases

## Basic Operating Flow

The general flow is:

1. Start one or more Peer-OS nodes.
2. Submit a workload.
3. Check the workload status.
4. Retrieve the output.
5. Review execution behavior when needed.

Peer-OS coordinates execution across available infrastructure and places workloads based on resource availability, workload type, and runtime conditions.

## How Peer-OS Places Workloads

Peer-OS supports both local and distributed execution patterns.

In simple terms:

- smaller or locality-sensitive workloads can stay close to where they start
- workloads that benefit from parallel execution can use multiple machines
- placement can consider CPU, memory, storage, network, GPU availability, and current load
- execution behavior can adapt as infrastructure conditions change

Users do not need to manage every placement decision manually.

## Starting Peer-OS

Peer-OS can be started in different environments, including:

- a single local machine
- multiple machines on a local network
- development environments
- business environments
- AI experimentation environments
- benchmarking setups

A helper script or runtime command can be used to start nodes depending on the deployment model.

## Submitting Workloads

After a node is running, users submit workloads to the runtime.

Typical workload categories include:

- basic validation workloads
- command-line process workloads
- distributed or split workloads
- portable workloads
- AI or inference workloads
- repeated batch jobs

The same general submit, status, and output flow is used across these workload types.

## Checking Status

Users can check workload status while a job is running or after it completes.

Status information helps confirm:

- whether the workload was accepted
- whether it is still running
- whether it completed
- whether output is available
- whether follow-up action is needed

## Retrieving Output

Completed workloads can produce outputs that are retrieved through the runtime.

This allows users to submit work, monitor progress, and collect results without manually logging into every machine.

## Common First Tests

A typical first-use sequence is:

1. Start a local node.
2. Submit a simple validation workload.
3. Check its status.
4. Retrieve the output.
5. Add another node if distributed testing is needed.
6. Try a workload that can benefit from parallel execution.

## Main Feature Areas

### Local Workloads

Use Peer-OS locally when you want to:

- test the runtime
- run simple jobs
- keep data close
- validate workflows
- run lightweight automation

### Multi-Node Workloads

Use multiple nodes when you want to:

- improve throughput
- use idle machines
- run distributed experiments
- process larger batches
- coordinate workloads across machines

### Portable Workloads

Peer-OS can support portable workload patterns that are useful when jobs need to run consistently across different systems.

### AI and ML Workloads

Peer-OS can support AI and machine learning workloads such as:

- inference jobs
- batch inference
- embedding pipelines
- preprocessing
- model-support workflows
- mixed CPU/GPU execution

AI workloads may require additional model files, helper binaries, or framework-specific setup depending on the use case.

### Business Workloads

Business-oriented workloads can include:

- reporting
- ETL
- document processing
- media processing
- scheduled jobs
- repeated batch workloads
- internal automation

### Benchmarking

Benchmarking workflows can help validate:

- runtime startup
- workload submission
- scheduling behavior
- output retrieval
- repeated execution
- basic performance characteristics

## Adapting Examples

Most example workloads can be adapted by changing the workload definition rather than changing the runtime.

Common changes include:

- changing the command or program being run
- changing the input files
- changing the workload type
- changing parallelism settings
- changing environment variables
- changing model or data paths

After adapting an example, the same submit and status flow can usually be reused.

## Resource Adaptation

Peer-OS can coordinate several resource types:

- CPU
- GPU
- memory
- storage
- network

This helps the runtime place workloads where they are more likely to run efficiently.

For example:

- CPU-heavy jobs can use available compute capacity
- GPU-related jobs can target suitable machines
- data-heavy jobs can consider storage and network conditions
- distributed jobs can be spread across available nodes when appropriate

## Durability and Reliability

Some deployments may use stronger durability or recovery-oriented settings depending on the importance of the workload.

Use stronger reliability settings when:

- outputs are important
- jobs are business-critical
- node failure is expected
- repeatability matters
- recovery behavior needs testing

For critical business records or compliance-sensitive data, Peer-OS should complement durable systems of record rather than replace them.

## Placement Visibility

Peer-OS can expose information about workload placement and runtime decisions.

This is useful when you need to understand:

- why a workload ran on a certain node
- whether a node was overloaded
- whether resources were available
- how the runtime evaluated placement
- whether the workload should be adjusted

## Use Case Examples

Peer-OS can be used for:

- local development and testing
- home lab compute
- media processing
- backup or file-processing jobs
- business ETL and reporting
- document conversion
- distributed AI inference
- ML preprocessing
- WebAssembly-style portable workloads
- repeated batch jobs
- benchmark validation
- edge-to-cloud processing
- shared team compute environments

## Short Version

1. Start Peer-OS.
2. Submit a simple workload.
3. Check status.
4. Retrieve output.
5. Add more nodes when distributed execution is needed.
6. Adapt examples to your real workload.
7. Use monitoring and placement visibility to understand behavior.

## User Action Flow

```mermaid
flowchart TD
    Start[Start Peer-OS]
    Start --> Goal{Choose workload goal}

    Goal --> Local[Local workload]
    Goal --> Multi[Multi-node workload]
    Goal --> AI[AI or ML workload]
    Goal --> Batch[Batch or business workload]
    Goal --> Benchmark[Benchmark or validation]

    Local --> Submit[Submit workload]
    Multi --> Submit
    AI --> PrepareAI[Prepare model, data, or helper dependencies]
    PrepareAI --> Submit
    Batch --> Submit
    Benchmark --> Submit

    Submit --> Status[Check status]
    Status --> Output[Retrieve output]
    Output --> Review{Need to adjust?}

    Review -->|Yes| Adapt[Adapt workload example]
    Adapt --> Submit
    Review -->|No| Done[Done]
