param name string = 'lookup'
param version string = '1.0.0'
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
    identityPrincipalId: id.properties.principalId
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

var image = '${cr.outputs.name}${environment().suffixes.acrLoginServer}/${name}:${version}'

module web './web.bicep' = {
  name: 'web-${deployment().name}'
  params: {
    managedIdentityId: id.id
    virtualNetworkId: vnet.outputs.id
    virtualNetworkSubnetId: vnet.outputs.subnetId
    image: image
    appInsightsInstrumentationKey: log.outputs.instrumentationKey
    redisConnectionString: redis.outputs.connectionString
    sqlConnectionString: sql.outputs.connectionString
  }
}

output registryName string = cr.outputs.name
output imageName string = image
