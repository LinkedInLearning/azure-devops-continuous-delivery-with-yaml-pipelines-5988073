using 'myYaml-Slots.bicep'

// Core application parameters
param envName = 'lil'
param appName = 'myYAML-dev'
param operatingSystem = 'x' // 'x' for Linux/.NET Core, 'w' for Windows/.NET Framework

// Shared infrastructure parameters
param sharedPlanName = 'lil-shared-linux-plan'
param sharedPlanResourceGroup = 'lil-shared-rg'


