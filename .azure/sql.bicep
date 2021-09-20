param administratorLogin string
param virtualNetworkSubnetId string

@secure()
param administratorLoginPassword string

resource server 'Microsoft.Sql/servers@2021-02-01-preview' = {
  name: 'sql-${resourceGroup().name}'
  location: resourceGroup().location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    minimalTlsVersion: '1.2'
  }
  resource database 'databases' = {
    name: 'sqldb-${resourceGroup().name}'
    location: resourceGroup().location
    sku: {
      name: 'S0'
      tier: 'Standard'
    }
  }
  resource virtualNetworkRule 'virtualNetworkRules' = {
    name: 'default'
    properties: {
      virtualNetworkSubnetId: virtualNetworkSubnetId
    }
  }
}

output connectionString string = 'Server=tcp:${server.name}${environment().suffixes.sqlServerHostname},1433;Initial Catalog=${server::database.name};Persist Security Info=False;User ID=${administratorLogin};Password=${administratorLoginPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
