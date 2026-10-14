---
title: Azure SRE Agent Demonstration Scenarios
description: Ten controlled reliability scenarios for evaluating investigations, telemetry, alerts, and reports
author: Azure SRE demo team
ms.date: 2026-10-14
ms.topic: tutorial
estimated_reading_time: 12
---

## Safety and cost model

All scenarios run in one Azure Functions Consumption app. They are deterministic,
bounded, and intended only for the evaluation resource group. Do not point load
tests or production alert routes at this environment.

The shared stack includes:

* One Linux Consumption Function App
* One Standard LRS storage account and queue
* One workspace-based Application Insights resource
* One Log Analytics workspace capped at 0.1 GB/day
* One scheduled-query alert and email action group
* One Azure Monitor workbook
* One $100 monthly Azure budget
* One day-29 teardown Logic App

## Scenario catalog

| #  | Scenario                | Signal                           | Expected diagnosis                         | SRE capability                              |
|----|-------------------------|----------------------------------|--------------------------------------------|---------------------------------------------|
| 1  | HTTP 500 spike          | Failed requests and error traces | Simulated checkout exception               | Error correlation and root-cause summary    |
| 2  | Latency regression      | Three-second request duration    | Synchronous blocking operation             | Percentile analysis and slow endpoint review|
| 3  | Dependency failure      | HTTP 503 and critical trace      | Downstream payment connection refusal      | Dependency-oriented investigation           |
| 4  | API throttling          | HTTP 429 responses               | Simulated request quota                    | Saturation and policy diagnosis              |
| 5  | Queue backlog           | 25 queued messages               | Queue processor stopped                    | Backlog and throughput reasoning             |
| 6  | Poison message          | Malformed queue payload          | Producer schema violation                  | Data-quality and retry analysis              |
| 7  | Memory pressure         | Temporary 24 MiB allocation      | Oversized in-memory payload                | Resource and code-path analysis              |
| 8  | CPU saturation          | Two-second CPU-bound operation   | Inefficient hashing loop                   | CPU and latency correlation                  |
| 9  | Configuration drift     | HTTP 503 and setting mismatch    | Unapproved `SRE_DEMO_MODE` value           | Resource configuration inspection            |
| 10 | Deployment regression   | HTTP 500 and release mismatch    | Bad release differs from approved baseline | Change correlation and rollback recommendation|

## Run the scenarios

Invoke all scenarios once:

```powershell
./scripts/Invoke-Scenario.ps1 -Scenario All
```

Invoke a single scenario:

```powershell
./scripts/Invoke-Scenario.ps1 -Scenario latency
```

Allow up to five minutes for traces, requests, the alert rule, and Live Reports
connector caches to update.

## Investigation prompts

Use these prompts after connecting the demo resource group and Log Analytics
workspace to the SRE Agent.

### HTTP failures

```text
Investigate failed requests in rg-sre-demo during the last hour. Correlate
request status, exception or trace evidence, configuration, and recent changes.
Identify the most likely root cause and propose a low-risk mitigation.
```

### Performance

```text
Find the slowest operations in the Azure SRE demo during the last hour. Compare
p50, p95, and p99 duration, correlate slow requests with CPU and memory scenarios,
and explain which code path should be optimized first.
```

### Queue reliability

```text
Investigate the sre-demo-events queue. Determine whether it has a backlog or
malformed messages, explain the operational impact, and propose safe replay,
quarantine, and producer-validation steps.
```

### Configuration and deployment

```text
Compare the current Function App configuration and release markers with the
expected healthy baseline. Determine whether configuration drift or a deployment
regression explains the failures and provide a rollback plan.
```
