// Reference deployment for Web App with Slots using Shared Plan
// Self-contained deployment for .NET 9.0 applications - single resource group scope
// Uses existing shared App Service Plan
// Example: az deployment group create --resource-group myapp-rg --template-file main.bicep --parameters envName=demo appName=testslots

targetScope = 'resourceGroup'

@description('Environment name')
param envName string

@description('Web app name')
param appName string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Operating system for the App Service Plan')
@allowed(['w', 'x'])
param operatingSystem string = 'x'

@description('Name of the existing shared App Service Plan')
param sharedPlanName string

@description('Resource group name where the shared App Service Plan exists')
param sharedPlanResourceGroup string

@description('Subscription ID where the shared App Service Plan exists')
param sharedPlanSubscriptionId string = subscription().subscriptionId

@description('Cost center code for tagging')
param costCenter string = 'CC-Demo'

@description('Deployment source for tagging')
param deploymentSource string = 'main.bicep'

@description('Favorite color for app settings')
param favoriteColor string = 'lightgreen'

// Standard tags
var standardTags = {
  CreatedBy: 'IaC'
  Environment: envName
  CostCenter: costCenter
  DeploymentSource: deploymentSource
  Template: 'main.bicep'
}

var webAppName = '${appName}-${uniqueString(resourceGroup().id)}'

// Reference to existing hosting plan in different resource group
resource existingHostingPlan 'Microsoft.Web/serverfarms@2024-04-01' existing = {
  name: sharedPlanName
  scope: resourceGroup(sharedPlanSubscriptionId, sharedPlanResourceGroup)
}

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${envName}-${appName}-log'
  location: location
  tags: standardTags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${envName}-${appName}-ain'
  location: location
  kind: 'web'
  tags: standardTags
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Web App
resource webApp 'Microsoft.Web/sites@2024-11-01' = {
  name: webAppName
  location: location
  kind: operatingSystem == 'w' ? 'app' : 'app,linux'
  tags: standardTags
  properties: {
    serverFarmId: existingHostingPlan.id
    reserved: operatingSystem == 'x' ? true : false
    httpsOnly: true
    siteConfig: {
      alwaysOn: true
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      http20Enabled: true
      linuxFxVersion: operatingSystem == 'x' ? 'DOTNETCORE|9.0' : null
      netFrameworkVersion: operatingSystem == 'w' ? 'v9.0' : null
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'EnvName'
          value: envName
        }
        {
          name: 'FavoriteColor'
          value: favoriteColor
        }
        {
          name: 'DeploymentType'
          value: 'Production-with-Slots'
        }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Production'
        }
      ]
    }
  }
}

// Staging Slot
resource stagingSlot 'Microsoft.Web/sites/slots@2024-11-01' = {
  parent: webApp
  name: 'staging'
  location: location
  kind: operatingSystem == 'w' ? 'app' : 'app,linux'
  tags: standardTags
  properties: {
    serverFarmId: existingHostingPlan.id
    reserved: operatingSystem == 'x' ? true : false
    httpsOnly: true
    siteConfig: {
      alwaysOn: true
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      http20Enabled: true
      linuxFxVersion: operatingSystem == 'x' ? 'DOTNETCORE|9.0' : null
      netFrameworkVersion: operatingSystem == 'w' ? 'v9.0' : null
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'EnvName'
          value: '${envName}-staging'
        }
        {
          name: 'FavoriteColor'
          value: 'Orange'
        }
        {
          name: 'SlotName'
          value: 'staging'
        }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Staging'
        }
      ]
    }
  }
}

// Slot Configuration Names (which settings are slot-specific)
resource slotConfigNames 'Microsoft.Web/sites/config@2024-11-01' = {
  parent: webApp
  name: 'slotConfigNames'
  properties: {
    appSettingNames: [
      'EnvName'
      'SlotName'
      'ASPNETCORE_ENVIRONMENT'
    ]
  }
}

// Outputs
output webAppName string = webApp.name
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output stagingSlotUrl string = 'https://${stagingSlot.properties.defaultHostName}'
output slots array = [
  {
    name: 'staging'
    url: 'https://${stagingSlot.properties.defaultHostName}'
  }
]
output sharedPlanId string = existingHostingPlan.id
output sharedPlanResourceGroup string = sharedPlanResourceGroup
output appInsightsConnectionString string = appInsights.properties.ConnectionString
output logAnalyticsWorkspaceId string = logAnalytics.id
