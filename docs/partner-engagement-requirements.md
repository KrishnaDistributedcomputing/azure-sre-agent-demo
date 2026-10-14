---
title: Partner Engagement and Azure Implementation Requirements
description: Must-have governance, documentation, implementation, and acceptance requirements for partner-led Azure SRE Agent customer engagements
author: Azure SRE demo team
ms.date: 2026-10-14
ms.topic: reference
keywords:
  - Azure SRE Agent
  - partner governance
  - customer engagement
  - implementation evidence
estimated_reading_time: 14
---

## Requirement statement

All requirements in this document are mandatory for partner-led customer
engagements involving the Azure SRE Agent showcase or a derivative
implementation.

The partner must document every customer engagement, technical decision,
implementation activity, validation result, security assignment, cost control,
operational procedure, and acceptance decision. The documentation must provide
enough evidence for the customer and Microsoft stakeholders to understand what
was agreed, why it was selected, what was deployed, how it was validated, who
approved it, and what remains open.

> [!IMPORTANT]
> Verbal agreement, meeting attendance, portal screenshots without context, and
> undocumented configuration changes do not satisfy these requirements.

## Deployed Azure component baseline

The current evaluation contains 19 top-level Azure resources across three
resource groups. Four supporting or child components complete the deployment.

The partner must confirm this baseline before each engagement. Any addition,
removal, substitution, or configuration change requires documented rationale,
customer approval, implementation evidence, and updated operational guidance.

### SRE Agent resource group

Resource group: `rg-sre-agent`

| Resource | Azure type | Purpose | Required partner evidence |
|----------|------------|---------|---------------------------|
| `msdn-sre-agent` | `Microsoft.App/agents` | Investigates reliability signals and recommends actions | Agent scope, connector design, model choice, usage allocation, validation, and customer approval |
| `msdn-sre-agent-aaxceouyeq3aw` | `Microsoft.ManagedIdentity/userAssignedIdentities` | Provides credential-free access for Agent operations | Identity purpose, assigned roles, scopes, and least-privilege review |
| `workspaceaaxceouyeq3aw` | `Microsoft.OperationalInsights/workspaces` | Stores Agent operational telemetry | Retention, ingestion, access, data boundary, and query validation |
| `msdn-sre-agent-61deb7af-8ddc-app-insights` | `Microsoft.Insights/components` | Collects Agent application telemetry | Workspace linkage, telemetry purpose, access model, and health validation |
| `Application Insights Smart Detection` | `Microsoft.Insights/actionGroups` | Supports smart-detection notification routing | Recipient ownership, notification test, escalation path, and review cadence |

### Demo workload resource group

Resource group: `rg-sre-demo`

| Resource | Azure type | Purpose | Required partner evidence |
|----------|------------|---------|---------------------------|
| `sredemo-be3wpifmuf` | `Microsoft.Web/sites` | Hosts scenario APIs and public showcase dashboards | Runtime, routes, identity, configuration, deployment record, health check, and rollback plan |
| `asp-sredemo-be3wpifmuf` | `Microsoft.Web/serverfarms` | Supplies Flex Consumption compute | SKU rationale, scale settings, regional decision, capacity boundary, and cost assumption |
| `sredemobe3wpifmuf` | `Microsoft.Storage/storageAccounts` | Stores Function packages and controlled scenario messages | Network access, TLS, public-access settings, data purpose, retention, and access review |
| `id-sredemo-be3wpifmuf` | `Microsoft.ManagedIdentity/userAssignedIdentities` | Authenticates Function deployment storage | Role assignments, scope, lifecycle, and credential-free deployment validation |
| `log-sredemo-be3wpifmuf` | `Microsoft.OperationalInsights/workspaces` | Stores and queries correlated demo telemetry | Daily cap, retention, query access, ingestion test, and cost monitoring |
| `appi-sredemo-be3wpifmuf` | `Microsoft.Insights/components` | Collects request, exception, and dependency telemetry | Workspace linkage, sampling decision, scenario evidence, and availability check |
| `ag-sre-demo` | `Microsoft.Insights/actionGroups` | Routes reliability notifications | Recipient approval, notification test, ownership, and escalation procedure |
| `alert-sre-demo-severity` | `Microsoft.Insights/scheduledQueryRules` | Detects controlled severity 1 and 2 signals | Query, threshold, evaluation period, action, test result, and false-positive review |
| `alert-sre-demo-http-failures` | `Microsoft.Insights/metricAlerts` | Detects failed customer-facing HTTP requests | Metric, threshold, evaluation period, action group, test response, and recovery validation |
| `webtest-sre-demo-health` | `Microsoft.Insights/webtests` | Checks the public health endpoint every five minutes | Endpoint, test location, frequency, timeout, TLS validation, and failure response |
| `92c9fbfb-f80a-5eb6-8348-db0150007740` | `Microsoft.Insights/workbooks` | Provides the Azure Monitor dashboard | Audience, queries, time range, expected visuals, access path, and review result |

### Guardrail resource group

Resource group: `rg-sre-guardrails`

| Resource | Azure type | Purpose | Required partner evidence |
|----------|------------|---------|---------------------------|
| `logic-sre-demo-day-29-teardown` | `Microsoft.Logic/workflows` | Deletes evaluation resource groups before fixed Agent billing begins | Trigger time, target scopes, identity, permissions, test evidence, owner, and manual fallback |
| `alert-sre-demo-service-health` | `Microsoft.Insights/activityLogAlerts` | Notifies owners about Azure incidents and planned events | Incident types, subscription scope, action group, notification test, owner, and escalation procedure |
| `alert-sre-demo-resource-health` | `Microsoft.Insights/activityLogAlerts` | Detects degraded or unavailable Azure resources | Health states, subscription scope, action group, test plan, owner, and recovery procedure |

### Subscription and child components

| Component | Azure capability | Purpose | Required partner evidence |
|-----------|------------------|---------|---------------------------|
| `azure-sre-agent-demo-monthly` | Cost Management budget | Alerts at 50%, 80%, and forecasted 100% of the $100 target | Amount, recipients, thresholds, notification test, and weekly review record |
| `sre-demo-events` | Azure Storage queue | Supports queue backlog and poison-message scenarios | Queue purpose, message boundary, scenario procedure, cleanup, and data classification |
| Function deployment package | Private blob container | Stores the remotely built Function package | Private-access validation, deployment identity, retention, and package provenance |
| Least-privilege role assignments | Azure RBAC | Limits telemetry, storage, inventory, and teardown access | Principal, role, scope, justification, approval, validation, and removal plan |

## Partner engagement requirements

### Customer engagement record

The partner must create one engagement record before technical work begins. The
record must contain:

* Customer organization and approved stakeholders
* Business objective and expected outcome
* In-scope and out-of-scope services
* Customer environment, tenant, subscription, region, and data boundary
* Assumptions, constraints, dependencies, and known risks
* Engagement milestones and decision dates
* Partner, customer, and Microsoft owners
* Communication and escalation paths
* Success measures and acceptance authority

Every workshop, design review, implementation session, operational exercise,
and executive readout must be added to the engagement record within two
business days.

### Meeting and customer interaction evidence

Each material customer interaction must record:

| Field | Requirement |
|-------|-------------|
| Date and attendees | Identify organizations, roles, and decision authority |
| Purpose | State the intended decision or outcome |
| Customer context | Capture business priorities, technical constraints, and concerns |
| Discussion | Summarize relevant facts without unsupported interpretation |
| Decisions | Link each decision to its decision record |
| Actions | Include owner, due date, status, and closure evidence |
| Risks and blockers | Include impact, owner, mitigation, and escalation |
| Customer confirmation | Record approval, rejection, or requested revision |

### Technical decision records

A technical decision record is required for every material choice, including:

* Azure service and SKU selection
* Region and availability design
* Identity and RBAC model
* Network and public-access configuration
* Telemetry, retention, ingestion, and alerting
* SRE Agent scope, model provider, and consumption allocation
* Data handling and privacy boundary
* Cost controls and teardown strategy
* Deployment, rollback, and recovery approach
* Exceptions to customer or Microsoft standards

Each decision record must include:

1. Decision title, date, status, and owner.
2. Customer requirement and decision context.
3. Options considered.
4. Evaluation criteria and evidence.
5. Selected option and rationale.
6. Security, privacy, operational, and cost consequences.
7. Risks, mitigations, and residual risk owner.
8. Approvers and approval evidence.
9. Review or expiration date.
10. Links to implementation and validation records.

### Implementation record

Every implementation activity must be reproducible and traceable. The record
must include:

* Work item or change identifier
* Repository, branch, commit, and pull request
* Infrastructure-as-code module and parameters
* Target tenant, subscription, resource group, and region
* Predeployment checks and approvals
* Deployment command, pipeline, or release identifier
* Start and completion timestamps
* Resources created, changed, or removed
* Configuration changes without secret values
* Validation commands and results
* Issues encountered and corrective action
* Rollback procedure and result when used
* Implementer and independent reviewer

Manual portal changes are prohibited unless the customer-approved procedure
requires them. Every approved manual change must be recorded and reconciled
back into infrastructure as code.

## Security and privacy requirements

The partner must:

* Use managed identities instead of embedded credentials wherever supported
* Apply least-privilege roles at the narrowest practical scope
* Record every principal, role, scope, justification, owner, and expiration
* Prevent secrets, access tokens, connection strings, and customer data from
  entering source control or public dashboards
* Confirm storage public access, TLS, and network configuration
* Document telemetry fields and data classification
* Obtain customer approval before exposing any endpoint publicly
* Validate that public APIs return only approved metadata
* Review role assignments before handover and after teardown
* Record security exceptions with an approver and remediation date

## Cost and consumption requirements

The partner must provide a cost model before deployment. It must distinguish:

* Trial charges from post-trial charges
* Fixed SRE Agent capacity from active-flow consumption
* Model-provider multiplier effects
* Log Analytics ingestion and retention
* Application Insights and alerting
* Function execution and storage
* Network or optional-service costs
* Tax, currency, agreement, and regional assumptions

The partner must confirm:

* A customer-approved monthly budget
* Budget alert recipients and tested notifications
* SRE Agent consumption allocation
* Weekly Cost Management review ownership
* Trial end date and post-trial decision date
* Automatic teardown and manual fallback
* Production funding approval before extending the evaluation

## Operational readiness requirements

Before customer acceptance, the partner must document and validate:

* Service ownership and support boundaries
* Health, telemetry, alert, and dashboard access
* Incident severity and escalation model
* Investigation and recovery runbooks
* Backup, restore, continuity, and regional assumptions
* Change, deployment, rollback, and emergency procedures
* Capacity and quota limits
* Cost-monitoring and teardown procedures
* Known limitations and deferred work
* Handover, access transfer, and knowledge-transfer completion

The ten controlled reliability scenarios must have recorded execution evidence,
expected signals, root cause, investigation steps, remediation, recovery
criteria, and customer-observed outcome.

## Required deliverables

The partner must maintain the following deliverables in a customer-approved
repository or documentation system:

| Deliverable | Minimum update frequency |
|-------------|--------------------------|
| Engagement charter and scope | At engagement start and every approved scope change |
| Stakeholder and responsibility matrix | At start and when ownership changes |
| Customer interaction log | Within two business days of each material interaction |
| Architecture and resource inventory | After every deployment change |
| Technical decision records | Before implementation of each material decision |
| Implementation and change records | During every deployment |
| Security and RBAC register | After every access change |
| Cost model and consumption report | Before deployment and weekly during evaluation |
| Validation and test evidence | During implementation and before acceptance |
| Risk, issue, action, and dependency log | At least weekly |
| Operational runbooks | Before operational handover |
| Acceptance and handover record | At completion |
| Teardown or production-transition evidence | At evaluation closure |

## Definition of done

The engagement is complete only when:

1. The customer confirms the agreed business outcomes were evaluated.
2. The deployed inventory matches the approved architecture.
3. Every material decision has an approved decision record.
4. Every implementation has traceable deployment and validation evidence.
5. Security, privacy, RBAC, and public-access reviews are complete.
6. Cost assumptions, current consumption, and post-trial implications are
   acknowledged.
7. Alerts, dashboards, scenarios, and recovery procedures are validated.
8. Open risks have named owners and agreed target dates.
9. Runbooks, source, access, and knowledge are handed over.
10. The customer signs the acceptance record.
11. The environment is either approved for funded continuation or teardown is
    verified.

## Exception management

Any exception to a must-have requirement must include:

* The requirement that cannot be met
* Business and technical justification
* Customer impact
* Security, operational, and cost risk
* Compensating control
* Named risk owner
* Approver
* Expiration date
* Remediation action and due date

An undocumented exception is a failed requirement.
