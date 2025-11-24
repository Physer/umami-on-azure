param redisName string
@allowed([
  'Data Owner'
  'Data Contributor'
  'Data Reader'
])
param policyAssignmentName string
param policyAssignmentObjectId string
param policyAssignmentObjectAlias string

resource redis 'Microsoft.Cache/redis@2024-11-01' existing = {
  name: redisName
}

resource redisCacheBuiltInAccessPolicyAssignment 'Microsoft.Cache/redis/accessPolicyAssignments@2024-11-01' = {
  name: '${redisName}-${policyAssignmentName}-policy-${uniqueString(resourceGroup().id)}'
  parent: redis
  properties: {
    accessPolicyName: policyAssignmentName
    objectId: policyAssignmentObjectId
    objectIdAlias: policyAssignmentObjectAlias
  }
}
