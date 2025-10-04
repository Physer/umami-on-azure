param location string = resourceGroup().location

param applicationName string
param keyVaultSubnetName string
param postgresSubnetName string
param appServiceSubnetName string
param vpnSubnetName string
param dnsPrivateResolverInboundSubnetName string
param dnsPrivateResolverOutboundSubnetName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: applicationName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: postgresSubnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
          delegations: [
            {
              name: 'postgresDelegation'
              properties: {
                serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
              }
            }
          ]
        }
      }
      {
        name: appServiceSubnetName
        properties: {
          addressPrefix: '10.0.2.0/24'
          delegations: [
            {
              name: 'appServiceDelegation'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
            }
          ]
        }
      }
      {
        name: keyVaultSubnetName
        properties: {
          addressPrefix: '10.0.3.0/24'
        }
      }
      {
        name: vpnSubnetName
        properties: {
          addressPrefix: '10.0.4.0/24'
        }
      }
      {
        name: dnsPrivateResolverInboundSubnetName
        properties: {
          addressPrefix: '10.0.5.0/24'
          delegations: [
            {
              name: 'dnsPrivateResolverInboundDelegation'
              properties: {
                serviceName: 'Microsoft.Network/dnsResolvers'
              }
            }
          ]
        }
      }
      {
        name: dnsPrivateResolverOutboundSubnetName
        properties: {
          addressPrefix: '10.0.6.0/24'
          delegations: [
            {
              name: 'dnsPrivateResolverOutboundDelegation'
              properties: {
                serviceName: 'Microsoft.Network/dnsResolvers'
              }
            }
          ]
        }
      }
    ]
  }
}
