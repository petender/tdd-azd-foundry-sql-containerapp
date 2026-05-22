using './main.bicep'

param environment        = readEnvironmentVariable('AZURE_ENV_NAME', 'demo')
param location           = readEnvironmentVariable('AZURE_LOCATION', 'eastus2')
param principalId        = readEnvironmentVariable('AZURE_PRINCIPAL_ID', '')
param projectName        = 'fsc'
param aiFoundryLocation  = 'swedencentral'
param containerImage     = readEnvironmentVariable('SERVICE_WEB_IMAGE_NAME', 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest')
