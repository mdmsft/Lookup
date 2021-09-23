param name string = 'lookup'
param sqlAdministratorLogin string = name

@secure()
param sqlAdministratorLoginPassword string

resource id 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'id-${resourceGroup().name}'
  location: resourceGroup().location
}

module vnet 'vnet.bicep' = {
  name: 'vnet-${deployment().name}'
}

module log './log.bicep' = {
  name: 'log-${deployment().name}'
}

module cr './cr.bicep' = {
  name: 'cr-${deployment().name}'
  params: {
    principals: [
      id.properties.principalId
      web.outputs.principalId
    ]
  }
}

module redis './redis.bicep' = {
  name: 'redis-${deployment().name}'
}

module sql './sql.bicep' = {
  name: 'sql-${deployment().name}'
  params: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorLoginPassword
    virtualNetworkSubnetId: vnet.outputs.subnetId
  }
}

module web './web.bicep' = {
  name: 'web-${deployment().name}'
  params: {
    virtualNetworkSubnetId: vnet.outputs.subnetId
    managedIdentity: {
      id: id.id
      clientId: id.properties.clientId
    }
    appInsightsInstrumentationKey: log.outputs.instrumentationKey
    redisConnectionString: redis.outputs.connectionString
    sqlConnectionString: sql.outputs.connectionString
  }
}

output registryName string = cr.outputs.name
output imageName string = '${cr.outputs.name}${environment().suffixes.acrLoginServer}/${name}'
output siteName string = web.outputs.name
