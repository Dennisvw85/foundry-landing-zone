param name string
param location string
param tags object

resource foundry 'Microsoft.CognitiveServices/accounts@2026-07-01' = {
  name: name
  location: location
  tags: tags
  kind: 'AIServices'
  sku: { name: 'S0' }
  identity: { type: 'SystemAssigned' }
  properties: {
    allowProjectManagement: true
    customSubDomainName: name
    disableLocalAuth: true
    publicNetworkAccess: 'Enabled'
  }
}

output name string = foundry.name
output endpoint string = foundry.properties.endpoint
