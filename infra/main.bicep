// Main Bicep orchestration file for devShop application
// Deploys two-tier architecture: IIS Web VM + SQL Server VM

targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment (used for resource naming)')
param environmentName string

@minLength(1)
@description('Primary Azure region for all resources')
param location string

@secure()
@description('SQL Server administrator username')
param sqlAdminUsername string

@secure()
@description('SQL Server administrator password')
param sqlAdminPassword string

@secure()
@description('Web VM administrator username')
param webVmAdminUsername string

@secure()
@description('Web VM administrator password')
param webVmAdminPassword string

@description('VM size for SQL Server')
param sqlVmSize string = 'Standard_B4ms'

@description('VM size for Web Server')
param webVmSize string = 'Standard_B2ms'

@description('Current UTC timestamp for unique resource naming')
param deploymentUtcNow string = utcNow()

@description('Public IP address allowed for RDP access (leave empty to allow from anywhere)')
param myIp string = ''

// Generate unique resource token for naming
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location, deploymentUtcNow))
var tags = {
  'azd-env-name': environmentName
  Application: 'devShop'
  Environment: environmentName
}

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

// Network infrastructure (VNet, Subnets, NSGs)
module network 'network.bicep' = {
  name: 'network-${resourceToken}'
  scope: rg
  params: {
    environmentName: environmentName
    location: location
    tags: tags
    allowedRdpSourceIp: myIp
  }
}

// SQL Server VM with pre-installed SQL Server 2022
module sqlServer 'sqlvm.bicep' = {
  name: 'sqlserver-${resourceToken}'
  scope: rg
  params: {
    environmentName: environmentName
    location: location
    subnetId: network.outputs.dbSubnetId
    adminUsername: sqlAdminUsername
    adminPassword: sqlAdminPassword
    vmSize: sqlVmSize
    tags: tags
  }
}

// Web Server VM with IIS
module webServer 'webvm.bicep' = {
  name: 'webserver-${resourceToken}'
  scope: rg
  params: {
    environmentName: environmentName
    location: location
    subnetId: network.outputs.webSubnetId
    adminUsername: webVmAdminUsername
    adminPassword: webVmAdminPassword
    sqlServerPrivateIp: sqlServer.outputs.privateIp
    sqlAdminUsername: sqlAdminUsername
    sqlAdminPassword: sqlAdminPassword
    vmSize: webVmSize
    tags: tags
  }
}

// Outputs for azd environment variables and user reference
output AZURE_LOCATION string = location
output AZURE_RESOURCE_GROUP string = rg.name

// SQL Server outputs
output SQL_SERVER_NAME string = sqlServer.outputs.vmName
output SQL_SERVER_PRIVATE_IP string = sqlServer.outputs.privateIp
output SQL_SERVER_PUBLIC_IP string = sqlServer.outputs.publicIp
output SQL_SERVER_FQDN string = sqlServer.outputs.fqdn
output SQL_ADMIN_USERNAME string = sqlAdminUsername

// Web Server outputs
output WEB_SERVER_NAME string = webServer.outputs.vmName
output WEB_SERVER_PRIVATE_IP string = webServer.outputs.privateIp
output WEB_SERVER_PUBLIC_IP string = webServer.outputs.publicIp
output WEB_SERVER_FQDN string = webServer.outputs.fqdn
output WEB_URL string = webServer.outputs.webUrl

// Storage account for deployment scripts
output STORAGE_ACCOUNT_NAME string = webServer.outputs.storageAccountName
output SCRIPTS_CONTAINER_NAME string = webServer.outputs.scriptsContainerName

// Network outputs
output VNET_NAME string = network.outputs.vnetName
output VNET_ID string = network.outputs.vnetId

// Connection string for application (stored in azd environment)
output CONNECTION_STRING string = 'Server=${sqlServer.outputs.privateIp};Database=devShopDB;User Id=${sqlAdminUsername};Password=${sqlAdminPassword};TrustServerCertificate=True;'
