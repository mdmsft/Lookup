param name string
param activeDirectorySid string
param secrets array
param oids array

var initialAccessPolicies = empty(activeDirectorySid) ? [] : [
  {
    tenantId: subscription().tenantId
    objectId: activeDirectorySid
    permissions: {
      certificates: [
        'backup'
        'create'
        'delete'
        'deleteissuers'
        'get'
        'getissuers'
        'import'
        'list'
        'listissuers'
        'managecontacts'
        'manageissuers'
        'purge'
        'recover'
        'restore'
        'setissuers'
        'update'
      ]
      keys: [
        'backup'
        'create'
        'decrypt'
        'delete'
        'encrypt'
        'get'
        'import'
        'list'
        'purge'
        'recover'
        'restore'
        'sign'
        'unwrapKey'
        'update'
        'verify'
        'wrapKey'
      ]
      secrets: [
        'backup'
        'delete'
        'get'
        'list'
        'purge'
        'recover'
        'restore'
        'set'
      ]
    }
  }
]

resource kv 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: 'kv-${name}'
  location: resourceGroup().location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: initialAccessPolicies
    enableSoftDelete: false
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      ipRules: []
      virtualNetworkRules: []
    }
    softDeleteRetentionInDays: 7
  }
}

resource accessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2021-04-01-preview' = {
  name: any('${kv.name}/add')
  properties: {
    accessPolicies: [for oid in oids: {
      tenantId: subscription().tenantId
      objectId: oid
      permissions: {
        secrets: [
          'get'
        ]
      }
    }]
  }
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = [for secret in secrets: {
  name: '${kv.name}/${secret.name}'
  properties: {
    value: secret.value
  }
}]

output name string = kv.name
