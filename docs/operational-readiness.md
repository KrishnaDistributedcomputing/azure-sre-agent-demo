---
title: Operational Readiness Pack
description: Design, operation, validation, cost, and response guidance for the Azure SRE Agent operational-readiness deployment
author: Azure SRE demo team
ms.date: 2026-10-14
ms.topic: how-to
keywords:
  - Azure Monitor
  - availability test
  - Service Health
  - Resource Health
  - operational readiness
estimated_reading_time: 8
---

## Purpose

The operational-readiness pack extends the controlled SRE Agent demonstration
with platform-level detection and an external customer-path health signal. It
adds low-volume monitoring without introducing another application workload.

## Deployed components

| Resource | Resource group | Purpose |
|----------|----------------|---------|
| `webtest-sre-demo-health` | `rg-sre-demo` | Calls the public health endpoint every five minutes from one Azure test location |
| `alert-sre-demo-http-failures` | `rg-sre-demo` | Alerts when Application Insights records one or more failed HTTP requests in five minutes |
| `alert-sre-demo-service-health` | `rg-sre-guardrails` | Alerts on Azure incidents, maintenance, required actions, and security advisories |
| `alert-sre-demo-resource-health` | `rg-sre-guardrails` | Alerts when an Azure resource becomes degraded, unavailable, or unknown |
| Function platform health check | `rg-sre-demo` | Configures `/api/health` as the Function App health-check path |

All alerts use the existing `ag-sre-demo` action group. The deployment does not
add another notification destination.

## Availability test

The standard Application Insights web test uses:

* Endpoint: `https://sredemo-be3wpifmuf.azurewebsites.net/api/health`
* Frequency: five minutes
* Timeout: 30 seconds
* Retry: enabled
* Expected status: HTTP 200
* TLS certificate validation: enabled
* Certificate lifetime check: seven days
* Test locations: one

One test location limits cost and provides a customer-path signal. It does not
demonstrate multi-region availability. Add locations only after updating the
cost model and receiving customer approval.

## HTTP failure alert

The Application Insights metric alert evaluates every five minutes over a
five-minute window. It triggers when the total `requests/failed` metric is
greater than zero. This signal is used because Flex Consumption does not
publish the App Service `Http5xx` platform metric.

Expected response:

1. Confirm the endpoint and time range.
2. Correlate the metric with Application Insights requests and exceptions.
3. Identify whether the event is a controlled scenario.
4. Record customer impact and correlation ID.
5. Validate recovery and alert mitigation.

## Service Health alert

The Service Health activity-log alert covers:

* Azure service incidents
* Planned maintenance
* Required customer actions
* Security advisories

The alert is subscription-scoped and routes through the existing action group.
The owner must validate notification delivery with an approved test or Azure
test-notification capability. Do not create a real service incident for
validation.

## Resource Health alert

The Resource Health activity-log alert covers:

* Degraded resources
* Unavailable resources
* Unknown resource state

The responder must determine whether the resource state affects the customer
path, identify related Azure Service Health events, and record the recovery
time.

## Cost boundary

The planning estimate increases supporting Azure infrastructure from $5 to $7
per month. The revised evaluation estimate is:

```text
$50 active-flow AAUs
 $7 serverless, telemetry, availability, and alerting estimate
---
$57 estimated evaluation total
```

The revised post-trial estimate is approximately $349 per month, including the
$292 fixed SRE Agent planning estimate.

> [!IMPORTANT]
> The $7 supporting-infrastructure figure is a planning assumption, not an
> invoice forecast. Availability test executions, alert rules, telemetry, tax,
> agreement, and regional pricing can change the result.

## Validation checklist

* The public health endpoint returns HTTP 200
* The availability test is enabled and linked to Application Insights
* The Function App health-check path is `/api/health`
* The HTTP failure metric alert is enabled and targets Application Insights
* The Service Health alert includes all four required incident types
* The Resource Health alert includes degraded, unavailable, and unknown states
* All four alerts reference the approved action group
* Action group ownership and escalation are documented
* The component dashboard shows 19 top-level resources
* The cost planner defaults to the $57 evaluation estimate

## Teardown

The day-29 Logic App deletes:

1. `rg-sre-demo`
2. `rg-sre-agent`
3. `rg-sre-guardrails`

Its managed identity has Contributor only on those three resource groups. The
guardrail group is deleted last so the workflow can initiate removal of the
availability and health-monitoring controls before its own resources are
removed.

The owner must still verify deletion in Azure Resource Graph and Cost
Management. If the workflow fails, delete all three groups manually.
