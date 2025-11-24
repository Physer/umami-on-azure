using '../../deployApplication.bicep'

// Environment definition
var environment = 'local'

// Global parameters
param umamiDatabaseName = 'umami'
param appServiceSubnetName = 'snet-appservice'
param postgresSubnetName = 'snet-postgres'
param pgAdminAppServicePrivateEndpointSubnetName = 'snet-pgadmin-pe'
param umamiDockerImageName = 'ghcr.io/umami-software/umami'
param umamiDockerImageTag = 'postgresql-v2'
param pgAdminDockerImageName = 'dpage/pgadmin4'
param pgAdminDockerImageTag = '9'
param redisSubnetName = 'snet-redis'
param redisUrlSecretName = 'redisUrl'

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
param redisName = 'redis-analytics-${environment}'

// Admin tools parameters
param deployPgAdmin = true
param pgAdminAppServiceName = 'app-pgadmin-${environment}'
