resource redis 'Microsoft.Cache/redis@2020-12-01' = {
  name: 'redis-${resourceGroup().name}'
  location: resourceGroup().location
  properties: {
    sku: {
      capacity: 0
      family: 'C'
      name: 'Standard'
    }
  }
}

output connectionString string = '${redis.properties.hostName}:${redis.properties.enableNonSslPort ? redis.properties.port : redis.properties.sslPort},password=${redis.listKeys().primaryKey},ssl=${redis.properties.enableNonSslPort ? 'False' : 'True'},abortConnect=False'

