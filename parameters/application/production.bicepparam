using '../../deployApplication.bicep'

// Environment definition
var environment = 'production'

// Global parameters
param umamiDatabaseName = 'umami'
param appServiceSubnetName = 'snet-appservice'
param postgresSubnetName = 'snet-postgres'
param pgAdminAppServicePrivateEndpointSubnetName = 'snet-pgadmin-pe'

// Environment-specific parameters
param appServicePlanSkuTier = 'Basic'
param appServicePlanSkuSize = 'B1'
param appServicePlanSkuFamily = 'B'
param appServicePlanName = 'plan-analytics-${environment}'
param umamiAppServiceName = 'app-umami-${environment}'
param postgresServerName = 'psql-umami-${environment}'
param virtualNetworkName = 'vnet-analytics-${environment}'
param applicationInsightsName = 'appi-analytics-${environment}'
param logAnalyticsWorkspaceName = 'log-analytics-${environment}'
param keyVaultName = 'kv-analytics-${environment}'

// Admin tools parameters
param deployPgAdmin = false
param pgAdminAppServiceName = 'app-pgadmin-${environment}'
