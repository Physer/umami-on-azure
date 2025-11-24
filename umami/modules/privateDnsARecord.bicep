param privateDnsZoneFqdn string
param networkInterfaceName string
param dnsRecordName string

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: privateDnsZoneFqdn
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2024-07-01' existing = {
  name: networkInterfaceName
}

resource recordSet 'Microsoft.Network/privateDnsZones/A@2024-06-01' = {
  parent: privateDnsZone
  name: dnsRecordName
  properties: {
    ttl: 300
    aRecords: [
      {
        ipv4Address: networkInterface.properties.ipConfigurations[0].properties.privateIPAddress
      }
    ]
  }
}
