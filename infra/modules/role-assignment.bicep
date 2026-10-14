metadata name = 'Resource Group Role Assignment'
metadata description = 'Assigns a role to a service principal at the current resource-group scope.'

/*
 * Identity parameters
 */

@description('Object ID of the service principal that receives the role.')
param principalId string

@description('Fully qualified role definition resource ID.')
param roleDefinitionId string

/*
 * Role assignment
 */

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, roleDefinitionId)
  properties: {
    principalId: principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: roleDefinitionId
  }
}

/*
 * Outputs
 */

@description('Resource ID of the role assignment.')
output roleAssignmentId string = roleAssignment.id
