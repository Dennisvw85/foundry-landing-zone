targetScope = 'subscription'

@minLength(1)
@maxLength(20)
@description('Naam van de azd-omgeving, bijvoorbeeld dev')
param environmentName string

@description('Azure-regio voor alle resources')
param location string

var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

module foundry 'foundry.bicep' = {
  scope: rg
  params: {
    name: 'fdy-${resourceToken}'
    location: location
    tags: tags
    projectName: 'proj-${environmentName}'
    modelName: 'gpt-4.1-mini'
    modelVersion: '2025-04-14'
    modelCapacity: 30
  }
}

output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_FOUNDRY_NAME string = foundry.outputs.name
output AZURE_FOUNDRY_ENDPOINT string = foundry.outputs.endpoint
output AZURE_AI_PROJECT_ENDPOINT string = foundry.outputs.projectEndpoint
output AZURE_AI_MODEL_DEPLOYMENT_NAME string = foundry.outputs.modelDeploymentName
