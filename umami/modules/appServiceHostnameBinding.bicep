param appServiceName string
param customDomainValue string
@allowed(['CName', 'A'])
param dnsRecordType string = 'CName'

resource appService 'Microsoft.Web/sites@2025-03-01' existing = {
  name: appServiceName
}

resource customDomain 'Microsoft.Web/sites/hostNameBindings@2025-03-01' = {
  parent: appService
  name: customDomainValue
  properties: {
    hostNameType: 'Verified'
    customHostNameDnsRecordType: dnsRecordType
    siteName: appServiceName
    sslState: 'Disabled'
  }
}
