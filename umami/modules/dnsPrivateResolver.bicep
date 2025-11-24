param location string = resourceGroup().location
param dnsResolverName string
param virtualNetworkName string
param inboundSubnetName string
param outboundSubnetName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-07-01' existing = {
  name: virtualNetworkName
}

resource inboundSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' existing = {
  parent: virtualNetwork
  name: inboundSubnetName
}

resource outboundSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' existing = {
  parent: virtualNetwork
  name: outboundSubnetName
}

resource dnsPrivateResolver 'Microsoft.Network/dnsResolvers@2025-05-01' = {
  name: dnsResolverName
  location: location
  properties: {
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}

resource inboundEndpoint 'Microsoft.Network/dnsResolvers/inboundEndpoints@2025-05-01' = {
  parent: dnsPrivateResolver
  name: 'in-endpoint'
  location: location
  properties: {
    ipConfigurations: [
      {
        privateIpAllocationMethod: 'Dynamic'
        subnet: {
          id: inboundSubnet.id
        }
      }
    ]
  }
}

resource outboundEndpoint 'Microsoft.Network/dnsResolvers/outboundEndpoints@2025-05-01' = {
  parent: dnsPrivateResolver
  name: 'out-endpoint'
  location: location
  properties: {
    subnet: {
      id: outboundSubnet.id
    }
  }
}
