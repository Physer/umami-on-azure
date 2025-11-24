param location string = resourceGroup().location

param skuSize string
param skuTier string
param skuFamily string
param appServicePlanName string
param logAnalyticsWorkspaceId string

resource appServicePlan 'Microsoft.Web/serverfarms@2024-11-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: skuSize
    tier: skuTier
    size: skuSize
    family: skuFamily
    capacity: 1
  }
  properties: {
    reserved: true
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: appServicePlan.name
  scope: appServicePlan
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    metrics: [
      {
        enabled: true
        category: 'AllMetrics'
      }
    ]
  }
}

output resourceId string = appServicePlan.id
