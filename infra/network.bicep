// Network infrastructure for devShop application
// Creates VNet with separate subnets for web and database tiers

@description('Environment name for resource naming')
param environmentName string

@description('Azure region for resources')
param location string = resourceGroup().location

@description('Tags to apply to all resources')
param tags object = {}

@description('Public IP address allowed for RDP access (empty string = allow from anywhere)')
param allowedRdpSourceIp string = ''

// Network configuration
var vnetName = 'vnet-${environmentName}'
var webSubnetName = 'snet-web'
var dbSubnetName = 'snet-db'
var webNsgName = 'nsg-web-${environmentName}'
var dbNsgName = 'nsg-db-${environmentName}'

// Virtual Network with two subnets
resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: webSubnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: webNsg.id
          }
        }
      }
      {
        name: dbSubnetName
        properties: {
          addressPrefix: '10.0.2.0/24'
          networkSecurityGroup: {
            id: dbNsg.id
          }
        }
      }
    ]
  }
}

// Network Security Group for Web tier (IIS)
resource webNsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: webNsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowHTTP'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
          description: 'Allow HTTP traffic to IIS'
        }
      }
      {
        name: 'AllowHTTPS'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          description: 'Allow HTTPS traffic to IIS'
        }
      }
      {
        name: 'AllowRDP'
        properties: {
          priority: 120
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: allowedRdpSourceIp != '' ? allowedRdpSourceIp : '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
          description: allowedRdpSourceIp != '' ? 'Allow RDP from specific IP' : 'Allow RDP for management'
        }
      }
      {
        name: 'AllowSSH'
        properties: {
          priority: 125
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: allowedRdpSourceIp != '' ? allowedRdpSourceIp : '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
          description: allowedRdpSourceIp != '' ? 'Allow SSH from specific IP' : 'Allow SSH for management'
        }
      }
      {
        name: 'AllowSQLFromWeb'
        properties: {
          priority: 130
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '10.0.1.0/24'
          sourcePortRange: '*'
          destinationAddressPrefix: '10.0.2.0/24'
          destinationPortRange: '1433'
          description: 'Allow SQL traffic to database subnet'
        }
      }
    ]
  }
}

// Network Security Group for Database tier (SQL Server)
resource dbNsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: dbNsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowSQLFromWeb'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '10.0.1.0/24'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '1433'
          description: 'Allow SQL traffic from web subnet only'
        }
      }
      {
        name: 'AllowRDP'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: allowedRdpSourceIp != '' ? allowedRdpSourceIp : '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
          description: allowedRdpSourceIp != '' ? 'Allow RDP from specific IP' : 'Allow RDP for management'
        }
      }
      {
        name: 'DenySQLFromInternet'
        properties: {
          priority: 200
          direction: 'Inbound'
          access: 'Deny'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '1433'
          description: 'Deny SQL traffic from Internet'
        }
      }
    ]
  }
}

// Outputs for use in other modules
output vnetId string = vnet.id
output vnetName string = vnet.name
output webSubnetId string = vnet.properties.subnets[0].id
output dbSubnetId string = vnet.properties.subnets[1].id
output webNsgId string = webNsg.id
output dbNsgId string = dbNsg.id
