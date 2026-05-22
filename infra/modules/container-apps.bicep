// AI Foundry Logistics Assistant — Container Apps Module
// Container Apps Environment + Container App (.NET 10 web frontend)

@description('Container Apps Environment name')
param environmentName string

@description('Container App name (max 32 chars)')
param containerAppName string

@description('Azure region')
param location string

@description('Resource tags')
param tags object

@description('Container image to deploy (ACR login server + image path)')
param containerImage string

@description('Container Registry login server for pull authentication')
param containerRegistryServer string

@description('Log Analytics Workspace resource ID for environment logging')
param logAnalyticsWorkspaceId string

@description('Application Insights connection string')
param appInsightsConnectionString string

@description('AI Foundry Account endpoint URL')
param aiFoundryEndpoint string

@description('AI model deployment name')
param aiModelDeploymentName string

@description('SQL Server fully qualified domain name')
param sqlServerFqdn string

@description('SQL Database name')
param sqlDatabaseName string

// ──────────────────────────────────────────────
// Container Apps Environment (AVM)
// ──────────────────────────────────────────────

module managedEnvironment 'br/public:avm/res/app/managed-environment:0.8.0' = {
  name: '${environmentName}-deploy'
  params: {
    name: environmentName
    location: location
    tags: tags
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceId
    zoneRedundant: false
  }
}

// ──────────────────────────────────────────────
// Container App (AVM)
// ──────────────────────────────────────────────

module containerApp 'br/public:avm/res/app/container-app:0.11.0' = {
  name: '${containerAppName}-deploy'
  params: {
    name: containerAppName
    location: location
    tags: tags
    environmentResourceId: managedEnvironment.outputs.resourceId
    containers: [
      {
        name: 'logistics-app'
        image: containerImage
        resources: {
          cpu: json('0.5')
          memory: '1Gi'
        }
        env: [
          {
            name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
            value: appInsightsConnectionString
          }
          {
            name: 'AI_FOUNDRY_ENDPOINT'
            value: aiFoundryEndpoint
          }
          {
            name: 'AI_MODEL_DEPLOYMENT_NAME'
            value: aiModelDeploymentName
          }
          {
            name: 'SQL_SERVER'
            value: sqlServerFqdn
          }
          {
            name: 'SQL_DATABASE'
            value: sqlDatabaseName
          }
          {
            name: 'ASPNETCORE_ENVIRONMENT'
            value: 'Production'
          }
        ]
      }
    ]
    registries: [
      {
        server: containerRegistryServer
        identity: 'system'
      }
    ]
    ingressExternal: true
    ingressTargetPort: 8080
    ingressTransport: 'auto'
    scaleMinReplicas: 0
    scaleMaxReplicas: 5
    scaleRules: [
      {
        name: 'http-scaling-rule'
        http: {
          metadata: {
            concurrentRequests: '10'
          }
        }
      }
    ]
    managedIdentities: {
      systemAssigned: true
    }
  }
}

// ──────────────────────────────────────────────
// Outputs
// ──────────────────────────────────────────────

@description('Container Apps Environment resource ID')
output environmentResourceId string = managedEnvironment.outputs.resourceId

@description('Container App resource ID')
output resourceId string = containerApp.outputs.resourceId

@description('Container App name')
output resourceName string = containerApp.outputs.name

@description('Container App system-assigned managed identity principal ID')
output principalId string = containerApp.outputs.systemAssignedMIPrincipalId

@description('Container App ingress FQDN')
output fqdn string = containerApp.outputs.fqdn
