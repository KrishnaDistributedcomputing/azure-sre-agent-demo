---
name: sre-demo-queue-assessment
description: Use for read-only queue backlog, poison-message simulations, enqueue spikes, and queue evidence assessment in rg-sre-demo - Brought to you by KrishnaDistributedcomputing/azure-sre-agent-demo
tools:
  - RunAzCliReadCommands
  - system-mcp-monitor_monitor_workspace_log_query
---

# Demo queue assessment

## Scope and safeguards

Subscription: 26081847-0bf1-4c5a-84f5-f18dd3902200.
Resource group: rg-sre-demo. Storage account: sredemobe3wpifmuf.
Queue: sre-demo-events. Workspace: log-sredemo-be3wpifmuf
(4cc00420-dd6c-4b5a-a7b2-970960622540).
Requires an enabled native SRE Agent skill and the declared read-only tools.
Use only existing identity authorization.
Do not enqueue, receive, dequeue, peek at message payloads, delete, purge,
replay, quarantine, change configuration, list storage keys, generate SAS,
or change permissions. Do not invoke scenario APIs to generate more messages.

## Procedure

1. Confirm the UTC window and whether the question concerns produced events,
   actual queue depth, or consumer processing.
2. Query bounded AppTraces aggregates for queue-backlog and poison-message
   scenario evidence. Inspect the actual schema before referencing custom
   properties. Pass subscription explicitly to the workspace query tool.
3. Distinguish enqueue counts from queue depth. If needed and permitted,
   read queue metadata using identity authentication, never account keys.
   Use the command below.
4. Label approximate message counts as approximate and timestamp the
   observation. Compare equivalent windows only if actual measurements exist.
5. If data-plane authorization fails, report the error. Do not grant roles
   or retrieve keys as a workaround.
6. Propose missing consumer instrumentation and a human-owned next step
   without performing any queue mutation.

```text
az storage queue metadata show --account-name sredemobe3wpifmuf --name sre-demo-events --auth-mode login --subscription 26081847-0bf1-4c5a-84f5-f18dd3902200
```

## Evidence limits

This demo is producer-only. It has no deployed queue consumer, retries,
poison queue, quarantine, replay, or measured drain rate. poison-message
is a simulation label, not evidence of processing failure or dead-lettering.
item_count is produced messages, not current depth. Do not infer age,
delivery failures, recovery, customer impact, or consumer health.

## Output and troubleshooting

Return scope, observed producer signals, measured queue metadata if available,
exact tools and queries, explicit missing evidence, and next safe validation.
Read-only instructions do not substitute for RBAC and tool enforcement.

> Brought to you by KrishnaDistributedcomputing/azure-sre-agent-demo
