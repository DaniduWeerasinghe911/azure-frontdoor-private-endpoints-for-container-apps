//Deploy Front Door Premium

targetScope =  'subscription'

@description('Resource Group Name')
param rgName string = 'fdoor-rg'

@description('Resource Locations')
param location string = 'australiaeast'

@description('The name of the existing Front Door/CDN Profile.')
param profileName string = 'fdoor-dckloud'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rgName
  location: location
}

module profile '../modules/front-door/profiles.bicep' =  {
  scope: rg
  name: 'deploy_frontDoor_Profile'
  params: {
    name: profileName
    skuName: 'Premium_AzureFrontDoor'
  }
}
