using './main.bicep'

// Resource Group Name for Container App deployment
@description('The name of the resource group where the Container App will be deployed')
param rgName = 'abc-prod-aue-aic-rg'

@description('The Azure region where all resources will be created')
param location = 'australiaeast'

@description('The name of the Container Apps Environment to be created or used')
param environmentName = 'abc-prod-aue-aic-env'

@description('The name of the Container App to be created')
param appName = 'abc-prod-aue-aic-capp'

@description('The fully qualified container image name including registry, repository and tag')
param containerImageName = 'abcprodaueacr.azurecr.io/xyz-image:1.0.0'

@description('Azure Container Registry configuration including server, username and password')
param registryConfiguration = {
  server: 'abcprodaueacr.azurecr.io'
  username: 'abcprodaueacr'
  // TODO: Replace with a secure method like Key Vault reference or pipeline variable
  password: 'your-password-here' // Replace with the actual password or use a secure method to pass it
}

@description('The resource ID of the subnet where the Container App will be deployed')
param vnetSubnetId = '/subscriptions/xxxx-xxxx-xxxx-xxxx-xxxxxx/resourceGroups/abc-prod-aue-network-rg/providers/Microsoft.Network/virtualNetworks/abc-prod-aue-vnet/subnets/prod-aue-aic-snet'
