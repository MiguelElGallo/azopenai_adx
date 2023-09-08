using './main.bicep'

param environmentName = readEnvironmentVariable('AZURE_ENV_NAME') 
param location = readEnvironmentVariable('AZURE_LOCATION')
param resourceGroupName = ''
param adxSKU = 'Standard_D13_v2'
param keyVaultName = 'keyvaultadxai'
param openAiServiceName = ''
param openAiResourceGroupLocation = readEnvironmentVariable('AZURE_LOCATION')
param openAiSkuName = 'S0'
param chatGptDeploymentName = ''
param chatGptDeploymentCapacity = 30
param chatGptModelName = 'gpt-35-turbo'
param chatGptModelVersion = '0613'
param embeddingDeploymentName = ''
param embeddingDeploymentCapacity = 30
param embeddingModelName = 'text-embedding-ada-002'
param principalId = ''

