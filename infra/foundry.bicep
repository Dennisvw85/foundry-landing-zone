param name string
param location string
param tags object
param projectName string
param modelName string
param modelVersion string
param modelCapacity int
param principalId string
param principalType string
param appInsightsName string

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

resource project 'Microsoft.CognitiveServices/accounts/projects@2026-07-01' = {
  parent: foundry
  name: projectName
  location: location
  tags: tags
  identity: { type: 'SystemAssigned' }
  properties: {
    displayName: projectName
    description: 'Oefenproject voor AI-103'
  }
}

resource model 'Microsoft.CognitiveServices/accounts/deployments@2026-07-01' = {
  parent: foundry
  name: modelName
  sku: {
    name: 'GlobalStandard'
    capacity: modelCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: modelName
      version: modelVersion
    }
    versionUpgradeOption: 'NoAutoUpgrade'
  }
  dependsOn: [
    project
  ]
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource appInsightsConnection 'Microsoft.CognitiveServices/accounts/projects/connections@2026-07-01' = {
  parent: project
  name: 'appi-connection'
  properties: {
    category: 'AppInsights'
    target: appInsights.id
    authType: 'ApiKey'
    isSharedToAll: true
    credentials: {
      key: appInsights.properties.ConnectionString
    }
    metadata: {
      ApiType: 'Azure'
      ResourceId: appInsights.id
    }
  }
}

var foundryUserRoleId = '53ca6127-db72-4b80-b1b0-d745d6d5456d'

resource foundryUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: foundry
  name: guid(foundry.id, principalId, foundryUserRoleId)
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', foundryUserRoleId)
  }
}

output name string = foundry.name
output endpoint string = foundry.properties.endpoint
output projectEndpoint string = project.properties.endpoints['AI Foundry API']
output modelDeploymentName string = model.name
