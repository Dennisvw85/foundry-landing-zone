// Eenmalige bootstrap voor GitHub Actions: een managed identity die via OIDC mag inloggen.
// Staat bewust los van main.bicep, zodat `azd down` de CI/CD-identiteit niet weggooit.
//
// Uitrollen (eenmalig, lokaal):
//   az deployment sub create -l swedencentral -f infra/bootstrap/cicd.bicep \
//     -p githubOwner=<owner> githubRepo=<repo>
targetScope = 'subscription'

param location string = 'swedencentral'

@description('GitHub-gebruiker of -organisatie die de repo bezit')
param githubOwner string

@description('Naam van de GitHub-repo')
param githubRepo string

@description('GitHub-environment waaruit gedeployd mag worden')
param githubEnvironment string = 'dev'

var contributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var rbacAdminRoleId = 'f58310d9-a9f6-439a-9e8d-f62e7b41a168'
var foundryUserRoleId = '53ca6127-db72-4b80-b1b0-d745d6d5456d'

// De identiteit mag rollen toewijzen en verwijderen, maar alleen de Foundry User-rol.
var onlyFoundryUser = '((!(ActionMatches{\'Microsoft.Authorization/roleAssignments/write\'})) OR (@Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${foundryUserRoleId}})) AND ((!(ActionMatches{\'Microsoft.Authorization/roleAssignments/delete\'})) OR (@Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${foundryUserRoleId}}))'

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-cicd'
  location: location
}

module identity 'identity.bicep' = {
  scope: rg
  params: {
    name: 'id-gh-${githubRepo}'
    location: location
    subject: 'repo:${githubOwner}/${githubRepo}:environment:${githubEnvironment}'
  }
}

resource contributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, 'id-gh-${githubRepo}', contributorRoleId)
  properties: {
    principalId: identity.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleId)
  }
}

resource rbacAdmin 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, 'id-gh-${githubRepo}', rbacAdminRoleId)
  properties: {
    principalId: identity.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', rbacAdminRoleId)
    condition: onlyFoundryUser
    conditionVersion: '2.0'
  }
}

output AZURE_CLIENT_ID string = identity.outputs.clientId
