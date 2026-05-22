// AI Foundry Logistics Assistant — Main Orchestration
// Azure AI Foundry Hub + Project + GPT-4.1-mini
// Azure Container Apps (.NET 10 logistics web app)
// Azure SQL Database (General Purpose Serverless)
targetScope = 'resourceGroup'

// ──────────────────────────────────────────────
// Parameters
// ──────────────────────────────────────────────

@description('Azure region for primary resources.')
param location string

@description('Environment name (from azd).')
@minLength(1)
@maxLength(64)
param environment string

@description('Project name used in resource naming.')
param projectName string = 'fsc'

@description('Principal ID of the deploying user. Azure Developer CLI populates this automatically.')
param principalId string

@description('Azure region for AI Foundry resources (must support GPT-4.1-mini).')
param aiFoundryLocation string = 'swedencentral'

@description('Container image to deploy. Updated by azd deploy after build.')
param containerImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

// ──────────────────────────────────────────────
// Variables
// ──────────────────────────────────────────────

var uniqueSuffix = uniqueString(resourceGroup().id)

var tags = {
  Environment: environment
  ManagedBy: 'Bicep'
  Project: projectName
  SecurityControl: 'Ignore'
}

// CAF-compliant resource names
var logName      = 'log-${projectName}-${environment}'
var appiName     = 'appi-${projectName}-${environment}'
var stName       = 'st${take(replace(projectName, '-', ''), 8)}${take(environment, 3)}${take(uniqueSuffix, 6)}'
var sqlSvrName   = 'sql-${projectName}-${environment}'
var sqlDbName    = 'sqldb-${projectName}-${environment}'
var crName       = 'cr${take(replace(projectName, '-', ''), 8)}${take(environment, 3)}${take(uniqueSuffix, 6)}'
var aiAcctName   = 'ai-${take(projectName, 8)}-${take(environment, 3)}-${take(uniqueSuffix, 6)}'
var aiProjName   = 'aiproj-${projectName}-${environment}'
var caeName      = 'cae-${projectName}-${environment}'
var caName       = 'ca-${take(projectName, 16)}-${take(environment, 8)}'

// ──────────────────────────────────────────────
// Phase 1: Monitoring
// ──────────────────────────────────────────────

module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring-${uniqueSuffix}-deploy'
  params: {
    logAnalyticsName: logName
    appInsightsName: appiName
    location: location
    tags: tags
  }
}

// ──────────────────────────────────────────────
// Phase 2: Data + Registry (parallel)
// ──────────────────────────────────────────────

module storage 'modules/storage.bicep' = {
  name: 'storage-${uniqueSuffix}-deploy'
  params: {
    name: stName
    location: location
    tags: tags
    logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceId
  }
}

module sql 'modules/sql.bicep' = {
  name: 'sql-${uniqueSuffix}-deploy'
  params: {
    serverName: sqlSvrName
    databaseName: sqlDbName
    location: location
    tags: tags
    sqlAdminObjectId: principalId
    sqlAdminLogin: 'azd-deployer'
    logAnalyticsWorkspaceName: logName
  }
  dependsOn: [
    monitoring
  ]
}

module containerRegistry 'modules/container-registry.bicep' = {
  name: 'cr-${uniqueSuffix}-deploy'
  params: {
    name: crName
    location: location
    tags: tags
    logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceId
  }
}

// ──────────────────────────────────────────────
// Phase 3: AI Foundry (Hub + Project + Model)
// ──────────────────────────────────────────────

module aiFoundry 'modules/ai-foundry.bicep' = {
  name: 'ai-foundry-${uniqueSuffix}-deploy'
  params: {
    accountName: aiAcctName
    projectName: aiProjName
    location: aiFoundryLocation
    tags: tags
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
  }
}

// ──────────────────────────────────────────────
// Phase 4: Container Apps
// ──────────────────────────────────────────────

module containerApps 'modules/container-apps.bicep' = {
  name: 'ca-${uniqueSuffix}-deploy'
  params: {
    environmentName: caeName
    containerAppName: caName
    location: location
    tags: tags
    containerImage: containerImage
    containerRegistryServer: containerRegistry.outputs.loginServer
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
    aiFoundryEndpoint: aiFoundry.outputs.endpoint
    aiModelDeploymentName: aiFoundry.outputs.modelDeploymentName
    sqlServerFqdn: sql.outputs.fullyQualifiedDomainName
    sqlDatabaseName: sql.outputs.databaseName
  }
}

// ──────────────────────────────────────────────
// Phase 5: RBAC
// ──────────────────────────────────────────────

module roleAssignments 'modules/role-assignments.bicep' = {
  name: 'rbac-${uniqueSuffix}-deploy'
  params: {
    principalId: principalId
    containerAppPrincipalId: containerApps.outputs.principalId
    aiFoundryPrincipalId: aiFoundry.outputs.principalId
    aiFoundryProjectPrincipalId: aiFoundry.outputs.projectPrincipalId
    containerRegistryId: containerRegistry.outputs.resourceId
    containerRegistryName: containerRegistry.outputs.resourceName
    aiFoundryAccountId: aiFoundry.outputs.resourceId
    aiFoundryAccountName: aiFoundry.outputs.resourceName
    storageAccountId: storage.outputs.resourceId
    storageAccountName: storage.outputs.resourceName
  }
}

// ──────────────────────────────────────────────
// Outputs (consumed by azd + webapp)
// ──────────────────────────────────────────────

@description('Azure region')
output AZURE_LOCATION string = location

@description('Container App ingress URL')
output SERVICE_WEB_URI string = 'https://${containerApps.outputs.fqdn}'

@description('Container App name (used by azd deploy)')
output SERVICE_WEB_NAME string = containerApps.outputs.resourceName

@description('Container Registry login server')
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer

@description('Container Registry name')
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.resourceName

@description('AI Foundry Account endpoint')
output AI_FOUNDRY_ENDPOINT string = aiFoundry.outputs.endpoint

@description('AI model deployment name')
output AI_MODEL_DEPLOYMENT_NAME string = aiFoundry.outputs.modelDeploymentName

@description('SQL Server FQDN')
output SQL_SERVER string = sql.outputs.fullyQualifiedDomainName

@description('SQL Database name')
output SQL_DATABASE string = sql.outputs.databaseName

@description('Application Insights connection string')
output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.appInsightsConnectionString
