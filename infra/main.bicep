targetScope = 'subscription'

@minLength(1)
@maxLength(20)
@description('Naam van de azd-omgeving, bijvoorbeeld dev')
param environmentName string

@description('Azure-regio voor alle resources')
param location string

@description('Object-ID van wie de Foundry User-rol krijgt; azd vult dit zelf in')
param principalId string

@description('Ophogen na een purge: Foundry kent een hergebruikte accountnaam urenlang niet terug (404 Project not found)')
param revision string = ''

@allowed(['User', 'ServicePrincipal'])
param principalType string = 'User'

@description('E-mailadres voor budgetwaarschuwingen; leeg = geen budget aanmaken')
param budgetContactEmail string = ''

@description('Maandbudget in de valuta van de subscription')
param budgetAmount int = 50

@description('Startdatum van het budget, altijd de eerste van een maand')
param budgetStartDate string = '2026-09-01'

var resourceToken = toLower(empty(revision)
  ? uniqueString(subscription().id, environmentName, location)
  : uniqueString(subscription().id, environmentName, location, revision))
var tags = { 'azd-env-name': environmentName }

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

resource budget 'Microsoft.Consumption/budgets@2024-08-01' = if (!empty(budgetContactEmail)) {
  name: 'budget-${environmentName}'
  properties: {
    category: 'Cost'
    amount: budgetAmount
    timeGrain: 'Monthly'
    timePeriod: { startDate: budgetStartDate }
    notifications: {
      actual50: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 50
        thresholdType: 'Actual'
        contactEmails: [budgetContactEmail]
      }
      actual80: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 80
        thresholdType: 'Actual'
        contactEmails: [budgetContactEmail]
      }
      forecast100: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 100
        thresholdType: 'Forecasted'
        contactEmails: [budgetContactEmail]
      }
    }
  }
}

module monitoring 'monitoring.bicep' = {
  scope: rg
  params: {
    name: resourceToken
    location: location
    tags: tags
  }
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
    principalId: principalId
    principalType: principalType
    appInsightsName: monitoring.outputs.appInsightsName
  }
}

output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_FOUNDRY_NAME string = foundry.outputs.name
output AZURE_FOUNDRY_ENDPOINT string = foundry.outputs.endpoint
output AZURE_AI_PROJECT_ENDPOINT string = foundry.outputs.projectEndpoint
output AZURE_AI_MODEL_DEPLOYMENT_NAME string = foundry.outputs.modelDeploymentName
output APPLICATIONINSIGHTS_NAME string = monitoring.outputs.appInsightsName
