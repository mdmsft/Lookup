param name string

var connectionStrings = {
  Database: {
    type: 'SQLAzure'
    value: '@Microsoft.KeyVault(SecretUri=https://kv-${name}${environment().suffixes.keyvaultDns}/secrets/sqldb-connection-string/)'
  }
  Redis: {
    type: 'Custom'
    value: '@Microsoft.KeyVault(SecretUri=https://kv-${name}${environment().suffixes.keyvaultDns}/secrets/redis-connection-string/)'
  }
}

var appSettings = {
  'APPINSIGHTS_INSTRUMENTATIONKEY': '@Microsoft.KeyVault(SecretUri=https://kv-${name}${environment().suffixes.keyvaultDns}/secrets/appi-instrumentation-key/)'
}

resource linuxPlan 'Microsoft.Web/serverfarms@2021-01-01' = {
  name: 'plan-${name}-linux'
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

resource windowsPlan 'Microsoft.Web/serverfarms@2021-01-01' = {
  name: 'plan-${name}-windows'
  location: resourceGroup().location
  kind: 'windows'
  sku: {
    name: 'S1'
    tier: 'Standart'
  }
  properties: {
    reserved: false
  }
}

resource linuxApp 'Microsoft.Web/sites@2021-01-01' = {
  name: 'app-${name}-linux'
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    serverFarmId: linuxPlan.id
    httpsOnly: true
    reserved: true
    clientAffinityEnabled: false
    siteConfig: {
      alwaysOn: true
      ftpsState: 'Disabled'
      healthCheckPath: '/healthz'
      http20Enabled: true
      linuxFxVersion: 'DOTNETCORE|6.0'
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
}

resource windowsApp 'Microsoft.Web/sites@2021-01-01' = {
  name: 'app-${name}-windows'
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    serverFarmId: windowsPlan.id
    httpsOnly: true
    reserved: false
    clientAffinityEnabled: false
    siteConfig: {
      alwaysOn: true
      ftpsState: 'Disabled'
      healthCheckPath: '/healthz'
      http20Enabled: true
      netFrameworkVersion: 'v6.0'
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
}

output oids array = [
  linuxApp.identity.principalId
  windowsApp.identity.principalId
]

output ips array = union(split(linuxApp.properties.outboundIpAddresses, ','), split(windowsApp.properties.outboundIpAddresses, ','))
