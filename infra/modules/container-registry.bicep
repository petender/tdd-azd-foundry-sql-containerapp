// AI Foundry Logistics Assistant — Container Registry Module
// Azure Container Registry — Standard SKU, RBAC-only, admin disabled

@description('Container Registry name (max 50 chars, alphanumeric only)')
param name string

@description('Azure region')
param location string

@description('Resource tags')
param tags object

@description('Log Analytics Workspace resource ID for diagnostics')
param logAnalyticsWorkspaceResourceId string

// ──────────────────────────────────────────────
// Container Registry (AVM)
// ──────────────────────────────────────────────

module containerRegistry 'br/public:avm/res/container-registry/registry:0.6.0' = {
  name: '${name}-deploy'
  params: {
    name: name
    location: location
    tags: tags
    acrSku: 'Standard'
    acrAdminUserEnabled: false
    publicNetworkAccess: 'Enabled'
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalyticsWorkspaceResourceId
        logCategoriesAndGroups: [
          { categoryGroup: 'allLogs', enabled: true }
        ]
        metricCategories: [
          { category: 'AllMetrics', enabled: true }
        ]
      }
    ]
  }
}

// ──────────────────────────────────────────────
// Outputs
// ──────────────────────────────────────────────

@description('Container Registry resource ID')
output resourceId string = containerRegistry.outputs.resourceId

@description('Container Registry name')
output resourceName string = containerRegistry.outputs.name

@description('Container Registry login server (FQDN)')
output loginServer string = containerRegistry.outputs.loginServer

@description('Principal ID placeholder (ACR has no system identity)')
output principalId string = ''
