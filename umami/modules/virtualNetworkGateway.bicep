param location string = resourceGroup().location
param tenantId string = subscription().tenantId
param skuName string = 'VpnGw1AZ'
param virtualNetworkName string
param subnetName string
param virtualNetworkGatewayName string
param publicIpName string
param vpnAddressSpace string

// Azure VPN Client application ID (well-known GUID for AAD authentication)
var microsoftRegisteredAudience = 'c632b3df-fb67-4d84-bdcf-b95ad541b5c8'
var microsoftRegisteredIssuer = 'https://sts.windows.net/${tenantId}/'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-07-01' existing = {
  name: virtualNetworkName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' existing = {
  parent: virtualNetwork
  name: subnetName
}

resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2024-07-01' existing = {
  name: publicIpName
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2024-07-01' = {
  name: virtualNetworkGatewayName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'vnetGatewayConfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet.id
          }
          publicIPAddress: {
            id: publicIpAddress.id
          }
        }
      }
    ]
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    activeActive: false
    allowRemoteVnetTraffic: false
    allowVirtualWanTraffic: false
    sku: {
      name: skuName
      tier: skuName
    }
    vpnClientConfiguration: {
      vpnClientAddressPool: {
        addressPrefixes: [
          vpnAddressSpace
        ]
      }
      vpnClientProtocols: [
        'OpenVPN'
      ]
      vpnAuthenticationTypes: [
        'AAD'
      ]
      aadAudience: microsoftRegisteredAudience
      aadIssuer: microsoftRegisteredIssuer
      aadTenant: uri(environment().authentication.loginEndpoint, tenantId)
    }
  }
}
