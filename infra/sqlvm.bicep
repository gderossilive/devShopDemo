// SQL Server VM with pre-installed SQL Server 2022
// Uses Azure Marketplace image with SQL Server already configured

@description('Environment name for resource naming')
param environmentName string

@description('Azure region for resources')
param location string = resourceGroup().location

@description('Database subnet ID')
param subnetId string

@description('SQL Server administrator username')
@secure()
param adminUsername string

@description('SQL Server administrator password')
@secure()
param adminPassword string

@description('Tags to apply to all resources')
param tags object = {}

@description('VM size for SQL Server')
param vmSize string = 'Standard_B4ms'

// Variables
var vmName = 'vm-sql-${environmentName}'
var nicName = 'nic-sql-${environmentName}'
var publicIpName = 'pip-sql-${environmentName}'
var osDiskName = '${vmName}-osdisk'
var dataDiskName = '${vmName}-datadisk'

// Public IP for SQL Server VM (for management access)
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

// Network Interface for SQL Server VM
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

// SQL Server 2022 on Windows Server VM
// Using marketplace image with SQL Server pre-installed
resource sqlVm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  tags: union(tags, {
    'azd-service-name': 'sqlserver'
  })
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftSQLServer'
        offer: 'sql2022-ws2022'
        sku: 'sqldev-gen2'  // SQL Server 2022 Developer Edition on Windows Server 2022
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
      dataDisks: [
        {
          name: dataDiskName
          createOption: 'Empty'
          diskSizeGB: 128
          lun: 0
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
          caching: 'ReadOnly'
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: false
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'Manual'
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

// SQL IaaS Extension for advanced SQL Server management
resource sqlIaasExtension 'Microsoft.SqlVirtualMachine/sqlVirtualMachines@2023-10-01' = {
  name: vmName
  location: location
  tags: tags
  properties: {
    virtualMachineResourceId: sqlVm.id
    sqlServerLicenseType: 'PAYG'  // Pay-as-you-go (or 'AHUB' for Azure Hybrid Benefit)
    sqlManagement: 'Full'
    sqlImageSku: 'Developer'
    storageConfigurationSettings: {
      diskConfigurationType: 'NEW'
      storageWorkloadType: 'GENERAL'
      sqlDataSettings: {
        luns: [0]
        defaultFilePath: 'F:\\SQLData'
      }
      sqlLogSettings: {
        luns: [0]
        defaultFilePath: 'F:\\SQLLog'
      }
      sqlTempDbSettings: {
        luns: [0]
        defaultFilePath: 'F:\\SQLTemp'
      }
    }
    serverConfigurationsManagementSettings: {
      sqlConnectivityUpdateSettings: {
        connectivityType: 'PRIVATE'  // Private network only
        port: 1433
        sqlAuthUpdateUserName: adminUsername
        sqlAuthUpdatePassword: adminPassword
      }
      additionalFeaturesServerConfigurations: {
        isRServicesEnabled: false
      }
    }
  }
}

// Custom Script Extension to configure SQL Server database
resource sqlSetupScript 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  name: 'SetupSQLDatabase'
  parent: sqlVm
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -Command "Write-Host \'SQL Server VM configured. Database setup will be performed by post-provision hook.\'"'
    }
  }
  dependsOn: [
    sqlIaasExtension
  ]
}

// Auto-shutdown schedule - shutdown at 7:00 PM daily
resource sqlVmShutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = {
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
    targetResourceId: sqlVm.id
  }
}

// Outputs
output vmId string = sqlVm.id
output vmName string = sqlVm.name
output privateIp string = nic.properties.ipConfigurations[0].properties.privateIPAddress
output publicIp string = publicIp.properties.ipAddress
output fqdn string = publicIp.properties.dnsSettings.fqdn
output sqlServerName string = vmName
output sqlAdminUsername string = adminUsername
