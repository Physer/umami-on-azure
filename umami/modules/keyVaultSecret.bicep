param keyVaultName string
param secretName string
@secure()
param secretValue string

resource keyVault 'Microsoft.KeyVault/vaults@2025-05-01' existing = {
  name: keyVaultName
}

resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2025-05-01' = {
  name: secretName
  parent: keyVault
  properties: {
    value: secretValue
  }
}
