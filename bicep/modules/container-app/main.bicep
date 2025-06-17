@description('The name of the Container Apps Environment')
param environmentName string

@description('The name of the Container App to be created')
param appName string

@description('The Azure region where all resources should be created')
param location string = resourceGroup().location

@description('Configuration for the container including name, env variables, resources, and volume mounts')
param containerConfig object

@description('Array of volume definitions to be mounted to the container')
param volumes array

@description('Ingress configuration for the container app')
param ingress object

@description('Container registry configuration. Leave empty for public container images')
param registryConfiguration object

@description('The resource ID of the subnet where the Container App will be deployed')
param vnetSubnetId string

@description('Name of the managed identity. Defaults to {appName}-identity')
param identityName string = '${appName}-identity'


resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

resource environment 'Microsoft.App/managedEnvironments@2024-08-02-preview' = {
  name: environmentName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    workloadProfiles: [
      {
        workloadProfileType: 'Consumption'
        name: 'Consumption'
      }
    ]
    publicNetworkAccess: 'Disabled'
    vnetConfiguration: {
      internal:true
      infrastructureSubnetId: vnetSubnetId
    }
  }
}

// https://github.com/Azure/azure-rest-api-specs/blob/Microsoft.App-2022-01-01-preview/specification/app/resource-manager/Microsoft.App/preview/2022-01-01-preview/ContainerApps.json
resource containerApp 'Microsoft.App/containerApps@2024-08-02-preview' = {
  name: appName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: environment.id
    configuration: {
      ingress: ingress

      registries: !empty(registryConfiguration.server)
        ? [
            {
              identity: managedIdentity.id
              server: registryConfiguration.server
            }
          ]
        : []
      dapr: {
        enabled: false
      }
    }
    template: {
      containers: [
        {
          image: 'docker.io/hello-world:latest'
          name: containerConfig.name
          env: containerConfig.env
          resources: containerConfig.resources
          volumeMounts: containerConfig.volumeMounts
        }
      ]
      volumes: volumes
    }
  }
}

output location string = location
output environmentId string = environment.id
