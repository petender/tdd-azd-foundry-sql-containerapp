// AI Foundry Logistics Assistant — Monitoring Module
// Log Analytics Workspace + Application Insights

@description('Log Analytics Workspace name')
param logAnalyticsName string

@description('Application Insights name')
param appInsightsName string

@description('Azure region')
param location string

@description('Resource tags')
param tags object

// ──────────────────────────────────────────────
// Log Analytics Workspace (AVM)
// ──────────────────────────────────────────────

module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.9.0' = {
  name: '${logAnalyticsName}-deploy'
  params: {
    name: logAnalyticsName
    location: location
    tags: tags
    skuName: 'PerGB2018'
    dataRetention: 30
    dailyQuotaGb: 5
  }
}

// ──────────────────────────────────────────────
// Application Insights (AVM)
// ──────────────────────────────────────────────

module appInsights 'br/public:avm/res/insights/component:0.4.0' = {
  name: '${appInsightsName}-deploy'
  params: {
    name: appInsightsName
    location: location
    tags: tags
    workspaceResourceId: logAnalytics.outputs.resourceId
    applicationType: 'web'
    kind: 'web'
  }
}

// ──────────────────────────────────────────────
// Outputs
// ──────────────────────────────────────────────

@description('Log Analytics Workspace resource ID')
output logAnalyticsWorkspaceId string = logAnalytics.outputs.resourceId

@description('Log Analytics Workspace name')
output logAnalyticsWorkspaceName string = logAnalytics.outputs.name

@description('Application Insights resource ID')
output appInsightsResourceId string = appInsights.outputs.resourceId

@description('Application Insights connection string')
output appInsightsConnectionString string = appInsights.outputs.connectionString
