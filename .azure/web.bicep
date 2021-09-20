param image string
param virtualNetworkSubnetId string
param virtualNetworkId string
param sqlConnectionString string
param redisConnectionString string
param appInsightsInstrumentationKey string

var connectionStrings = {
  Database: {
    type: 'SQLAzure'
    value: sqlConnectionString
  }
  Redis: {
    type: 'Custom'
    value: redisConnectionString
  }
}

var appSettings = {
  'APPINSIGHTS_INSTRUMENTATIONKEY': appInsightsInstrumentationKey
}

resource plan 'Microsoft.Web/serverfarms@2021-01-01' = {
  name: 'plan-${resourceGroup().name}'
  location: resourceGroup().location
  kind: 'linux'
  sku: {
    name: 'S1'
    tier: 'Standart'
  }
  properties: {
    reserved: true
  }
}

resource site 'Microsoft.Web/sites@2021-01-01' = {
  name: 'app-${resourceGroup().name}'
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  kind: 'app,linux,container'
  properties: {
    enabled: true
    serverFarmId: plan.id
    httpsOnly: true
    reserved: true
    clientAffinityEnabled: false
    virtualNetworkSubnetId: virtualNetworkSubnetId
    siteConfig: {
      acrUseManagedIdentityCreds: true
      alwaysOn: true
      ftpsState: 'Disabled'
      healthCheckPath: '/healthz'
      http20Enabled: true
      linuxFxVersion: 'DOCKER|${image}'
      minTlsVersion: '1.2'
      numberOfWorkers: 1
      use32BitWorkerProcess: false
      webSocketsEnabled: false
    }
  }

  resource appsettings 'config' = {
    name: 'appsettings'
    properties: appSettings
  }

  resource connectionstrings 'config' = {
    name: 'connectionstrings'
    properties: connectionStrings
  }

  resource virtualNetworkConnection 'virtualNetworkConnections' = {
    name: 'default'
    properties: {
      vnetResourceId: virtualNetworkId
    }
  }
}

output oid string = site.identity.principalId

output ips array = split(site.properties.outboundIpAddresses, ',')
