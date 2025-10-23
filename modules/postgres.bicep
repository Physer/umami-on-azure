param location string = resourceGroup().location
param skuName string = 'Standard_B1ms'
param skuTier string = 'Burstable'
param storageSizeInGb int = 32
param backupRetentionDays int = 7

param resourceName string
param virtualNetworkName string
param postgresSubnetName string
param privateDnsZoneResourceId string
param databaseName string
param logAnalyticsWorkspaceId string
@secure()
param administratorUsername string
@secure()
param administratorPassword string

resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2025-01-01-preview' = {
  name: resourceName
  location: location
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    version: '17'
    administratorLogin: administratorUsername
    administratorLoginPassword: administratorPassword
    authConfig: {
      activeDirectoryAuth: 'Disabled'
      passwordAuth: 'Enabled'
      tenantId: tenant().tenantId
    }
    network: {
      delegatedSubnetResourceId: resourceId(
        'Microsoft.Network/virtualNetworks/subnets',
        virtualNetworkName,
        postgresSubnetName
      )
      privateDnsZoneArmResourceId: privateDnsZoneResourceId
      publicNetworkAccess: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
    storage: {
      storageSizeGB: storageSizeInGb
      autoGrow: 'Enabled'
    }
    backup: {
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: 'Disabled'
    }
  }
}

resource databaseConfiguration 'Microsoft.DBforPostgreSQL/flexibleServers/configurations@2025-01-01-preview' = {
  name: 'azure.extensions'
  parent: postgresServer
  properties: {
    source: 'user-override'
    value: 'pgcrypto'
  }
}

resource postgresDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2025-01-01-preview' = {
  parent: postgresServer
  name: databaseName
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: postgresServer.name
  scope: postgresServer
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
