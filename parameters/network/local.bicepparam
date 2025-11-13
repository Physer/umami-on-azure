using '../../deployNetwork.bicep'

// Environment definition
var environment = 'local'

// Global parameters
param vpnAddressSpace = '172.16.0.0/24'
param appServiceSubnetName = 'snet-appservice'
param keyVaultSubnetName = 'snet-keyvault'
param postgresSubnetName = 'snet-postgres'
param dnsPrivateResolverInboundSubnetName = 'snet-dns-inbound'
param dnsPrivateResolverOutboundSubnetName = 'snet-dns-outbound'
param pgAdminAppServicePrivateEndpointSubnetName = 'snet-pgadmin-pe'
param redisSubnetName = 'snet-redis'

// Environment-specific parameters
param virtualNetworkName = 'vnet-analytics-${environment}'
param virtualNetworkGatewayPublicIpName = 'pip-vpn-analytics-${environment}'
param virtualNetworkGatewayName = 'vgw-analytics-${environment}'
param dnsPrivateResolverName = 'dnspr-analytics-${environment}'
param deployVpnGateway = false
