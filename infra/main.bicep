metadata name = 'Azure SRE Agent Demo'
metadata description = 'Deploys a low-cost SRE demo workload, monitoring, budget, and day-29 teardown.'

targetScope = 'subscription'

/*
 * Common parameters
 */

@description('Email address that receives budget and reliability alerts.')
param alertEmail string

@description('Azure region for the demo resources.')
param location string = 'westus2'

@description('UTC timestamp when the guardrail workflow deletes the SRE evaluation resources.')
param teardownUtc string

@description('UTC timestamp used to anchor the monthly budget period.')
param deploymentUtc string = utcNow('u')

/*
 * Resource naming parameters
 */

@description('Resource group that contains the SRE Agent.')
param agentResourceGroupName string = 'rg-sre-agent'

@description('Resource group for the low-cost demo workload.')
param demoResourceGroupName string = 'rg-sre-demo'

@description('Resource group for budget and teardown guardrails.')
param guardrailResourceGroupName string = 'rg-sre-guardrails'

/*
 * Variables
 */

var commonTags = {
  application: 'azure-sre-agent-demo'
  environment: 'evaluation'
  expiresOn: substring(teardownUtc, 0, 10)
  owner: 'sre-demo'
}
var contributorRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'b24988ac-6180-42a0-ab88-20f7382dd24c'
)
var readerRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'acdd72a7-3385-48ef-bd42-f606fba81ae7'
)
var budgetStartDate = '${substring(deploymentUtc, 0, 4)}-${substring(deploymentUtc, 5, 2)}-01T00:00:00Z'

/*
 * Resource groups
 */

resource agentResourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' existing = {
  name: agentResourceGroupName
}

resource demoResourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: demoResourceGroupName
  location: location
  tags: commonTags
}

resource guardrailResourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: guardrailResourceGroupName
  location: location
  tags: commonTags
}

/*
 * Budget
 */

resource evaluationBudget 'Microsoft.Consumption/budgets@2023-11-01' = {
  name: 'azure-sre-agent-demo-monthly'
  properties: {
    amount: 100
    category: 'Cost'
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: budgetStartDate
      endDate: dateTimeAdd(budgetStartDate, 'P5Y')
    }
    notifications: {
      Actual50Percent: {
        contactEmails: [
          alertEmail
        ]
        enabled: true
        locale: 'en-us'
        operator: 'GreaterThanOrEqualTo'
        threshold: 50
        thresholdType: 'Actual'
      }
      Actual80Percent: {
        contactEmails: [
          alertEmail
        ]
        enabled: true
        locale: 'en-us'
        operator: 'GreaterThanOrEqualTo'
        threshold: 80
        thresholdType: 'Actual'
      }
      Forecast100Percent: {
        contactEmails: [
          alertEmail
        ]
        enabled: true
        locale: 'en-us'
        operator: 'GreaterThanOrEqualTo'
        threshold: 100
        thresholdType: 'Forecasted'
      }
    }
  }
}

/*
 * Modules
 */

module demoStack 'modules/demo-stack.bicep' = {
  scope: demoResourceGroup
  params: {
    alertEmail: alertEmail
    inventoryResourceGroupNames: [
      agentResourceGroupName
      demoResourceGroupName
      guardrailResourceGroupName
    ]
    location: location
    resourcePrefix: 'sredemo'
    tags: commonTags
    teardownUtc: teardownUtc
  }
}

module guardrails 'modules/guardrails.bicep' = {
  scope: guardrailResourceGroup
  params: {
    agentResourceGroupName: agentResourceGroupName
    demoResourceGroupName: demoResourceGroupName
    location: location
    tags: commonTags
    teardownUtc: teardownUtc
  }
}

/*
 * Teardown permissions
 */

module guardrailAgentRole 'modules/role-assignment.bicep' = {
  scope: agentResourceGroup
  params: {
    principalId: guardrails.outputs.principalId
    roleDefinitionId: contributorRoleDefinitionId
  }
}

module guardrailDemoRole 'modules/role-assignment.bicep' = {
  scope: demoResourceGroup
  params: {
    principalId: guardrails.outputs.principalId
    roleDefinitionId: contributorRoleDefinitionId
  }
}

/*
 * Public inventory permissions
 */

module inventoryAgentReader 'modules/role-assignment.bicep' = {
  scope: agentResourceGroup
  params: {
    principalId: demoStack.outputs.functionPrincipalId
    roleDefinitionId: readerRoleDefinitionId
  }
}

module inventoryDemoReader 'modules/role-assignment.bicep' = {
  scope: demoResourceGroup
  params: {
    principalId: demoStack.outputs.functionPrincipalId
    roleDefinitionId: readerRoleDefinitionId
  }
}

module inventoryGuardrailReader 'modules/role-assignment.bicep' = {
  scope: guardrailResourceGroup
  params: {
    principalId: demoStack.outputs.functionPrincipalId
    roleDefinitionId: readerRoleDefinitionId
  }
}

/*
 * Outputs
 */

@description('Application Insights resource ID used by the SRE telemetry connector.')
output applicationInsightsId string = demoStack.outputs.applicationInsightsId

@description('Function App host name.')
output functionAppHostName string = demoStack.outputs.functionAppHostName

@description('Public no-login showcase portal URL.')
output portalUrl string = demoStack.outputs.portalUrl

@description('Public no-login component inventory dashboard URL.')
output resourceDashboardUrl string = demoStack.outputs.resourceDashboardUrl

@description('Public no-login evaluation cost planner URL.')
output costPlannerUrl string = demoStack.outputs.costPlannerUrl

@description('Function App name for code deployment.')
output functionAppName string = demoStack.outputs.functionAppName

@description('Log Analytics workspace resource ID used by the SRE telemetry connector.')
output logAnalyticsWorkspaceId string = demoStack.outputs.logAnalyticsWorkspaceId

@description('Azure Monitor workbook resource ID.')
output workbookId string = demoStack.outputs.workbookId

@description('UTC timestamp for automatic evaluation teardown.')
output teardownUtc string = teardownUtc
