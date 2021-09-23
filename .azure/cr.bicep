param principals array

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: 'cr${resourceGroup().name}'
  location: resourceGroup().location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: false
    anonymousPullEnabled: true
    publicNetworkAccess: 'Enabled'
  }
}

var acrPull = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

resource rbac 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = [for principal in principals: {
  name: guid(containerRegistry.id, principal, acrPull)
  scope: containerRegistry
  properties: {
    principalId: principal
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPull)
  }
}]


output name string = containerRegistry.name
