param name string

resource log 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: 'log-${name}'
  location: resourceGroup().location
}

resource appi 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: 'appi-${name}'
  location: resourceGroup().location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: log.id
  }
}

output instrumentationKey string = appi.properties.InstrumentationKey
