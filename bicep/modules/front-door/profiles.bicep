@description('The name of the Front Door profile to create. This must be globally unique.')
param name string

@description('The name of the SKU to use when creating the Front Door profile.')
@allowed([
  'Standard_AzureFrontDoor'
  'Premium_AzureFrontDoor'
])
param skuName string

@description('Optional. Specifies the send and receive timeout on forwarding request to the origin. When timeout is reached, the request fails and returns.')
param originResponseTimeoutSeconds int = 30

@description('Optional. Resource tags.')
param tags object = {}

resource profile 'Microsoft.Cdn/profiles@2022-11-01-preview' = {
  name: name
  location: 'global'
  sku: {
    name: skuName
  }
  identity: {
    type: 'SystemAssigned'
  }// identity
  tags: tags
  properties: {
    originResponseTimeoutSeconds: originResponseTimeoutSeconds
  }
}


@description('The name of the deployed Azure Front Door Profile.')
output name string = profile.name
@description('The resource Id of the deployed Azure Front Door Profile.')
output resourceId string = profile.id
