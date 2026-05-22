// AI Foundry Logistics Assistant — AI Foundry Module
// AI Foundry Account (Hub) + Project + GPT-4.1-mini deployment
// Raw Bicep — no AVM module available for CognitiveServices/AIServices kind

@description('AI Foundry Account (Hub) name')
param accountName string

@description('AI Foundry Project name')
param projectName string

@description('Azure region (must support GPT-4.1-mini — use swedencentral)')
param location string

@description('Resource tags')
param tags object

@description('Log Analytics Workspace resource ID for diagnostics')
param logAnalyticsWorkspaceId string

// ──────────────────────────────────────────────
// AI Foundry Account (Hub)
// ──────────────────────────────────────────────

resource aiAccount 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: accountName
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: accountName
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
    allowProjectManagement: true
  }
}

// ──────────────────────────────────────────────
// Diagnostic Settings — AI Foundry Account
// ──────────────────────────────────────────────

resource aiAccountDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${accountName}'
  scope: aiAccount
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// ──────────────────────────────────────────────
// GPT-4.1-mini Model Deployment
// ──────────────────────────────────────────────

resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  parent: aiAccount
  name: 'gpt-4.1-mini'
  sku: {
    name: 'Standard'
    capacity: 30
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4.1-mini'
      version: '2025-04-14'
    }
    raiPolicyName: 'Microsoft.DefaultV2'
  }
}

// ──────────────────────────────────────────────
// AI Foundry Project
// ──────────────────────────────────────────────

resource aiProject 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  parent: aiAccount
  name: projectName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'Logistics AI Assistant Project'
    description: 'AI Foundry project for logistics operations: shipment tracking, exception alerts, delivery predictions.'
  }
  dependsOn: [
    modelDeployment
  ]
}

// ──────────────────────────────────────────────
// Outputs
// ──────────────────────────────────────────────

@description('AI Foundry Account resource ID')
output resourceId string = aiAccount.id

@description('AI Foundry Account name')
output resourceName string = aiAccount.name

@description('AI Foundry Account system-assigned principal ID')
output principalId string = aiAccount.identity.principalId

@description('AI Foundry Project resource ID')
output projectResourceId string = aiProject.id

@description('AI Foundry Project name')
output projectName string = aiProject.name

@description('AI Foundry Project system-assigned principal ID')
output projectPrincipalId string = aiProject.identity.principalId

@description('AI Foundry Account endpoint')
output endpoint string = aiAccount.properties.endpoint

@description('GPT model deployment name')
output modelDeploymentName string = modelDeployment.name
