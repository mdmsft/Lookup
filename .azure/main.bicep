param name string = 'lookup'
param version string = '1.0.0'
param sqlAdministratorLogin string = name

@secure()
param sqlAdministratorLoginPassword string

module vnet 'vnet.bicep' = {
  name: 'vnet-${deployment().name}'
}

module log './log.bicep' = {
  name: 'log-${deployment().name}'
}

module cr './cr.bicep' = {
  name: 'cr-${deployment().name}'
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
    virtualNetworkId: vnet.outputs.id
    virtualNetworkSubnetId: vnet.outputs.subnetId
    image: image
    appInsightsInstrumentationKey: log.outputs.instrumentationKey
    redisConnectionString: redis.outputs.connectionString
    sqlConnectionString: sql.outputs.connectionString
  }
}

module rbac 'rbac.bicep' = {
  name: 'rbac-${deployment().name}'
  params: {
    appServicePrincipalId: web.outputs.oid
    containerRegistryName: cr.outputs.name
  }
}

output registryName string = cr.outputs.name
output imageName string = image
