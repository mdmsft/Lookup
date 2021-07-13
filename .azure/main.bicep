param project string = 'contoso'
param region object = {
  key: 'weu'
  name: 'west europe'
}

var name = '${project}-${region.key}'

param activeDirectorySid string = '6887230d-44bb-44a3-94b4-2b69c88d9724'
param activeDirectoryLogin string = 'dmmorozo@microsoft.com'
param sqlAdministratorLogin string = project

@secure()
param sqlAdministratorLoginPassword string

targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${project}-${region.key}'
  location: region.name
}

module log './log.bicep' = {
  scope: rg
  name: 'log-${deployment().name}'
  params: {
    name: name
  }
}

module redis './redis.bicep' = {
  scope: rg
  name: 'redis-${deployment().name}'
  params: {
    name: name
  }
}

module sql './sql.bicep' = {
  scope: rg
  name: 'sql-${deployment().name}'
  params: {
    name: name
    activeDirectorySid: activeDirectorySid
    administratorLogin: sqlAdministratorLogin
    activeDirectoryLogin: activeDirectoryLogin
    administratorLoginPassword: sqlAdministratorLoginPassword
    ips: web.outputs.ips
  }
}

module web './web.bicep' = {
  scope: rg
  name: 'web-${deployment().name}'
  params: {
    name: name
  }
}

module kv './kv.bicep' = {
  scope: rg
  name: 'kv-${deployment().name}'
  params: {
    name: name
    activeDirectorySid: activeDirectorySid
    oids: web.outputs.oids
    secrets: [
      {
        name: 'appi-instrumentation-key'
        value: log.outputs.instrumentationKey
      }
      {
        name: 'redis-connection-string'
        value: redis.outputs.connectionString
      }
      {
        name: 'sqldb-connection-string'
        value: sql.outputs.connectionString
      }
    ]
  }
}

