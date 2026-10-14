---
title: Azure SRE Agent Live Reports
description: Prompts and acceptance checks for reusable SRE dashboards over the demo telemetry
author: Azure SRE demo team
ms.date: 2026-10-14
ms.topic: how-to
estimated_reading_time: 8
---

## Report strategy

Create three Live Reports after connecting the demo Log Analytics workspace.
The prompts avoid model-assisted analysis on refresh so routine reloads retrieve
connector data without active-flow AAU charges.

## Reliability command center

```text
Build a Live Report called "Reliability Command Center" using the connected
Log Analytics or Application Insights telemetry for rg-sre-demo.

Cover the selected time range, defaulting to the last 24 hours. Include:
1. Status indicators for total requests, failed requests, failure rate, p95
   duration, and distinct controlled scenarios.
2. A time chart for request count, HTTP 4xx, HTTP 5xx, p50, p95, and p99 duration.
3. A bar chart grouped by scenario and severity from JSON traces where eventType
   equals sre-demo-scenario.
4. A sortable incident-evidence table with timestamp, scenario, status code,
   severity, duration, summary, expected root cause, and correlation ID.
5. Filters for time range, scenario, severity, and status code.

Use connector queries only during refresh. Do not use model-assisted summaries
or write actions. Save the report when all visualizations return data.
```

## Scenario coverage matrix

```text
Build a Live Report called "SRE Scenario Coverage" from the connected demo
telemetry. Show one row for each of these scenarios: http-500, latency,
dependency-failure, throttling, queue-backlog, poison-message, memory-pressure,
cpu-saturation, config-drift, and deployment-regression.

For each row show last observed time, run count, worst severity, latest status
code, maximum duration, latest summary, expected root cause, and a health status
of Not Run, Observed, Warning, or Critical. Add a coverage donut and a bar chart
of run count by scenario. Default to the last seven days.

Use connector queries only during refresh. Do not use model-assisted summaries
or write actions.
```

## Cost and evaluation guardrails

```text
Build a Live Report called "Evaluation Guardrails" for msdn-sre-agent and the
Azure SRE Agent demo. Show the configured AAU allocation, active-flow consumption
by thread type, daily AAU usage, the $100 Azure budget status when available,
the day-29 teardown timestamp, and whether rg-sre-agent, rg-sre-demo, and
rg-sre-guardrails exist.

Add warning status when active-flow usage reaches 400 AAUs, Azure cost reaches
$80, or fewer than three days remain before teardown. Use read-only tools.
Avoid model-assisted analysis during refresh.
```

## Acceptance checks

Each report must:

* Load without write-tool approval prompts
* Expose the requested time and scenario filters
* Show a clear no-data state before a scenario runs
* Update after **Reload** when new telemetry arrives
* Keep the saved layout stable across reloads
* Avoid model calls during routine refresh
