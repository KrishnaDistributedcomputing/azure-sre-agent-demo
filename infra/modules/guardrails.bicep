metadata name = 'SRE Evaluation Guardrails'
metadata description = 'Deploys a one-time Logic App that deletes evaluation resources before fixed billing starts.'

/*
 * Common parameters
 */

@description('Resource group that contains the SRE Agent.')
param agentResourceGroupName string

@description('Resource group that contains the demo workload.')
param demoResourceGroupName string

@description('Azure region for the guardrail workflow.')
param location string

@description('Tags applied to the guardrail workflow.')
param tags object

@description('UTC timestamp when the workflow deletes evaluation resources.')
param teardownUtc string

/*
 * Variables
 */

var managementAudience = 'https://management.azure.com/'
var subscriptionBaseUri = 'https://management.azure.com/subscriptions/${subscription().subscriptionId}'

/*
 * Teardown workflow
 */

resource teardownWorkflow 'Microsoft.Logic/workflows@2019-05-01' = {
  name: 'logic-sre-demo-day-29-teardown'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      actions: {
        Delete_demo_resource_group: {
          inputs: {
            authentication: {
              audience: managementAudience
              type: 'ManagedServiceIdentity'
            }
            method: 'DELETE'
            uri: '${subscriptionBaseUri}/resourceGroups/${demoResourceGroupName}?api-version=2024-11-01'
          }
          runAfter: {}
          type: 'Http'
        }
        Delete_SRE_Agent_resource_group: {
          inputs: {
            authentication: {
              audience: managementAudience
              type: 'ManagedServiceIdentity'
            }
            method: 'DELETE'
            uri: '${subscriptionBaseUri}/resourceGroups/${agentResourceGroupName}?api-version=2024-11-01'
          }
          runAfter: {
            Delete_demo_resource_group: [
              'Succeeded'
              'Failed'
              'Skipped'
              'TimedOut'
            ]
          }
          type: 'Http'
        }
      }
      contentVersion: '1.0.0.0'
      outputs: {}
      parameters: {}
      triggers: {
        Day_29: {
          recurrence: {
            frequency: 'Month'
            interval: 1
            startTime: teardownUtc
            timeZone: 'UTC'
          }
          type: 'Recurrence'
        }
      }
    }
    parameters: {}
    state: 'Enabled'
  }
}

/*
 * Outputs
 */

@description('Managed identity principal ID used for teardown role assignments.')
output principalId string = teardownWorkflow.identity.principalId

@description('Name of the teardown workflow.')
output workflowName string = teardownWorkflow.name
