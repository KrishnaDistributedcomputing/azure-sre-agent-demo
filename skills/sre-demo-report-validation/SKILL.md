---
name: sre-demo-report-validation
description: Use for read-only reliability dashboards, Live Report evidence checks, sample-chart labeling, and measurement validation in the SRE demo - Brought to you by KrishnaDistributedcomputing/azure-sre-agent-demo
tools:
  - system-mcp-monitor_monitor_workspace_log_query
---

# Demo report evidence validation

## Scope and safeguards

Subscription: 26081847-0bf1-4c5a-84f5-f18dd3902200.
Resource group: rg-sre-demo.
Workspace: log-sredemo-be3wpifmuf (4cc00420-dd6c-4b5a-a7b2-970960622540).
Requires an enabled native SRE Agent skill, the declared query tool, and
existing workspace authorization.
Use only read-only queries and authorized report content. Do not create,
save, edit, delete, schedule, or trigger model-assisted refresh of reports.
Do not change resource settings, permissions, consumption limits, or teardown.
Queries and investigations may incur usage charges; keep checks bounded.

## Procedure

1. Identify the report, provenance, UTC query window, resource scope,
   metric definitions, filters, units, denominator, and refresh timestamp.
2. Classify each value as actual queried telemetry, an illustrative sample,
   a simulation label, a planning assumption, or uninstrumented.
3. Validate required aggregates through AppTraces and AppRequests. Pass
   subscription explicitly with workspace, resource-group, and hours.
4. For each chart, record KQL, returned table, timestamp, sample size,
   aggregation, and missing-data behavior. Never replace missing data with
   zero or call stale data current.
5. Explain that portal sample charts are not saved native Live Reports.
   A sample before/incident/recovered series is not a performed recovery.
6. Compare equivalent time windows only when actual measurements support
   them. Report uncertainty and a safe, unexecuted correction proposal.

## Measurement limits

Queue produced counts are not depth, age, or drain rate. Memory allocation
does not establish a leak or OOM. CPU exercise duration is not fleet CPU
percentage. Synthetic failures do not establish production customer impact.
Simulation root-cause labels are not independently verified diagnoses.
A release-marker edit and the generic health endpoint do not prove recovery
of deployment-regression or config-drift.

## Output and troubleshooting

Return a compact table of metric, classification, evidence and query,
freshness, limitations, and pass or gap. Cite actual results and exact
errors. Do not invent improvements, SLA compliance, or recovery percentages.
Skill guidance does not override RBAC or effective tool policies.

> Brought to you by KrishnaDistributedcomputing/azure-sre-agent-demo
