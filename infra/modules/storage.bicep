// AI Foundry Logistics Assistant — Storage Module
// Azure Storage Account (dependency for AI Foundry Hub)

@description('Storage Account name (max 24 chars, no hyphens)')
param name string

@description('Azure region')
param location string

@description('Resource tags')
param tags object

@description('Log Analytics Workspace resource ID for diagnostics')
param logAnalyticsWorkspaceResourceId string

// ──────────────────────────────────────────────
// Storage Account (AVM)
// ──────────────────────────────────────────────

module storageAccount 'br/public:avm/res/storage/storage-account:0.14.0' = {
  name: '${name}-deploy'
  params: {
    name: name
    location: location
    tags: tags
    kind: 'StorageV2'
    skuName: 'Standard_LRS'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalyticsWorkspaceResourceId
        metricCategories: [
          { category: 'Transaction', enabled: true }
        ]
      }
    ]
  }
}

// ──────────────────────────────────────────────
// Outputs
// ──────────────────────────────────────────────

@description('Storage Account resource ID')
output resourceId string = storageAccount.outputs.resourceId

@description('Storage Account name')
output resourceName string = storageAccount.outputs.name

@description('Storage Account principal ID (empty — no system identity on storage)')
output principalId string = ''
