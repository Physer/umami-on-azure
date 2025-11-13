param location string = resourceGroup().location
param redisName string
param redisSkuName string = 'Basic'
param redisSkuCapacity int = 0
param redisSkuFamily string = 'C'
param virtualNetworkName string
param subnetName string

resource redis 'Microsoft.Cache/redis@2024-11-01' = {
  name: redisName
  location: location
  properties: {
    sku: {
      name: redisSkuName
      capacity: redisSkuCapacity
      family: redisSkuFamily
    }
    publicNetworkAccess: 'Disabled'
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
  }
}
