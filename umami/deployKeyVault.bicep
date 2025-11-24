// Networking parameters
param virtualNetworkName string
param keyVaultSubnetName string
param keyVaultPrivateEndpointName string

// Key Vault parameters
param keyVaultName string

// Key Vault
module keyVault 'modules/keyVault.bicep' = {
  name: 'deployVault'
  params: {
    keyVaultName: keyVaultName
  }
}

module keyVaultPrivateEndpoint 'modules/privateEndpoint.bicep' = {
  name: 'deployKeyVaultPrivateEndpoint'
  params: {
    privateEndpointName: keyVaultPrivateEndpointName
    virtualNetworkName: virtualNetworkName
    subnetName: keyVaultSubnetName
    resourceIdToLink: keyVault.outputs.resourceId
    groupIds: [
      'vault'
    ]
  }
}

module keyVaultPrivateDns 'modules/privateDnsZone.bicep' = {
  name: 'deployKeyVaultPrivateDns'
  params: {
    privateDnsZoneFqdn: 'privatelink.vaultcore.azure.net'
    virtualNetworkName: virtualNetworkName
  }
}

module keyVaultPrivateDnsARecord 'modules/privateDnsARecord.bicep' = {
  name: 'deployKeyVaultPrivateDnsARecord'
  params: {
    privateDnsZoneFqdn: keyVaultPrivateDns.outputs.resourceName
    networkInterfaceName: keyVaultPrivateEndpoint.outputs.privateEndpointNetworkInterfaceName
    dnsRecordName: keyVaultName
  }
}
