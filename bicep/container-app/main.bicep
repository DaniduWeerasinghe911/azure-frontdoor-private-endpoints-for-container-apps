// This template deploys a Container App with its associated environment and managed identity
// The deployment targets a subscription scope and creates a new resource group

targetScope = 'subscription'

@description('The name of the resource group where all resources will be deployed')
param rgName string

@description('The Azure region where all resources will be created')
param location string 

@description('The name of the Container Apps Environment to be created')
param environmentName string

@description('The name of the Container App instance to be created')
param appName string 

@description('The fully qualified container image name including registry, repository and tag')
param containerImageName string 

@description('Container registry configuration for private registries. Leave empty for public images')
param registryConfiguration object = {
  server: ''    // ACR server URL, e.g., 'myregistry.azurecr.io'
  username: ''  // ACR admin username if enabled
  password: ''  // ACR admin password or service principal secret
}

@description('Array of environment variables to be set in the container')
param envVariables array = [
  {
    name: 'OPENAI_API_KEY'
    value: 'test'
  }
]

// Additional environment variables can be defined here
var envVar = []

// Combine both static and dynamic environment variables
var allEnvVar = concat(envVariables, envVar)

@description('The resource ID of the subnet where the Container App will be deployed')
param vnetSubnetId string

// Create the resource group
resource rg 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  name: rgName
  location: location
}

// Deploy the Container App using the module
module containerApp '../modules/container-app/main.bicep' = {
  name: 'containerApp-deployment'
  scope: rg
  params: {
    vnetSubnetId: vnetSubnetId
    location: location
    environmentName: environmentName
    appName: appName
    containerConfig: {
      image: containerImageName
      name: appName
      env: allEnvVar
      resources: {
        cpu: '2.0'       // Allocated CPU cores
        memory: '4.0Gi'  // Allocated memory
      }
    }
    ingress: {
      external: false     // Internal ingress only
      targetPort: 8000    // Container port to expose
      allowInsecure: true // Allow HTTP traffic
    }
    registryConfiguration: registryConfiguration
    volumes: []
  }
}

