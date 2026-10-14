---
name: sre-demo-evidence-triage
description: Use for read-only Azure Functions HTTP failures, latency, telemetry gaps, and incident evidence triage in rg-sre-demo - Brought to you by KrishnaDistributedcomputing/azure-sre-agent-demo
tools:
  - RunAzCliReadCommands
  - system-mcp-monitor_monitor_workspace_log_query
---

# Demo evidence triage

## Scope and safeguards

Subscription: 26081847-0bf1-4c5a-84f5-f18dd3902200.
Resource group: rg-sre-demo. Function App: sredemo-be3wpifmuf.
Workspace: log-sredemo-be3wpifmuf (4cc00420-dd6c-4b5a-a7b2-970960622540).
Requires an enabled native SRE Agent skill, the declared tools, and existing
identity authorization for this scope.
Keep Review mode. Do not change resources, settings, role assignments,
incident integrations, budgets, or teardown. Never retrieve credentials,
tokens, connection strings, or unrelated workload data.

## Procedure

1. Confirm the UTC window and question. Default to the last 24 hours and
   bounded aggregate results.
2. Query AppTraces and AppRequests with the attached workspace query tool.
   Pass subscription explicitly with workspace, resource-group, and hours.
   Start with the query below.
3. Cite actual tool results, KQL, counts, timestamps, and scope. Zero rows,
   ingestion delay, daily caps, and permission errors are limitations, not
   evidence of health.
4. Retrieve reviewed code through an already authorized connection or indexed
   knowledge. If GitHub remains pending, report code unavailable unless a
   real source citation is returned.
5. Separate observations, hypotheses, counter-evidence, simulation labels,
   and unknowns. Use read-only CLI only for non-secret resource metadata.
6. Return the next safe diagnostic and human-reviewed proposals. Never
   execute remediation.

```kusto
union withsource=SourceTable AppTraces, AppRequests
| where TimeGenerated > ago(24h)
| summarize Rows=count(), Latest=max(TimeGenerated) by SourceTable
```

## Interpretation limits

HTTP 500, payment failures, and 429 responses are synthetic.
Latency is a fixed three-second delay.
Queue item_count means messages produced, not queue depth. There is no
consumer, retry, poison queue, quarantine, or replay workflow.
Memory allocates 24 MiB and does not prove a leak or OOM.
CPU hashing lasts about two seconds and is not measured fleet CPU percent.
Configuration compares SRE_DEMO_MODE with healthy; validate through
config-drift, not generic health. Deployment-regression always returns
HTTP 500; changing the release marker does not recover it.
expected_root_cause is a simulation label, not proof.

## Output and troubleshooting

Return scope, tools and KQL, observed evidence, hypotheses, limitations, and
next validation. On failure, report the exact error and stop unsupported
conclusions. These instructions supplement RBAC and tool policies; they do
not grant authorization.

> Brought to you by KrishnaDistributedcomputing/azure-sre-agent-demo
