// Web Server VM with IIS for ASP.NET application
// Configured with Custom Script Extension for automatic setup

@description('Environment name for resource naming')
param environmentName string

@description('Azure region for resources')
param location string = resourceGroup().location

@description('Web subnet ID')
param subnetId string

@description('Web VM administrator username')
@secure()
param adminUsername string

@description('Web VM administrator password')
@secure()
param adminPassword string

@description('SQL Server private IP address')
param sqlServerPrivateIp string

@description('SQL Server admin username')
@secure()
param sqlAdminUsername string

@description('SQL Server admin password')
@secure()
param sqlAdminPassword string

@description('Tags to apply to all resources')
param tags object = {}

@description('VM size for Web Server')
param vmSize string = 'Standard_B2ms'

// Variables
var vmName = 'vm-web-${environmentName}'
var nicName = 'nic-web-${environmentName}'
var publicIpName = 'pip-web-${environmentName}'
var osDiskName = '${vmName}-osdisk'

// Public IP for Web Server VM
resource publicIp 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: publicIpName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: toLower('${vmName}-${uniqueString(resourceGroup().id)}')
    }
  }
}

// Network Interface for Web Server VM
resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: nicName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}

// Windows Server VM for IIS
resource webVm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  tags: union(tags, {
    'azd-service-name': 'web'
  })
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        name: osDiskName
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        caching: 'ReadWrite'
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'AutomaticByPlatform'
          assessmentMode: 'ImageDefault'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

// Custom Script Extension to install IIS and configure the web server
resource webSetupScript 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  name: 'SetupIIS'
  parent: webVm
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File setup-iis.ps1 "${sqlServerPrivateIp}" "${sqlAdminUsername}" "${sqlAdminPassword}"'
      fileUris: [
        '${storageAccount.properties.primaryEndpoints.blob}scripts/setup-iis.ps1${storageAccount.listAccountSas(storageAccount.apiVersion, sasProperties).accountSasToken}'
      ]
    }
  }
}

// Storage Account for deployment scripts
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'st${uniqueString(resourceGroup().id, environmentName)}'
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

// Blob container for scripts
resource scriptsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  name: '${storageAccount.name}/default/scripts'
  properties: {
    publicAccess: 'None'
  }
}

// SAS token properties for secure script download
var sasProperties = {
  signedServices: 'b'
  signedPermission: 'r'
  signedExpiry: dateTimeAdd(utcNow(), 'PT2H')
  signedResourceTypes: 'o'
  signedProtocol: 'https'
}

// Auto-shutdown schedule - shutdown at 7:00 PM daily
resource webVmShutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${vmName}'
  location: location
  tags: tags
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: '1900'  // 7:00 PM (19:00 in 24-hour format)
    }
    timeZoneId: 'UTC'
    notificationSettings: {
      status: 'Disabled'
    }
    targetResourceId: webVm.id
  }
}

// Outputs
output vmId string = webVm.id
output vmName string = webVm.name
output privateIp string = nic.properties.ipConfigurations[0].properties.privateIPAddress
output publicIp string = publicIp.properties.ipAddress
output fqdn string = publicIp.properties.dnsSettings.fqdn
output webUrl string = 'http://${publicIp.properties.dnsSettings.fqdn}'
output storageAccountName string = storageAccount.name
output scriptsContainerName string = 'scripts'
