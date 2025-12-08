param appServiceName string
param appSettings object

resource appService 'Microsoft.Web/sites@2025-03-01' existing = {
  name: appServiceName
}

resource appServiceConfig 'Microsoft.Web/sites/config@2025-03-01' = {
  parent: appService
  name: 'appsettings'
  properties: appSettings
}
