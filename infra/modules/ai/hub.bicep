metadata description = 'Creates the application frontend and backend container apps and dependencies.'
metadata author = 'AI GBB EMEA <eminkevich@microsoft.com>; <dobroegl@microsoft.com>'

/* -------------------------------------------------------------------------- */
/*                                 PARAMETERS                                 */
/* -------------------------------------------------------------------------- */

@description('The AI Studio Hub Resource name')
param name string

@description('The location to deploy the container app to')
param location string = resourceGroup().location

@description('The tags to apply to the container app')
param tags object = {}

@description('The display name of the AI Studio Hub Resource')
param displayName string = name

@description('The storage account ID to use for the AI Studio Hub Resource')
param storageAccountId string

@description('The key vault ID to use for the AI Studio Hub Resource')
param keyVaultId string

@description('The application insights ID to use for the AI Studio Hub Resource')
param applicationInsightsId string = ''

@description('The container registry ID to use for the AI Studio Hub Resource')
param containerRegistryId string = ''

@description('The OpenAI Cognitive Services account name to use for the AI Studio Hub Resource')
param openAiName string

@description('The Azure OpenAI service resource group name to use if different from current resource group')
param azureOpenAiResourceGroupName string = ''

@description('The OpenAI Cognitive Services account connection name to use for the AI Studio Hub Resource')
param openAiConnectionName string

@description('The Azure AI Search service name to use for the AI Studio Hub Resource')
param aiSearchName string = ''

@description('The Azure AI Search service resource group name to use if different from current resource group')
param azureAiSearchResourceGroupName string = ''

@description('The Azure AI Search service connection name to use for the AI Studio Hub Resource')
param aiSearchConnectionName string

@description('The SKU name to use for the AI Studio Hub Resource')
param skuName string = 'Basic'

@description('The SKU tier to use for the AI Studio Hub Resource')
@allowed(['Basic', 'Free', 'Premium', 'Standard'])
param skuTier string = 'Basic'

@description('The public network access setting to use for the AI Studio Hub Resource')
@allowed(['Enabled', 'Disabled'])
param publicNetworkAccess string = 'Enabled'

resource hub 'Microsoft.MachineLearningServices/workspaces@2024-01-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuTier
  }
  kind: 'Hub'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: displayName
    storageAccount: storageAccountId
    keyVault: keyVaultId
    applicationInsights: !empty(applicationInsightsId) ? applicationInsightsId : null
    containerRegistry: !empty(containerRegistryId) ? containerRegistryId : null
    hbiWorkspace: false
    managedNetwork: {
      isolationMode: 'Disabled'
    }
    v1LegacyMode: false
    publicNetworkAccess: publicNetworkAccess
  }

  resource openAiConnection 'connections' = {
    name: openAiConnectionName
    properties: {
      category: 'AzureOpenAI'
      authType: 'ApiKey'
      isSharedToAll: true
      target: openAi.properties.endpoints['OpenAI Language Model Instance API']
      metadata: {
        ApiVersion: '2023-07-01-preview'
        ApiType: 'azure'
        ResourceId: openAi.id
      }
      credentials: {
        key: openAi.listKeys().key1
      }
    }
  }

  resource searchConnection 'connections' = if (!empty(aiSearchName)) {
    name: aiSearchConnectionName
    properties: {
      category: 'CognitiveSearch'
      authType: 'ApiKey'
      isSharedToAll: true
      target: 'https://${search.name}.search.windows.net/'
      credentials: {
        key: !empty(aiSearchName) ? search.listAdminKeys().primaryKey : ''
      }
    }
  }
}

resource openAi 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  scope: resourceGroup(empty(azureOpenAiResourceGroupName) ? resourceGroup().name : azureOpenAiResourceGroupName)
  name: openAiName
}

resource search 'Microsoft.Search/searchServices@2021-04-01-preview' existing = if (!empty(aiSearchName)) {
  scope: resourceGroup(empty(azureAiSearchResourceGroupName) ? resourceGroup().name : azureAiSearchResourceGroupName)
  name: aiSearchName
}

/* -------------------------------------------------------------------------- */
/*                                   OUTPUTS                                  */
/* -------------------------------------------------------------------------- */

@description('The AI Studio Hub Resource name')
output name string = hub.name

@description('The AI Studio Hub Resource ID')
output resourceId string = hub.id

@description('The AI Studio Hub principal ID')
output principalId string = hub.identity.principalId

// Credits: heavily inspired by https://github.com/Azure-Samples/azd-aistudio-starter
