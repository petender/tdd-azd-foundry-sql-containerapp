// AI Foundry Logistics Assistant — Role Assignments Module
// All RBAC bindings: deployer access + Container App MI access

@description('Principal ID of the deploying user (from AZURE_PRINCIPAL_ID)')
param principalId string

@description('Principal ID of the Container App system-assigned managed identity')
param containerAppPrincipalId string

@description('Principal ID of the AI Foundry Account system-assigned managed identity')
param aiFoundryPrincipalId string

@description('Principal ID of the AI Foundry Project system-assigned managed identity')
param aiFoundryProjectPrincipalId string

@description('Container Registry resource ID')
param containerRegistryId string

@description('Container Registry name')
param containerRegistryName string

@description('AI Foundry Account resource ID')
param aiFoundryAccountId string

@description('AI Foundry Account name')
param aiFoundryAccountName string

@description('Storage Account resource ID')
param storageAccountId string

@description('Storage Account name')
param storageAccountName string

// ──────────────────────────────────────────────
// Existing resource references
// ──────────────────────────────────────────────

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: containerRegistryName
}

resource aiFoundryAccount 'Microsoft.CognitiveServices/accounts@2025-06-01' existing = {
  name: aiFoundryAccountName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

// ──────────────────────────────────────────────
// Role definition IDs
// ──────────────────────────────────────────────

var azureAiOwnerRoleId = 'b78c5d69-af96-48a3-bf8d-a8b4d589de94'
var storageBlobContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var acrPushRoleId = '8311e382-0749-4cb8-b61a-304f252e45ec'

// ──────────────────────────────────────────────
// Deployer → Container Registry (AcrPush for azd deploy)
// ──────────────────────────────────────────────

resource deployerAcrPush 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(principalId)) {
  name: guid(containerRegistryId, principalId, acrPushRoleId)
  scope: containerRegistry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPushRoleId)
    principalId: principalId
    principalType: 'User'
  }
}

// ──────────────────────────────────────────────
// Deployer → AI Foundry Account (Azure AI Owner)
// ──────────────────────────────────────────────

resource deployerAiOwner 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(principalId)) {
  name: guid(aiFoundryAccountId, principalId, azureAiOwnerRoleId)
  scope: aiFoundryAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', azureAiOwnerRoleId)
    principalId: principalId
    principalType: 'User'
  }
}

// ──────────────────────────────────────────────
// Container App MI → AI Foundry Account (Azure AI Owner)
// Allows inference calls using managed identity
// ──────────────────────────────────────────────

resource containerAppAiOwner 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiFoundryAccountId, containerAppPrincipalId, azureAiOwnerRoleId)
  scope: aiFoundryAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', azureAiOwnerRoleId)
    principalId: containerAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ──────────────────────────────────────────────
// AI Foundry Account MI → Storage (Blob Contributor)
// ──────────────────────────────────────────────

resource aiFoundryStorageBlob 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccountId, aiFoundryPrincipalId, storageBlobContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobContributorRoleId)
    principalId: aiFoundryPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ──────────────────────────────────────────────
// AI Foundry Project MI → Storage (Blob Contributor)
// ──────────────────────────────────────────────

resource aiFoundryProjectStorageBlob 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccountId, aiFoundryProjectPrincipalId, storageBlobContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobContributorRoleId)
    principalId: aiFoundryProjectPrincipalId
    principalType: 'ServicePrincipal'
  }
}
