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
    keyVaultPrivateEndpointName: keyVaultPrivateEndpointName
    virtualNetworkName: virtualNetworkName
    subnetName: keyVaultSubnetName
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
    networkInterfaceName: keyVault.outputs.privateEndpointNetworkInterfaceName
    dnsRecordName: keyVaultName
  }
}
