using './main.bicep'

param environmentName = readEnvironmentVariable('AZURE_ENV_NAME') 
param location = readEnvironmentVariable('AZURE_LOCATION')
param resourceGroupName = ''
param openAiResourceGroupLocation = readEnvironmentVariable('AZURE_LOCATION')
param openAiSkuName = 'S0'
param chatGptDeploymentName = 'gpt-35-turbo-dep'
param chatGptDeploymentCapacity = 30
param chatGptModelName = 'gpt-35-turbo'
param chatGptModelVersion = '0613'
param embeddingDeploymentName = 'text-embedding-ada-002-dep'
param embeddingDeploymentCapacity = 30
param embeddingModelName = 'text-embedding-ada-002'
param principalId = ''

