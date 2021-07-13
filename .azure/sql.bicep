param name string
param administratorLogin string
param activeDirectorySid string
param activeDirectoryLogin string
param ips array

@secure()
param administratorLoginPassword string

resource sql 'Microsoft.Sql/servers@2021-02-01-preview' = {
  name: 'sql-${name}'
  location: resourceGroup().location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    minimalTlsVersion: '1.2'
    administrators: {
      administratorType: 'ActiveDirectory'
      principalType: 'User'
      sid: activeDirectorySid
      login: activeDirectoryLogin
      tenantId: subscription().tenantId
    }
  }
  resource firewallRules 'firewallRules' = [for ip in ips: {
    name: ip
    properties: {
      startIpAddress: ip
      endIpAddress: ip
    }
  }]
}

resource sqldb 'Microsoft.Sql/servers/databases@2021-02-01-preview' = {
  name: 'sqldb-${name}'
  location: resourceGroup().location
  parent: sql
  sku: {
    name: 'S0'
    tier: 'Standard'
  }
}

output connectionString string = 'Server=tcp:${sql.name}${environment().suffixes.sqlServerHostname},1433;Initial Catalog=${sqldb.name};Persist Security Info=False;User ID=${administratorLogin};Password=${administratorLoginPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
