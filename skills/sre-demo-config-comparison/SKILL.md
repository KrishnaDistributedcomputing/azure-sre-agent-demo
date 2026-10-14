---
name: sre-demo-config-comparison
description: Use for read-only configuration drift, SRE_DEMO_MODE baseline comparison, and release-marker interpretation in rg-sre-demo - Brought to you by KrishnaDistributedcomputing/azure-sre-agent-demo
tools:
  - RunAzCliReadCommands
  - system-mcp-monitor_monitor_workspace_log_query
---

# Demo configuration comparison

## Scope and safeguards

Subscription: 26081847-0bf1-4c5a-84f5-f18dd3902200.
Resource group: rg-sre-demo. Function App: sredemo-be3wpifmuf.
Workspace: log-sredemo-be3wpifmuf (4cc00420-dd6c-4b5a-a7b2-970960622540).
Requires an enabled native SRE Agent skill, the declared tools, and existing
identity authorization for this scope.
Keep Review mode. Do not change settings, restart, deploy, roll back, modify
roles, or alter budget and teardown. Never retrieve or display the app-settings
collection, connection strings, keys, tokens, or credentials.

## Procedure

1. Establish the UTC window and the approved non-secret baseline.
   For this demo only, SRE_DEMO_MODE is healthy for the simulated healthy
   configuration. Do not invent a production baseline.
2. Query bounded config-drift traces in AppTraces using actual schema.
   Supply subscription explicitly to the workspace query tool.
3. Read only projected non-secret site metadata when required: resource ID,
   state, kind, and location. Do not call app-settings or connection-string
   listing APIs to discover the setting. Use telemetry or approved,
   explicitly sanitized owner-provided evidence for SRE_DEMO_MODE.
4. If a current allowlisted setting value cannot be safely obtained, report
   that limitation. Do not broaden access or return a whole settings object.
5. Separate observed drift, approved baseline, timestamps, source revision,
   and inferred release correlation.
6. Recommend an exact human-reviewed change and rollback plan without
   executing it. Validation requires owner-approved config-drift scenario
   evidence; the generic health endpoint is not a drift acceptance check.

## Release interpretation

The deployment-regression scenario always returns HTTP 500. Changing
SRE_DEMO_RELEASE does not implement recovery. A release marker or
expected_root_cause label is not proof of causal deployment regression.
If GitHub is not connected, report missing source context rather than
claiming that local code was inspected.

## Output and troubleshooting

Return baseline source, observed non-secret evidence, differences, uncertainty,
tools and KQL, and an unexecuted validation proposal. Exact permission errors
must remain visible. Instructions do not grant permissions.

> Brought to you by KrishnaDistributedcomputing/azure-sre-agent-demo
