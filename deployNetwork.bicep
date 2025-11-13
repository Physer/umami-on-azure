// Networking parameters
param virtualNetworkName string
param dnsPrivateResolverName string
param appServiceSubnetName string
param postgresSubnetName string
param keyVaultSubnetName string
param dnsPrivateResolverInboundSubnetName string
param dnsPrivateResolverOutboundSubnetName string
param pgAdminAppServicePrivateEndpointSubnetName string
param redisSubnetName string
param vpnSubnetName string = 'GatewaySubnet' // This name is required by Azure

// VPN parameters
param virtualNetworkGatewayPublicIpName string
param virtualNetworkGatewayName string
param vpnAddressSpace string
param deployVpnGateway bool

module virtualNetwork './modules/virtualNetwork.bicep' = {
  name: 'deployVirtualNetwork'
  params: {
    applicationName: virtualNetworkName
    appServiceSubnetName: appServiceSubnetName
    postgresSubnetName: postgresSubnetName
    keyVaultSubnetName: keyVaultSubnetName
    dnsPrivateResolverInboundSubnetName: dnsPrivateResolverInboundSubnetName
    dnsPrivateResolverOutboundSubnetName: dnsPrivateResolverOutboundSubnetName
    vpnSubnetName: vpnSubnetName
    pgAdminAppServicePrivateEndpointSubnetName: pgAdminAppServicePrivateEndpointSubnetName
    redisSubnetName: redisSubnetName
  }
}

module dnsPrivateResolver 'modules/dnsPrivateResolver.bicep' = if (deployVpnGateway) {
  name: 'deployDnsPrivateResolver'
  params: {
    dnsResolverName: dnsPrivateResolverName
    virtualNetworkName: virtualNetworkName
    inboundSubnetName: dnsPrivateResolverInboundSubnetName
    outboundSubnetName: dnsPrivateResolverOutboundSubnetName
  }
}

module virtualNetworkGatewayPublicIp 'modules/publicIp.bicep' = if (deployVpnGateway) {
  name: 'deployVpnPublicIp'
  params: {
    publicIpName: virtualNetworkGatewayPublicIpName
  }
}

module virtualNetworkGateway 'modules/virtualNetworkGateway.bicep' = if (deployVpnGateway) {
  name: 'deployVpnGateway'
  params: {
    virtualNetworkName: virtualNetworkName
    subnetName: vpnSubnetName
    publicIpName: virtualNetworkGatewayPublicIpName
    virtualNetworkGatewayName: virtualNetworkGatewayName
    vpnAddressSpace: vpnAddressSpace
  }
}
