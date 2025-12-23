# Azure Deployment Guide for devShop Application

## Architecture Overview

The devShop application is deployed on Azure using a **two-tier architecture**:

- **Frontend Tier**: Windows Server 2022 VM with IIS hosting the ASP.NET MVC application
- **Backend Tier**: Windows Server 2022 VM with SQL Server 2022 Developer Edition (pre-installed marketplace image)
- **Network**: Azure Virtual Network with separate subnets for web and database tiers, secured with Network Security Groups

```
┌─────────────────────────────────────────────────────────────┐
│                     Azure Subscription                       │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │           Resource Group: rg-{environmentName}         │ │
│  │                                                        │ │
│  │  ┌──────────────────────────────────────────────┐     │ │
│  │  │         Virtual Network (10.0.0.0/16)        │     │ │
│  │  │                                               │     │ │
│  │  │  ┌─────────────────┐  ┌──────────────────┐   │     │ │
│  │  │  │  Web Subnet     │  │  Database Subnet │   │     │ │
│  │  │  │  (10.0.1.0/24)  │  │  (10.0.2.0/24)   │   │     │ │
│  │  │  │                 │  │                  │   │     │ │
│  │  │  │  ┌───────────┐  │  │  ┌────────────┐  │   │     │ │
│  │  │  │  │  Web VM   │  │  │  │  SQL VM    │  │   │     │ │
│  │  │  │  │  + IIS    │◄─┼──┼─►│ SQL Server │  │   │     │ │
│  │  │  │  │  + .NET   │  │  │  │ 2022 Dev   │  │   │     │ │
│  │  │  │  └───────────┘  │  │  └────────────┘  │   │     │ │
│  │  │  │       ▲         │  │                  │   │     │ │
│  │  │  └───────┼─────────┘  └──────────────────┘   │     │ │
│  │  └──────────┼────────────────────────────────────┘     │ │
│  │             │                                          │ │
│  │        Public IP                                       │ │
│  │        (HTTP/HTTPS)                                    │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

1. **Azure Subscription**: Active Azure subscription with sufficient permissions
2. **Azure Developer CLI (azd)**: Install from https://aka.ms/azd-install
3. **Azure CLI**: Install from https://aka.ms/azcli
4. **PowerShell 7+**: For running deployment scripts
5. **Git**: For cloning the repository

## Quick Start

### 1. Initialize Environment

```bash
# Login to Azure
azd auth login

# Initialize the environment (first time only)
azd init

# You'll be prompted to enter:
# - Environment name (e.g., "devshop-prod")
# - Azure location (e.g., "eastus")
```

### 2. Set Required Parameters

Before provisioning, set the required passwords:

```bash
# Set SQL Server admin credentials
azd env set SQL_ADMIN_USERNAME sqladmin
azd env set SQL_ADMIN_PASSWORD "YourStrongPassword123!"

# Set Web VM admin credentials
azd env set WEB_ADMIN_USERNAME webadmin
azd env set WEB_ADMIN_PASSWORD "YourStrongPassword456!"
```

**Important**: Use strong passwords that meet Azure VM requirements:
- At least 12 characters
- Mix of uppercase, lowercase, numbers, and special characters

### 3. Provision Infrastructure

```bash
# Preview changes (recommended)
azd provision --preview

# Provision Azure resources
azd provision
```

This command will:
1. Create a resource group
2. Deploy Virtual Network with subnets and NSGs
3. Create SQL Server VM with marketplace image (SQL Server 2022 Developer)
4. Create Web Server VM with Windows Server 2022
5. Configure network connectivity
6. Run post-provision hooks to:
   - Upload setup scripts to Azure Storage
   - Configure SQL Server database
   - Set up environment variables

**Estimated time**: 15-20 minutes

### 4. Wait for VM Configuration

After `azd provision` completes, the VMs need additional time to:
- Complete Custom Script Extension execution
- Install IIS and .NET Framework
- Configure SQL Server storage
- Create application directories

**Wait 5-10 minutes** before proceeding to deployment.

### 5. Deploy Application

```bash
# Deploy the ASP.NET application to the Web VM
azd deploy
```

This will package and deploy the devShop application to IIS.

### 6. Access the Application

After deployment, access your application:

```bash
# Get the web URL
azd env get-values | grep WEB_URL
```

Or visit: `http://{web-vm-fqdn}`

## Infrastructure Details

### Resource Naming Convention

All resources follow the naming pattern:
- Resource Group: `rg-{environmentName}`
- Web VM: `vm-web-{environmentName}`
- SQL VM: `vm-sql-{environmentName}`
- Virtual Network: `vnet-{environmentName}`
- Network Interfaces: `nic-{tier}-{environmentName}`
- Public IPs: `pip-{tier}-{environmentName}`

### Network Security

**Web Subnet NSG Rules**:
- Allow HTTP (80) from Internet
- Allow HTTPS (443) from Internet
- Allow RDP (3389) for management
- Allow SQL (1433) outbound to Database subnet

**Database Subnet NSG Rules**:
- Allow SQL (1433) from Web subnet only
- Allow RDP (3389) for management
- Deny SQL (1433) from Internet

### VM Specifications

**Web Server VM**:
- Size: Standard_B2ms (2 vCPUs, 8 GB RAM, burstable)
- OS: Windows Server 2022 Datacenter Azure Edition
- Storage: Premium SSD
- Software: IIS, .NET Framework 4.8, Web Deploy
- Performance: Burstable VM ideal for web workloads with variable CPU usage

**SQL Server VM**:
- Size: Standard_B4ms (4 vCPUs, 16 GB RAM, burstable)
- OS: Windows Server 2022 with SQL Server 2022 Developer Edition
- Storage: Premium SSD (OS) + 128GB Premium SSD (Data)
- Configuration: SQL IaaS Extension with optimized storage layout
- Performance: Burstable VM suitable for dev/test and small production workloads

## Configuration

### Connection String

The application reads the SQL Server connection string from the Windows Registry:
- Path: `HKLM\Software\Devshop\DBConnection\ConnectionString`
- Format: `Server={sql-private-ip};Database=devShopDB;User Id={username};Password={password};TrustServerCertificate=True;`

This is automatically configured by the setup scripts.

### Application Paths

- **Application**: `C:\inetpub\wwwroot\devShop`
- **Logs**: `C:\Logs\devShop\log.txt`
- **Email Pickup**: `C:\AppData\devShop\email`

### Database

- **Server**: SQL Server VM private IP (10.0.2.x)
- **Database Name**: `devShopDB`
- **Authentication**: SQL Server authentication
- **Data Files**: `F:\SQLData`
- **Log Files**: `F:\SQLLog`

## Management Commands

### View Environment Variables

```bash
azd env get-values
```

### SSH/RDP into VMs

```bash
# Get public IPs
azd env get-values | grep PUBLIC_IP

# RDP using credentials set during provisioning
# Username: webadmin (or sqladmin for SQL VM)
# Password: {your-password}
```

### Monitor Resources

```bash
# View resources in Azure Portal
az group show --name rg-{environmentName} --query "id" -o tsv
```

### View Application Logs

RDP into Web VM and check:
- Application logs: `C:\Logs\devShop\log.txt`
- IIS logs: `C:\inetpub\logs\LogFiles`
- Setup logs: `C:\setup-iis.log`

## Database Management

### Manual Database Setup

If post-provision database setup fails, run manually:

```powershell
# On your local machine
cd database
.\Setup-Database.ps1 -ServerName {sql-vm-private-ip} -SqlAuthMode -AdminUsername sqladmin -AdminPassword {password}
```

### Connect to SQL Server

Use SQL Server Management Studio:
- Server: `{sql-vm-public-ip}` (for remote) or `{sql-vm-private-ip}` (from Web VM)
- Authentication: SQL Server Authentication
- Username: sqladmin
- Password: {your-sql-password}

## Troubleshooting

### VM Setup Issues

1. **Check Custom Script Extension status**:
   ```bash
   az vm extension list --resource-group rg-{environmentName} --vm-name vm-web-{environmentName}
   ```

2. **View extension logs** (RDP into VM):
   - Location: `C:\WindowsAzure\Logs\Plugins\Microsoft.Compute.CustomScriptExtension`

### Application Not Loading

1. **Verify IIS is running**:
   ```powershell
   Get-Service W3SVC
   iisreset
   ```

2. **Check application pool**:
   ```powershell
   Import-Module WebAdministration
   Get-WebAppPoolState devShopPool
   Start-WebAppPool devShopPool
   ```

3. **Test SQL connectivity** from Web VM:
   ```powershell
   Test-NetConnection -ComputerName {sql-private-ip} -Port 1433
   ```

### Database Connection Issues

1. **Verify SQL Server is running** on SQL VM:
   ```powershell
   Get-Service MSSQLSERVER
   Start-Service MSSQLSERVER
   ```

2. **Check firewall rules**:
   ```powershell
   Get-NetFirewallRule -DisplayName "*SQL*"
   ```

3. **Verify NSG rules** allow traffic from Web subnet to Database subnet on port 1433

## Cost Optimization

To minimize Azure costs:

### Automatic Shutdown (Pre-configured)

✅ **Auto-shutdown is already configured** - Both VMs automatically shut down at **7:00 PM UTC daily**

This is deployed automatically via Bicep and saves ~50% on VM costs if you work 8-hour days.

**To modify shutdown time**:
1. Navigate to VM in Azure Portal → **Auto-shutdown**
2. Change time or timezone as needed
3. Enable email notifications if desired

**To disable auto-shutdown**:
```bash
az vm auto-shutdown --resource-group rg-{environmentName} --name vm-web-{environmentName} --status Disabled
az vm auto-shutdown --resource-group rg-{environmentName} --name vm-sql-{environmentName} --status Disabled
```

### Manual VM Management

1. **Deallocate VMs manually when not in use**:
   ```bash
   az vm deallocate --resource-group rg-{environmentName} --name vm-web-{environmentName}
   az vm deallocate --resource-group rg-{environmentName} --name vm-sql-{environmentName}
   ```

2. **Start VMs when needed**:
   ```bash
   az vm start --resource-group rg-{environmentName} --name vm-web-{environmentName}
   az vm start --resource-group rg-{environmentName} --name vm-sql-{environmentName}
   ```

## Cleanup

To delete all Azure resources:

```bash
# Delete environment (removes all resources)
azd down --purge --force
```

This will delete:
- Resource group and all resources
- Local environment configuration

## CI/CD Integration

For automated deployments, you can integrate with GitHub Actions or Azure DevOps:

```bash
# Configure CI/CD pipeline
azd pipeline config
```

Follow the prompts to set up:
- GitHub Actions workflow
- Azure service principal
- Environment secrets

## Next Steps

1. **Configure SSL/TLS**: Add Azure Application Gateway or configure IIS SSL certificates
2. **Backup Strategy**: Set up Azure Backup for VMs and SQL Server
3. **Monitoring**: Enable Azure Monitor and Application Insights
4. **Scaling**: Consider Azure VM Scale Sets for the web tier
5. **High Availability**: Deploy across availability zones or availability sets

## Support

For issues or questions:
- Check logs in `C:\Logs\devShop\` and `C:\setup-iis.log`
- Review NSG rules and VM extension status
- Verify environment variables: `azd env get-values`
- Check [Azure documentation](https://learn.microsoft.com/azure/)

## Architecture Decisions

### Why Two VMs Instead of Azure PaaS?

This architecture uses VMs to:
1. Demonstrate traditional IaaS deployment patterns
2. Provide full control over IIS and SQL Server configuration
3. Support migration from on-premise environments
4. Match the original LAB501 requirements adapted for Azure

For production workloads, consider:
- Azure App Service for the web tier
- Azure SQL Database for the database tier
- Azure Application Gateway for load balancing and SSL termination
