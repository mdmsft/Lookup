param app string
param image string

resource site 'Microsoft.Web/sites@2021-01-01' existing = {
  name: app
}

resource config 'Microsoft.Web/sites/config@2021-01-15' = {
  name: 'web'
  parent: site
  properties: {
    linuxFxVersion: 'DOCKER|${image}'
  }
}
