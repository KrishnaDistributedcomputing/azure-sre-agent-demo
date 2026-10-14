metadata name = 'SRE Demo Stack'
metadata description = 'Deploys a serverless workload, telemetry, alert, and workbook for SRE scenarios.'

/*
 * Common parameters
 */

@description('Email address that receives reliability alerts.')
param alertEmail string

@description('Azure region for the resources.')
param location string

@description('Short prefix used to create globally unique resource names.')
param resourcePrefix string

@description('Tags applied to every supported resource.')
param tags object

@description('UTC timestamp when the evaluation resources are automatically deleted.')
param teardownUtc string

@description('Resource groups included in the public read-only component inventory.')
param inventoryResourceGroupNames array

/*
 * Variables
 */

var uniqueSuffix = take(uniqueString(resourceGroup().id), 10)
var storageAccountName = '${resourcePrefix}${uniqueSuffix}'
var functionAppName = '${resourcePrefix}-${uniqueSuffix}'
var logAnalyticsWorkspaceName = 'log-${resourcePrefix}-${uniqueSuffix}'
var applicationInsightsName = 'appi-${resourcePrefix}-${uniqueSuffix}'
var workbookDisplayName = 'Azure SRE Agent Demo Dashboard'
var queueName = 'sre-demo-events'
var deploymentContainerName = 'app-package-${take(functionAppName, 32)}'
var storageBlobDataOwnerRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
)
var logAnalyticsReaderRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '73c42c96-874c-492b-b04d-ab87d138a893'
)

/*
 * Monitoring
 */

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  tags: tags
  properties: {
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  tags: tags
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    IngestionMode: 'LogAnalytics'
    Request_Source: 'rest'
    RetentionInDays: 30
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-sre-demo'
  location: 'global'
  tags: tags
  properties: {
    enabled: true
    groupShortName: 'sredemo'
    emailReceivers: [
      {
        emailAddress: alertEmail
        name: 'DemoOwner'
        useCommonAlertSchema: true
      }
    ]
  }
}

resource scenarioAlert 'Microsoft.Insights/scheduledQueryRules@2023-12-01' = {
  name: 'alert-sre-demo-severity'
  location: location
  tags: tags
  properties: {
    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }
    autoMitigate: false
    checkWorkspaceAlertsStorageConfigured: false
    criteria: {
      allOf: [
        {
          dimensions: []
          failingPeriods: {
            minFailingPeriodsToAlert: 1
            numberOfEvaluationPeriods: 1
          }
          operator: 'GreaterThanOrEqual'
          query: '''
            traces
            | where message has '"eventType":"sre-demo-scenario"'
            | extend event = parse_json(message)
            | where toint(event.severity) <= 2
          '''
          threshold: 1
          timeAggregation: 'Count'
        }
      ]
    }
    description: 'Detects controlled SRE demo scenarios with severity 1 or 2.'
    displayName: 'SRE demo reliability signal'
    enabled: true
    evaluationFrequency: 'PT5M'
    muteActionsDuration: 'PT15M'
    scopes: [
      applicationInsights.id
    ]
    severity: 2
    skipQueryValidation: false
    targetResourceTypes: [
      'Microsoft.Insights/components'
    ]
    windowSize: 'PT5M'
  }
}

resource workbook 'Microsoft.Insights/workbooks@2023-06-01' = {
  name: guid(resourceGroup().id, workbookDisplayName)
  location: location
  kind: 'shared'
  tags: union(tags, {
    'hidden-title': workbookDisplayName
  })
  properties: {
    category: 'workbook'
    displayName: workbookDisplayName
    serializedData: replace(
      loadTextContent('../../dashboards/azure-monitor-workbook.json'),
      '__APP_INSIGHTS_ID__',
      applicationInsights.id
    )
    sourceId: applicationInsights.id
    version: '1.0'
  }
}

/*
 * Storage
 */

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  tags: tags
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowCrossTenantReplication: false
    defaultToOAuthAuthentication: true
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Enabled'
    supportsHttpsTrafficOnly: true
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
}

resource deploymentContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: deploymentContainerName
  properties: {
    publicAccess: 'None'
  }
}

resource queueService 'Microsoft.Storage/storageAccounts/queueServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
}

resource scenarioQueue 'Microsoft.Storage/storageAccounts/queueServices/queues@2023-05-01' = {
  parent: queueService
  name: queueName
  properties: {
    metadata: {
      purpose: 'sre-demo'
    }
  }
}

/*
 * Compute
 */

resource deploymentIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${resourcePrefix}-${uniqueSuffix}'
  location: location
  tags: tags
}

resource deploymentStorageRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, deploymentIdentity.id, storageBlobDataOwnerRoleDefinitionId)
  scope: storageAccount
  properties: {
    principalId: deploymentIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: storageBlobDataOwnerRoleDefinitionId
  }
}

resource functionPlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: 'asp-${resourcePrefix}-${uniqueSuffix}'
  location: location
  kind: 'functionapp'
  tags: tags
  sku: {
    name: 'FC1'
    tier: 'FlexConsumption'
  }
  properties: {
    reserved: true
  }
}

resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  tags: tags
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${deploymentIdentity.id}': {}
    }
  }
  properties: {
    clientAffinityEnabled: false
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
    serverFarmId: functionPlan.id
    functionAppConfig: {
      deployment: {
        storage: {
          authentication: {
            type: 'UserAssignedIdentity'
            userAssignedIdentityResourceId: deploymentIdentity.id
          }
          type: 'blobContainer'
          value: '${storageAccount.properties.primaryEndpoints.blob}${deploymentContainer.name}'
        }
      }
      runtime: {
        name: 'python'
        version: '3.11'
      }
      scaleAndConcurrency: {
        instanceMemoryMB: 2048
        maximumInstanceCount: 40
      }
    }
    siteConfig: {
      healthCheckPath: '/api/health'
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
        }
        {
          name: 'AzureWebJobsFeatureFlags'
          value: 'EnableWorkerIndexing'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'SRE_DEMO_MODE'
          value: 'drifted'
        }
        {
          name: 'SRE_DEMO_RESOURCE_GROUPS'
          value: join(inventoryResourceGroupNames, ',')
        }
        {
          name: 'SRE_DEMO_QUEUE_NAME'
          value: queueName
        }
        {
          name: 'SRE_DEMO_RELEASE'
          value: '2026.10-bad'
        }
        {
          name: 'SRE_DEMO_TEARDOWN_UTC'
          value: teardownUtc
        }
        {
          name: 'SRE_DEMO_SUBSCRIPTION_ID'
          value: subscription().subscriptionId
        }
        {
          name: 'SRE_DEMO_WORKSPACE_ID'
          value: logAnalyticsWorkspace.properties.customerId
        }
      ]
      minTlsVersion: '1.2'
    }
  }
  dependsOn: [
    deploymentStorageRole
  ]
}

/*
 * Operational readiness
 */

resource healthAvailabilityTest 'Microsoft.Insights/webtests@2022-06-15' = {
  name: 'webtest-sre-demo-health'
  location: location
  kind: 'standard'
  tags: union(tags, {
    'hidden-link:${applicationInsights.id}': 'Resource'
  })
  properties: {
    SyntheticMonitorId: 'webtest-sre-demo-health'
    Name: 'SRE demo public health'
    Description: 'Validates the public Function health endpoint every five minutes.'
    Enabled: true
    Frequency: 300
    Timeout: 30
    Kind: 'standard'
    RetryEnabled: true
    Locations: [
      {
        Id: 'us-ca-sjc-azr'
      }
    ]
    Request: {
      RequestUrl: 'https://${functionApp.properties.defaultHostName}/api/health'
      HttpVerb: 'GET'
      ParseDependentRequests: false
      FollowRedirects: true
    }
    ValidationRules: {
      ExpectedHttpStatusCode: 200
      IgnoreHttpStatusCode: false
      SSLCheck: true
      SSLCertRemainingLifetimeCheck: 7
    }
  }
}

resource functionFailureAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-sre-demo-http-failures'
  location: 'global'
  tags: tags
  properties: {
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
    autoMitigate: true
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          metricName: 'requests/failed'
          metricNamespace: 'microsoft.insights/components'
          name: 'FailedRequestsTotal'
          operator: 'GreaterThan'
          skipMetricValidation: false
          threshold: 0
          timeAggregation: 'Count'
        }
      ]
    }
    description: 'Detects failed customer-facing HTTP requests recorded by Application Insights.'
    enabled: true
    evaluationFrequency: 'PT5M'
    scopes: [
      applicationInsights.id
    ]
    severity: 2
    targetResourceRegion: location
    targetResourceType: 'microsoft.insights/components'
    windowSize: 'PT5M'
  }
}

resource functionTelemetryRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(logAnalyticsWorkspace.id, functionApp.id, logAnalyticsReaderRoleDefinitionId)
  scope: logAnalyticsWorkspace
  properties: {
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: logAnalyticsReaderRoleDefinitionId
  }
}

resource deploymentIdentityTelemetryRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(logAnalyticsWorkspace.id, deploymentIdentity.id, logAnalyticsReaderRoleDefinitionId)
  scope: logAnalyticsWorkspace
  properties: {
    principalId: deploymentIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: logAnalyticsReaderRoleDefinitionId
  }
}

/*
 * Outputs
 */

@description('Application Insights resource ID.')
output applicationInsightsId string = applicationInsights.id

@description('Action group resource ID used by reliability and platform alerts.')
output actionGroupId string = actionGroup.id

@description('Function App host name.')
output functionAppHostName string = functionApp.properties.defaultHostName

@description('Function App name.')
output functionAppName string = functionApp.name

@description('Object ID of the Function App system-assigned managed identity.')
output functionPrincipalId string = functionApp.identity.principalId

@description('Public no-login showcase portal URL.')
output portalUrl string = 'https://${functionApp.properties.defaultHostName}/api/portal'

@description('Public no-login component inventory dashboard URL.')
output resourceDashboardUrl string = 'https://${functionApp.properties.defaultHostName}/api/resources'

@description('Public no-login evaluation cost planner URL.')
output costPlannerUrl string = 'https://${functionApp.properties.defaultHostName}/api/cost'

@description('Public no-login partner governance requirements URL.')
output partnerGovernanceUrl string = 'https://${functionApp.properties.defaultHostName}/api/partner'

@description('Log Analytics workspace resource ID.')
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id

@description('Azure Monitor workbook resource ID.')
output workbookId string = workbook.id
