// App service parameters
param appServicePlanName string
param appServicePlanSkuTier string
param appServicePlanSkuSize string
param appServicePlanSkuFamily string
param umamiAppServiceName string
param deployPgAdmin bool
param pgAdminAppServiceName string?

// Database parameters
param postgresServerName string
param umamiDatabaseName string

// Monitoring parameters
param logAnalyticsWorkspaceName string
param applicationInsightsName string

// Key Vault parameters
param keyVaultName string

// Networking parameters
param virtualNetworkName string
param postgresSubnetName string
param appServiceSubnetName string
param pgAdminAppServicePrivateEndpointSubnetName string

// Key Vault secret names
var databaseUsernameSecretName = 'postgresDatabaseUsername'
var databasePasswordSecretName = 'postgresDatabasePassword'
var databaseConnectionStringSecretName = 'postgresDatabaseConnectionString'
var appSecretName = 'umamiAppSecret'
var pgAdminEmailAddressSecretName = 'pgAdminEmailAddress'
var pgAdminPasswordSecretName = 'pgAdminPassword'

// Role Assignment Definitions
var keyVaultSecretsUserRoleDefinitionId = '4633458b-17de-408a-b874-0445c86b69e6'

// Key Vault
resource keyVaultReference 'Microsoft.KeyVault/vaults@2024-12-01-preview' existing = {
  name: keyVaultName
}

// Application Insights and Azure Monitoring
module monitoring 'modules/monitoring.bicep' = {
  name: 'deployMonitoring'
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    applicationInsightsName: applicationInsightsName
  }
}

// Database
module postgresDatabasePrivateDns 'modules/privateDnsZone.bicep' = {
  name: 'deployPostgresDatabasePrivateDns'
  params: {
    privateDnsZoneFqdn: '${postgresServerName}.private.postgres.database.azure.com'
    virtualNetworkName: virtualNetworkName
  }
}

module postgresDatabase 'modules/postgres.bicep' = {
  name: 'deployPostgresDatabase'
  params: {
    resourceName: postgresServerName
    virtualNetworkName: virtualNetworkName
    postgresSubnetName: postgresSubnetName
    privateDnsZoneResourceId: postgresDatabasePrivateDns.outputs.resourceId
    administratorUsername: keyVaultReference.getSecret(databaseUsernameSecretName)
    administratorPassword: keyVaultReference.getSecret(databasePasswordSecretName)
    databaseName: umamiDatabaseName
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
  }
}

// App Services
module appServicePrivateDns 'modules/privateDnsZone.bicep' = {
  name: 'deployAppServicePrivateDns'
  params: {
    privateDnsZoneFqdn: 'privatelink.azurewebsites.net'
    virtualNetworkName: virtualNetworkName
  }
}

module appServicePlan 'modules/appServicePlan.bicep' = {
  name: 'deployAppServicePlan'
  params: {
    appServicePlanName: appServicePlanName
    skuFamily: appServicePlanSkuFamily
    skuSize: appServicePlanSkuSize
    skuTier: appServicePlanSkuTier
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
  }
}

module umamiAppService 'modules/dockerAppService.bicep' = {
  name: 'deployUmamiAppService'
  params: {
    appServicePlanId: appServicePlan.outputs.resourceId
    imageName: 'ghcr.io/umami-software/umami'
    imageTag: 'postgresql-latest'
    appServiceName: umamiAppServiceName
    subnetName: appServiceSubnetName
    virtualNetworkName: virtualNetworkName
    publicNetworkAccess: 'Enabled'
    appSettings: [
      {
        name: 'DATABASE_TYPE'
        value: 'postgresql'
      }
      {
        name: 'DATABASE_URL'
        value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${databaseConnectionStringSecretName})'
      }
      {
        name: 'APP_SECRET'
        value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${appSecretName})'
      }
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: monitoring.outputs.applicationInsightsConnectionString
      }
      {
        name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
        value: '~3'
      }
      {
        name: 'XDT_MicrosoftApplicationInsights_Mode'
        value: 'Recommended'
      }
    ]
  }
}

module pgAdminAppService 'modules/dockerAppService.bicep' = if (deployPgAdmin && !empty(pgAdminAppServiceName)) {
  name: 'deployPgAdminAppService'
  params: {
    appServiceName: pgAdminAppServiceName!
    appServicePlanId: appServicePlan.outputs.resourceId
    appSettings: [
      {
        name: 'PGADMIN_DEFAULT_EMAIL'
        value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${pgAdminEmailAddressSecretName})'
      }
      {
        name: 'PGADMIN_DEFAULT_PASSWORD'
        value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${pgAdminPasswordSecretName})'
      }
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: monitoring.outputs.applicationInsightsConnectionString
      }
      {
        name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
        value: '~3'
      }
      {
        name: 'XDT_MicrosoftApplicationInsights_Mode'
        value: 'Recommended'
      }
    ]
    imageName: 'dpage/pgadmin4'
    imageTag: 'latest'
    subnetName: appServiceSubnetName
    virtualNetworkName: virtualNetworkName
    publicNetworkAccess: 'Disabled'
  }
}

module pgAdminPrivateEndpoint 'modules/privateEndpoint.bicep' = if (deployPgAdmin && !empty(pgAdminAppServiceName)) {
  name: 'deployPgAdminPrivateEndpoint'
  params: {
    privateEndpointName: 'pe-${pgAdminAppServiceName!}'
    virtualNetworkName: virtualNetworkName
    subnetName: pgAdminAppServicePrivateEndpointSubnetName
    resourceIdToLink: pgAdminAppService!.outputs.resourceId
    groupIds: [
      'sites'
    ]
  }
}

module pgAdminPrivateDnsARecord 'modules/privateDnsARecord.bicep' = if (deployPgAdmin && !empty(pgAdminAppServiceName)) {
  name: 'deployPgAdminPrivateDnsARecord'
  params: {
    privateDnsZoneFqdn: appServicePrivateDns!.outputs.resourceName
    networkInterfaceName: pgAdminPrivateEndpoint!.outputs.privateEndpointNetworkInterfaceName
    dnsRecordName: replace(pgAdminAppService!.outputs.defaultHostName, '.azurewebsites.net', '')
  }
}

// Role Assignments
module umamiAppServiceKeyVaultRoleAssignment 'modules/roleAssignments/keyVaultRoleAssignment.bicep' = {
  name: 'deployUmamiAppServiceKeyVaultRoleAssignment'
  params: {
    keyVaultName: keyVaultName
    principalId: umamiAppService.outputs.principalId
    roleDefinitionId: keyVaultSecretsUserRoleDefinitionId
  }
}

module pgAdminAppServiceKeyVaultRoleAssignment 'modules/roleAssignments/keyVaultRoleAssignment.bicep' = if (deployPgAdmin && !empty(pgAdminAppServiceName)) {
  name: 'deployPgAdminAppServiceKeyVaultRoleAssignment'
  params: {
    keyVaultName: keyVaultName
    principalId: pgAdminAppService!.outputs.principalId
    roleDefinitionId: keyVaultSecretsUserRoleDefinitionId
  }
}
