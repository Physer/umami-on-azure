param location string = resourceGroup().location
@allowed(['CName', 'A'])
param dnsRecordType string = 'CName'
param appServiceName string
param customDomainValue string

resource appService 'Microsoft.Web/sites@2024-11-01' existing = {
  name: appServiceName
}

resource managedCertificate 'Microsoft.Web/certificates@2024-11-01' = {
  name: 'cert-${customDomainValue}'
  location: location
  properties: {
    canonicalName: customDomainValue
    serverFarmId: appService.properties.serverFarmId
  }
}

resource customDomain 'Microsoft.Web/sites/hostNameBindings@2024-11-01' = {
  parent: appService
  name: customDomainValue
  properties: {
    hostNameType: 'Verified'
    customHostNameDnsRecordType: dnsRecordType
    siteName: appServiceName
    sslState: 'SniEnabled'
    thumbprint: managedCertificate.properties.thumbprint
  }
}
