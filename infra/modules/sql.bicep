// AI Foundry Logistics Assistant — SQL Module
// Azure SQL Server + Basic Database (smallest SKU, 5 DTU)

@description('SQL Server name')
param serverName string

@description('SQL Database name')
param databaseName string

@description('Azure region')
param location string

@description('Resource tags')
param tags object

@description('Azure AD admin object ID (the deploying user or a group)')
param sqlAdminObjectId string

@description('Azure AD admin login name')
param sqlAdminLogin string

@description('Log Analytics Workspace name for diagnostics')
param logAnalyticsWorkspaceName string

// ──────────────────────────────────────────────
// SQL Server (AVM)
// ──────────────────────────────────────────────

module sqlServer 'br/public:avm/res/sql/server:0.10.0' = {
  name: '${serverName}-deploy'
  params: {
    name: serverName
    location: location
    tags: tags
    administratorLogin: 'sqladminlocal'
    administratorLoginPassword: uniqueString(resourceGroup().id, serverName, 'sqladmin')
    administrators: {
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: true
      login: sqlAdminLogin
      principalType: 'User'
      sid: sqlAdminObjectId
      tenantId: tenant().tenantId
    }
    publicNetworkAccess: 'Enabled'
    restrictOutboundNetworkAccess: 'Disabled'
    firewallRules: [
      {
        name: 'AllowAzureServices'
        startIpAddress: '0.0.0.0'
        endIpAddress: '0.0.0.0'
      }
    ]
    databases: [
      {
        name: databaseName
        sku: {
          name: 'Basic'
          tier: 'Basic'
          capacity: 5
        }
        zoneRedundant: false
        diagnosticSettings: [
          {
            workspaceResourceId: resourceId('Microsoft.OperationalInsights/workspaces', logAnalyticsWorkspaceName)
            logCategoriesAndGroups: [
              { categoryGroup: 'allLogs', enabled: true }
            ]
            metricCategories: [
              { category: 'Basic', enabled: true }
            ]
          }
        ]
      }
    ]
  }
}

// ──────────────────────────────────────────────
// Outputs
// ──────────────────────────────────────────────

@description('SQL Server resource ID')
output resourceId string = sqlServer.outputs.resourceId

@description('SQL Server name')
output resourceName string = sqlServer.outputs.name

@description('SQL Server fully qualified domain name')
output fullyQualifiedDomainName string = '${serverName}${environment().suffixes.sqlServerHostname}'

@description('SQL Database name')
output databaseName string = databaseName

@description('Principal ID placeholder (SQL Server has no system identity by default)')
output principalId string = ''
