using '../../deployKeyVault.bicep'

// Environment definition
var environment = 'production'

// Global parameters
param keyVaultSubnetName = 'snet-keyvault'

// Environment-specific parameters
param virtualNetworkName = 'vnet-analytics-${environment}'
param keyVaultName = 'kv-analytics-${environment}'
param keyVaultPrivateEndpointName = 'pe-kv-analytics-${environment}'
