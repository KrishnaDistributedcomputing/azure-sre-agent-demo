---
title: Azure SRE Agent Demo
description: Low-cost 30-day Azure SRE Agent evaluation with ten incident scenarios and reusable dashboards
author: Azure SRE demo team
ms.date: 2026-10-14
ms.topic: overview
---

## Overview

This public evaluation project demonstrates Azure SRE Agent investigations,
telemetry correlation, alert response, Azure Monitor workbooks, and Live Reports
across ten controlled failure modes.

> [!WARNING]
> Azure SRE Agent costs about $292 per month in fixed always-on charges after the
> 30-day new-customer trial, before active usage. This deployment schedules
> deletion of the agent and demo resource groups on day 29. Verify the teardown
> workflow and delete the agent manually if the workflow is disabled or fails.

## Architecture

The project shares one serverless workload across every use case to keep Azure
resource costs low:

```text
Scenario script
    |
    v
Azure Functions Consumption --> Application Insights --> Log Analytics
    |                                  |                     |
    v                                  v                     v
Storage Queue                    Monitor alert         SRE Agent connector
                                                            |
                                                            v
                                            Live Reports and investigations
```

Cost controls include:

* $100 monthly Azure Cost Management budget
* 0.1 GB/day Log Analytics ingestion cap
* One alert rule shared by all scenarios
* One Function App on the Consumption plan
* Day-29 automatic deletion of the SRE Agent and demo workload
* Recommended 500-AAU active-flow allocation in SRE Agent settings

## Deploy

Prerequisites:

* Azure CLI and Bicep CLI
* Azure Functions Core Tools
* PowerShell 7
* Owner, or Contributor plus User Access Administrator, on the subscription

Authenticate Azure CLI:

```powershell
az login --scope https://management.core.windows.net//.default
```

Deploy the stack:

```powershell
./scripts/Deploy-Demo.ps1 `
  -SubscriptionId 26081847-0bf1-4c5a-84f5-f18dd3902200 `
  -AlertEmail <your-alert-email>
```

The script writes non-secret resource outputs to `deployment-output.json`, then
publishes the Python Function App.

## Run and investigate

Generate all ten telemetry patterns:

```powershell
./scripts/Invoke-Scenario.ps1 -Scenario All
```

Open the deployed **Azure SRE Agent Demo Dashboard** workbook for a structured
view of reliability signals. See [Demonstration scenarios](docs/scenarios.md)
for expected diagnoses and investigation prompts.

Create reusable SRE-native dashboards with the prompts in
[Azure SRE Agent Live Reports](docs/live-reports.md).

## Public showcase portal

The no-login portal queries Log Analytics with the Function App managed identity
and refreshes every 60 seconds:

<https://sredemo-be3wpifmuf.azurewebsites.net/api/portal>

The public data endpoint supports 1, 4, 24, and 168-hour time ranges:

<https://sredemo-be3wpifmuf.azurewebsites.net/api/dashboard-data?hours=24>

Use the business cost planner to compare the 30-day evaluation with ongoing
post-trial pricing assumptions:

<https://sredemo-be3wpifmuf.azurewebsites.net/api/cost>

See the [Business Showcase Portal Guide](docs/portal-guide.md) for audience
paths, dashboard interpretation, all ten business scenarios, costing
assumptions, a presentation playbook, and troubleshooting.

The managed identity has Log Analytics Reader access only on the demo workspace.
The API caches query results for 60 seconds to limit query volume and cost.

## Cost boundary

The $100 limit applies only to this 30-day evaluation design. The minimum
500-AAU active-flow allocation represents up to $50 at the documented
$0.10-per-AAU rate. Keep the remaining Azure resource spend below $50, avoid
repeated model-assisted report refreshes, and delete the agent before its trial
ends.

Use **Settings > Agent consumption** to track AAUs. Use Azure Cost Management to
track resource charges and confirm the budget notifications.
