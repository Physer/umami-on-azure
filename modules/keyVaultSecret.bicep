param keyVaultName string
param secretName string
@secure()
param secretValue string

resource keyVault 'Microsoft.KeyVault/vaults@2024-12-01-preview' existing = {
  name: keyVaultName
}

resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2025-05-01' = {
  name: secretName
  parent: keyVault
  properties: {
    value: secretValue
  }
}
