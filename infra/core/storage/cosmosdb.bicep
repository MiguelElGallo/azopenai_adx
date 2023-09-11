@description('Friendly name for the SQL Role Definition')
param roleDefinitionName string = 'My Read Write Role'

@description('Data actions permitted by the Role Definition')
param dataActions array = [
  'Microsoft.DocumentDB/databaseAccounts/readMetadata'
  'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*'
  'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/executeQuery'
]

@description('Object ID of the AAD identity. Must be a GUID.')
param principalId string

@description('Cosmos DB account name')
param name string

param tags object = {}

@description('Location for the Cosmos DB account.')
param location string 

@description('The name for the database')
param databaseName string = 'database1'

@description('The name for the container')
param containerName string = 'container1'

@description('The partition key for the container')
param partitionKeyPath string = '/partitionKey'

@description('The throughput policy for the container')
@allowed([
  'Manual'
  'Autoscale'
])
param throughputPolicy string = 'Manual'

@description('Throughput value when using Manual Throughput Policy for the container')
@minValue(400)
@maxValue(1000000)
param manualProvisionedThroughput int = 400

@description('Maximum throughput when using Autoscale Throughput Policy for the container')
@minValue(4000)
@maxValue(1000000)
param autoscaleMaxThroughput int = 4000

@description('Time to Live for data in analytical store. (-1 no expiry)')
@minValue(-1)
@maxValue(2147483647)


param analyticalStoreTTL int = -1
var accountName = name 
var locations = [
  {
    locationName: location
    failoverPriority: 0
    isZoneRedundant: false
  }
]
var throughput_Policy = {
  Manual: {
    Throughput: manualProvisionedThroughput
  }
  Autoscale: {
    autoscaleSettings: {
      maxThroughput: autoscaleMaxThroughput
    }
  }
}


var roleDefinitionId = guid('sql-role-definition-', principalId, databaseAccount.id)
var roleAssignmentId = guid(roleDefinitionId, principalId, databaseAccount.id)

resource databaseAccount 'Microsoft.DocumentDB/databaseAccounts@2021-04-15' = {
  name: accountName
  location: location
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    databaseAccountOfferType: 'Standard'
    locations: locations
    enableAnalyticalStorage: false
  }
}

resource sqlDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-04-15' = {
  parent: databaseAccount
  name: databaseName
  properties: {
    resource: {
      id: databaseName
    }
  }
}

resource sqlContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-04-15' = {
  parent: sqlDatabase
  name: containerName
  properties: {
    resource: {
      id: containerName
      partitionKey: {
        paths: [
          partitionKeyPath
        ]
        kind: 'Hash'
      }
    }
    }
}

resource sqlRoleDefinition 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2021-04-15' = {
  parent: databaseAccount
  name: roleDefinitionId
  properties: {
    roleName: roleDefinitionName
    type: 'CustomRole'
    assignableScopes: [
      databaseAccount.id
    ]
    permissions: [
      {
        dataActions: dataActions
      }
    ]
  }
}

resource sqlRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2021-04-15' = {
  parent: databaseAccount
  name: roleAssignmentId
  properties: {
    roleDefinitionId: sqlRoleDefinition.id
    principalId: principalId
    scope: databaseAccount.id
  }
}

output cosmosendpoint string = databaseAccount.properties.documentEndpoint
