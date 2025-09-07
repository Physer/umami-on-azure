param location string = resourceGroup().location

param keyVaultName string
param keyVaultPrivateEndpointName string
param virtualNetworkName string
param subnetName string

resource keyVault 'Microsoft.KeyVault/vaults@2024-12-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    enabledForTemplateDeployment: true
    enableRbacAuthorization: true
    publicNetworkAccess: 'Disabled'
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: tenant().tenantId
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-07-01' = {
  name: keyVaultPrivateEndpointName
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
    }
    privateLinkServiceConnections: [
      {
        name: '${keyVaultName}-connection'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
}
