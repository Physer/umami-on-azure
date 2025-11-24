param umamiAppServiceName string
param customDomainName string

module umamiCustomHostnameBinding 'modules/appServiceHostnameBinding.bicep' = {
  name: 'deployUmamiHostnameBinding'
  params: {
    appServiceName: umamiAppServiceName
    customDomainValue: customDomainName
  }
}

module umamiCustomDomain 'modules/appServiceCertificateBinding.bicep' = {
  name: 'deployUmamiCertificateBinding'
  params: {
    appServiceName: umamiAppServiceName
    customDomainValue: customDomainName
  }
  dependsOn: [
    umamiCustomHostnameBinding
  ]
}
