// Deploy Azure OpenAI, a KevVault and Azure Data explorer cluster (ADX , aka Kusto)

// Parameters
targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

param resourceGroupName string = ''


@description('Location for the OpenAI resource group')
@allowed(['canadaeast', 'eastus', 'francecentral', 'japaneast', 'northcentralus','westeruope'])
@metadata({
  azd: {
    type: 'location'
  }
})
param openAiResourceGroupLocation string

param openAiSkuName string = 'S0'


param chatGptDeploymentName string // Set in main.parameters.json
param chatGptDeploymentCapacity int = 30
param chatGptModelName string = 'gpt-35-turbo'
param chatGptModelVersion string = '0613'
param embeddingDeploymentName string = 'embedding'
param embeddingDeploymentCapacity int = 30
param embeddingModelName string = 'text-embedding-ada-002'

@description('Id of the user or app to assign application roles')
param principalId string = ''


// Variables

var abbrs = loadJsonContent('abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }



// Organize resources in a resource group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}



module keyVault './core/security/keyvault.bicep' = {
  name: 'keyvault'
  scope: resourceGroup
  params: {
    name: '${abbrs.keyVaultVaults}${resourceToken}'
    location: location
    tags: tags
    principalId: principalId
  }
}

// Give the API access to KeyVault
// module apiKeyVaultAccess './core/security/keyvault-access.bicep' = {
//   name: 'api-keyvault-access'
//   scope: resourceGroup
//   params: {
//     keyVaultName: keyVault.outputs.name
//     principalId: adxCluster.outputs.adxClusterIdentity
//   }
// }


// OpenAI services
module openAi 'core/ai/cognitiveservices.bicep' = {
  name: 'openai'
  scope: resourceGroup
  params: {
    name: '${abbrs.cognitiveServicesAccounts}${resourceToken}'
    location: openAiResourceGroupLocation
    tags: tags
    sku: {
      name: openAiSkuName
    }
    deployments: [
      {
        name: chatGptDeploymentName
        model: {
          format: 'OpenAI'
          name: chatGptModelName
          version: chatGptModelVersion
        }
        sku: {
          name: 'Standard'
          capacity: chatGptDeploymentCapacity
        }
      }
      {
        name: embeddingDeploymentName
        model: {
          format: 'OpenAI'
          name: embeddingModelName
          version: '2'
        }
        capacity: embeddingDeploymentCapacity
      }
    ]
  }
}

// Assing OpenAI role the the deploying user
module openAiRoleUser 'core/security/role.bicep' = {
   scope: resourceGroup
   name: 'openai-role-user'
   params: {
     principalId: principalId
     roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
     principalType: 'User'
   }
}

module CosmosDB 'core/storage/cosmosdb.bicep' = {
  name: 'cosmosdb'
  scope: resourceGroup
  params: {
    name: '${abbrs.documentDBDatabaseAccounts}${resourceToken}'
    location: location
    tags: tags
    principalId: principalId
  }
}

// // SYSTEM IDENTITIES
// module openAiRoleBackend 'core/security/role.bicep' = {
//   scope: resourceGroup
//   name: 'openai-role-backend'
//   params: {
//     principalId: adxCluster.outputs.adxClusterIdentity
//     roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
//     principalType: 'ServicePrincipal'
//   }
// }


output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = resourceGroup.name

output AZURE_OPENAI_SERVICE string = openAi.outputs.name
output AZURE_OPENAI_RESOURCE_GROUP string =resourceGroup.name
output AZURE_OPENAI_CHATGPT_DEPLOYMENT string = chatGptDeploymentName
output AZURE_OPENAI_CHATGPT_MODEL string = chatGptModelName
output AZURE_OPENAI_EMB_DEPLOYMENT string = embeddingDeploymentName
output AZURE_OPENAI_EMB_MODEL_NAME string = embeddingModelName
output COSMOS_ENDPOINT string = CosmosDB.outputs.cosmosendpoint
