---
title: Azure SRE Agent Live Reports
description: Prompts and acceptance checks for reusable SRE dashboards over the demo telemetry
author: Azure SRE demo team
ms.date: 2026-10-14
ms.topic: how-to
estimated_reading_time: 10
---

## Report strategy

Use the saved synthetic showcase below to demonstrate layouts and investigation
workflows without generating incidents or querying workload telemetry.
Use the connector-backed prompts later in this guide when you need actual
measurements. A native Live Report can contain synthetic fixtures; its location
in the report gallery does not make those values live telemetry.

Create three Live Reports after connecting the demo Log Analytics workspace.
The prompts avoid model-assisted analysis on refresh so routine reloads retrieve
connector data without active-flow AAU charges.

## Saved synthetic showcase

Ten native reports were saved on October 14, 2026. Open the
[Live Reports gallery](https://sre.azure.com/agents/subscriptions/26081847-0bf1-4c5a-84f5-f18dd3902200/resourceGroups/rg-sre-agent/providers/Microsoft.App/agents/msdn-sre-agent/views/liveReports)
or choose a scenario:

* [01: HTTP 500](https://sre.azure.com/agents/subscriptions/26081847-0bf1-4c5a-84f5-f18dd3902200/resourceGroups/rg-sre-agent/providers/Microsoft.App/agents/msdn-sre-agent/views/liveReports/livereport-15a71534-343f-4d4c-8dd8-c2cf53e7de9b)
* [02: Latency](https://sre.azure.com/agents/subscriptions/26081847-0bf1-4c5a-84f5-f18dd3902200/resourceGroups/rg-sre-agent/providers/Microsoft.App/agents/msdn-sre-agent/views/liveReports/livereport-5ace93a5-42e2-4aab-b2e9-eaac78fc86ef)
* [03: Dependency failure](https://sre.azure.com/agents/subscriptions/26081847-0bf1-4c5a-84f5-f18dd3902200/resourceGroups/rg-sre-agent/providers/Microsoft.App/agents/msdn-sre-agent/views/liveReports/livereport-7a6c14dd-215c-43f0-8cd9-92d557de716b)
* [04: Throttling](https://sre.azure.com/agents/subscriptions/26081847-0bf1-4c5a-84f5-f18dd3902200/resourceGroups/rg-sre-agent/providers/Microsoft.App/agents/msdn-sre-agent/views/liveReports/livereport-561c3874-386d-4556-be4d-9ea1b28c1aac)
* [05: Queue backlog](https://sre.azure.com/agents/subscriptions/26081847-0bf1-4c5a-84f5-f18dd3902200/resourceGroups/rg-sre-agent/providers/Microsoft.App/agents/msdn-sre-agent/views/liveReports/livereport-688f2252-13a5-4393-bd5f-a0d4a5a84cf3)
* [06: Poison message](https://sre.azure.com/agents/subscriptions/26081847-0bf1-4c5a-84f5-f18dd3902200/resourceGroups/rg-sre-agent/providers/Microsoft.App/agents/msdn-sre-agent/views/liveReports/livereport-8d3fd629-b79b-40c4-80ce-0e76760632b5)
* [07: Memory pressure](https://sre.azure.com/agents/subscriptions/26081847-0bf1-4c5a-84f5-f18dd3902200/resourceGroups/rg-sre-agent/providers/Microsoft.App/agents/msdn-sre-agent/views/liveReports/livereport-128dffb6-6cd1-45ab-b45b-ae15f12240d3)
* [08: CPU saturation](https://sre.azure.com/agents/subscriptions/26081847-0bf1-4c5a-84f5-f18dd3902200/resourceGroups/rg-sre-agent/providers/Microsoft.App/agents/msdn-sre-agent/views/liveReports/livereport-4e393ee6-d0dc-4506-be50-86e4da6d4303)
* [09: Configuration drift](https://sre.azure.com/agents/subscriptions/26081847-0bf1-4c5a-84f5-f18dd3902200/resourceGroups/rg-sre-agent/providers/Microsoft.App/agents/msdn-sre-agent/views/liveReports/livereport-c8fa2a32-3f66-438b-9f56-a220c46bcf32)
* [10: Deployment regression](https://sre.azure.com/agents/subscriptions/26081847-0bf1-4c5a-84f5-f18dd3902200/resourceGroups/rg-sre-agent/providers/Microsoft.App/agents/msdn-sre-agent/views/liveReports/livereport-46ee7c60-463d-407c-aaa6-d7407fe376b4)

Access requires the appropriate native Agent user role. Sharing a report URL
does not grant access, and these reports are not public portal pages.

Each report uses 12 embedded seeded random sample rows, illustrative KPI cards,
SVG charts, a sample table, phase controls, and an investigation outline.
The example UTC window is October 14, 2026, from 06:00 to 18:00. These fixed
samples do not become current measurements when you open or reload the report.
There are no permitted report tools or model-assisted refresh calls.

The corrected version has four KPI cards and two SVG charts per report.
Browser checks verified the 12 sample rows, valid timestamps within the
declared UTC window, and phase filtering from 12 rows to 3 and back to 12.
The same sample data persisted across a browser reload. Filters use
nonce-authorized event listeners rather than inline event handlers blocked
by the report sandbox's content security policy.

> [!IMPORTANT]
> All metrics, resources, phase labels, and recovery examples are fictional.
> KPI examples are independent illustrations, not aggregates of the sample rows.
> The reports do not establish real customer impact, diagnosed causes, or
> performed remediation. Queue production is not depth, and this workload has
> no consumer, poison queue, or replay workflow.

For an actual investigation, use the
[read-only skill templates](sre-agent-configuration-and-skills.md#repository-skill-templates)
with authorized telemetry. The report-validation skill reviews evidence; it
does not create or modify reports.

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

Each connector-backed report must:

* Load without write-tool approval prompts
* Expose the requested time and scenario filters
* Show a clear no-data state before a scenario runs
* Update after **Reload** when new telemetry arrives
* Keep the saved layout stable across reloads
* Avoid model calls during routine refresh
