param secretName string
param keyVaultName string
@secure()
param umamiDatabaseUsername string
@secure()
param umamiDatabasePassword string
param postgresServerName string
param umamiDatabaseName string

resource keyVault 'Microsoft.KeyVault/vaults@2025-05-01' existing = {
  name: keyVaultName
}

resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2025-05-01' = {
  name: secretName
  parent: keyVault
  properties: {
    value: 'postgresql://${umamiDatabaseUsername}:${umamiDatabasePassword}@${postgresServerName}.private.postgres.database.azure.com:5432/${umamiDatabaseName}?sslmode=require'
  }
}
