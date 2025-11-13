param redisName string
param principalId string
param roleDefinitionId string

resource redis 'Microsoft.Cache/redis@2024-11-01' existing = {
  name: redisName
}

resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: roleDefinitionId
}

resource redisRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(redisName, principalId, roleDefinitionId)
  scope: redis
  properties: {
    principalId: principalId
    roleDefinitionId: roleDefinition.id
    principalType: 'ServicePrincipal'
  }
}
