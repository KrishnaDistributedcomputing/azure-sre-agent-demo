---
title: Business Showcase Portal Guide
description: Business and technical guide for presenting the Azure SRE Agent reliability and cost portals
author: Azure SRE demo team
ms.date: 2026-10-14
ms.topic: how-to
keywords:
  - Azure SRE Agent
  - reliability
  - business showcase
  - cost planning
estimated_reading_time: 12
---

## Purpose

The public showcase translates Azure reliability telemetry into customer impact,
operational decisions, recovery actions, and cost controls. It is designed for
business leaders, service owners, SRE teams, application engineers, and
governance stakeholders.

The experience has four pages:

* [Reliability dashboard](https://sredemo-be3wpifmuf.azurewebsites.net/api/portal)
* [Evaluation cost planner](https://sredemo-be3wpifmuf.azurewebsites.net/api/cost)
* [Azure component command center](https://sredemo-be3wpifmuf.azurewebsites.net/api/resources)
* [Partner governance command center](https://sredemo-be3wpifmuf.azurewebsites.net/api/partner)

None of the pages requires a browser login. The reliability API queries the demo Log
Analytics workspace through the Function App managed identity. The cost planner
uses documented planning assumptions and does not query Azure billing data.

The component command center queries Azure Resource Graph every five minutes.
The Function App managed identity has Reader access only on the demo, SRE Agent,
and guardrail resource groups.

The partner governance command center presents the mandatory customer
engagement, technical decision, implementation, security, cost, operations,
handover, acceptance, and exception requirements. It includes the evidence
baseline for all 19 top-level and supporting Azure components.

> [!IMPORTANT]
> Every incident displayed by the portal is a controlled simulation. Do not
> interpret the signals as production-customer impact.

## Audience paths

Choose the shortest path for your audience.

| Audience | Start here | Focus |
|----------|------------|-------|
| Executive sponsor | Executive summary | Customer impact, readiness, cost boundary |
| Service owner | Business risk scenarios | Recovery criteria, ownership, prevention |
| SRE or operations | Trend and evidence | Severity, timing, correlation, investigation |
| Application engineer | Scenario detail | Signals, root cause, remediation |
| FinOps or governance | Cost planner | Trial boundary, AAU use, budget, teardown |

## Reliability dashboard

### Executive summary

The headline converts the current telemetry into a concise business statement.
It reports scenario readiness, high-impact events, watch-list events, transaction
volume, and peak P95 response time.

Use this section to answer three questions:

1. Did the demonstration produce evidence for all planned risks?
2. Which risks represent direct customer or revenue impact?
3. Is the evidence current enough for the walkthrough?

The three adjacent cards frame the value proposition:

* Customer experience connects technical symptoms to affected journeys
* Operational readiness demonstrates ten controlled failure modes
* Financial control shows the limits applied to the evaluation

### Reliability scorecard

| Measure | Business meaning | Interpretation |
|---------|------------------|----------------|
| Business events | Controlled signals found in the selected period | Confirms that scenario evidence exists |
| High impact | Severity 1 simulations | Represents direct customer, revenue, or service impact |
| Watch list | Severity 2 simulations | Represents degradation or risk before a full outage |
| Readiness | Scenarios with current evidence | A 10/10 result provides full showcase coverage |
| Transactions | Application requests observed | Establishes activity in the selected period |
| Customer wait | Peak P95 request duration | Shows the slow experience seen by the worst 5 percent |

Select or focus a question-mark button to open its help balloon. On touch
devices, select the button again or select elsewhere to close it.

### Business impact mix

The ring separates high-impact events from watch-list events. The center value
shows the total controlled signals. The readiness value reports how many of the
ten scenarios were observed.

Do not treat the ratio as a production health score. It describes the selected
demonstration period.

### Customer experience trend

The trend uses two vertical scales so transaction counts remain visible beside
response time:

* The left scale applies to requests and failures
* The right scale applies to P95 response time in milliseconds
* Blue represents transactions
* Red represents failures
* Amber represents customer wait

Point to a chart marker to see the value for one five-minute interval.

### Business risk scenarios

Select a scenario card to open its investigation story. Each story contains:

* The business measure affected by the scenario
* The expected customer or operational impact
* The evidence Azure records
* The contribution from Azure SRE Agent
* A sequenced investigation path
* Recommended remediation
* A measurable definition of recovery

The portal groups the ten scenarios into business concerns:

| Scenario | Business concern | Primary measure |
|----------|------------------|-----------------|
| Checkout HTTP 500 | Revenue protection | Successful checkout rate |
| Catalog latency breach | Customer experience | Catalog response time |
| Payment dependency outage | Partner resilience | Payment completion rate |
| API throttling | Demand management | Accepted request rate |
| Queue backlog | Order operations | Time to fulfillment |
| Poison message | Data quality | Valid order throughput |
| Memory pressure | Platform efficiency | Stable worker availability |
| CPU saturation | Platform efficiency | Transactions per compute unit |
| Configuration drift | Governance | Configuration compliance |
| Deployment regression | Change safety | Successful release rate |

### Signal-to-action workflow

The five-stage diagram explains the operating model:

1. Inject one bounded, controlled fault.
2. Observe the application and platform telemetry.
3. Correlate the evidence in Log Analytics.
4. Investigate likely cause and blast radius with Azure SRE Agent.
5. Improve the service through remediation, validation, and prevention.

Azure SRE Agent supports investigation. Human owners remain responsible for
approving and executing production changes.

### Evidence table

The table provides the telemetry behind the business narrative. Select a row to
open the corresponding scenario detail.

| Field | Use |
|-------|-----|
| Timestamp | Align the event with changes and alerts |
| Scenario | Identify the controlled fault |
| Severity | Prioritize response |
| Status | Interpret the HTTP outcome |
| Duration | Identify slow work |
| Items | Quantify messages, bytes, or iterations |
| Summary | Describe what happened |
| Expected root cause | Validate the intended diagnosis |
| Correlation ID | Follow the event across telemetry |

## Cost planner

The cost page separates the current evaluation from an ongoing deployment.

### Evaluation estimate

The 30-day trial waives the fixed SRE Agent capacity charge for an eligible new
customer. Active-flow consumption and supporting Azure resources remain
billable.

The default planning case uses:

* 500 active-flow AAUs at $0.10 per AAU, estimated at $50
* $5 for low-volume serverless demo infrastructure
* $0 fixed SRE Agent charge during the eligible trial
* $55 estimated evaluation total

### Post-trial estimate

The fixed planning estimate is:

```text
4 AAUs/hour x $0.10/AAU x 730 hours/month = approximately $292/month
```

With 500 active-flow AAUs and $5 of supporting infrastructure, the default
post-trial estimate becomes approximately $347 per month.

> [!WARNING]
> The $100 target does not support an always-on SRE Agent after the trial under
> these assumptions. Delete the Agent before the trial ends or approve a funded
> production plan.

### Interactive calculator

Use the sliders to change:

* Monthly active-flow AAUs
* Supporting infrastructure estimate
* Trial or post-trial pricing phase

The calculator compares the result with the $100 evaluation target. It is a
planning aid, not a billing integration.

Pricing may vary because of:

* Azure agreement and currency
* Region and tax
* Model-provider multipliers
* Actual active-flow consumption
* Telemetry ingestion and retention
* Function executions, duration, and storage
* Future Azure pricing changes

Validate approval figures in Azure pricing resources and Cost Management.

## Azure component command center

The component command center provides a live inventory of the top-level Azure
resources deployed for the evaluation.

### Summary and architecture

The summary reports:

* Top-level Azure resource count
* Resource group count
* Capability area count
* Azure location count
* Supporting control count

The architecture diagram groups the deployment into experience, compute and AI,
evidence, and control layers. Use it to explain how the public portals, Function
App, SRE Agent, observability services, storage, identity, and guardrails work
together.

### Inventory filters

Search by component name, resource type, or purpose. Filter the inventory by
resource group or capability area. Each card shows:

* Provisioning state
* Business capability
* Azure resource name and type
* Resource group and location
* SKU and kind
* Purpose in the evaluation

The resource-group distribution chart shows where the top-level resources are
deployed.

### Supporting components

Some deployed components do not appear as top-level Azure Resource Graph rows.
The dashboard lists these separately:

* $100 Cost Management budget
* Storage queue for backlog and poison-message scenarios
* Private Function deployment package container
* Least-privilege Azure RBAC assignments

### Inventory security

The public component API exposes resource inventory metadata only. It does not
return:

* Access tokens or credentials
* Function application settings
* Storage keys or connection strings
* Telemetry records
* Billing records
* Role-assignment principal details

The server filters results to the three configured evaluation resource groups,
even if the managed identity receives broader permissions later.

## Demonstration playbook

### Prepare

1. Open the reliability dashboard.
2. Select the time range that contains the latest scenario run.
3. Confirm readiness is 10/10.
4. Open the cost planner and confirm the teardown date and controls.

### Present

1. Begin with the executive headline.
2. Explain that every event is controlled and non-production.
3. Choose one revenue scenario and one operational scenario.
4. Connect business impact to Azure evidence.
5. Explain how SRE Agent narrows the investigation.
6. Finish with recovery criteria and prevention.

### Close

1. Review the cost boundary.
2. Assign owners for any follow-up action.
3. Confirm the next scenario or decision.
4. Verify automatic teardown remains scheduled.

## Data freshness and access

The browser refreshes reliability data every 60 seconds. The API caches Log
Analytics results for 60 seconds to reduce query volume and cost. The page is
public, but the managed identity has only Log Analytics Reader access to the
demo workspace.

The reliability page does not expose Azure credentials. Correlation IDs and
controlled scenario evidence are intentionally public for this demonstration.

## Troubleshooting

### The dashboard has no data

* Expand the time range to the last seven days
* Run the scenarios with `scripts/Invoke-Scenario.ps1`
* Allow several minutes for Application Insights ingestion
* Refresh the page

### Readiness is below 10/10

Run the missing scenarios and wait for telemetry ingestion. The scenario cards
identify which risks have not been observed.

### Help balloons do not remain open

Use keyboard focus or select the question-mark button. Selecting elsewhere
closes the active balloon.

### The cost estimate differs from Azure

The planner uses fixed assumptions rather than billing data. Check the Azure
agreement, model provider, region, consumption, and Cost Management records.

### The portal reports that telemetry is unavailable

Check Function App health, managed-identity workspace access, Log Analytics
availability, and the dashboard API response. The health and API endpoints are:

* <https://sredemo-be3wpifmuf.azurewebsites.net/api/health>
* <https://sredemo-be3wpifmuf.azurewebsites.net/api/dashboard-data?hours=24>
