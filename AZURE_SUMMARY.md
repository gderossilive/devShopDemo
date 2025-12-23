# devShop Azure Deployment - Summary

## Architecture Deployed

**Two-Tier Azure VM Architecture**:
- **Frontend**: Windows Server 2022 VM with IIS
- **Backend**: Windows Server 2022 VM with SQL Server 2022 Developer (marketplace image)
- **Network**: Azure VNet with isolated subnets and NSG security rules

## Files Created

### Infrastructure as Code (Bicep)
- ✅ `infra/main.bicep` - Main orchestrator (subscription scope)
- ✅ `infra/network.bicep` - VNet, subnets, NSGs
- ✅ `infra/sqlvm.bicep` - SQL Server VM with marketplace image
- ✅ `infra/webvm.bicep` - Web Server VM with IIS
- ✅ `infra/main.parameters.json` - Parameters file

### Azure Developer CLI Configuration
- ✅ `azure.yaml` - azd configuration with hooks
- ✅ `.azure/` - Environment folder (created by azd)

### Deployment Scripts
- ✅ `scripts/post-provision.ps1` - Post-provisioning hook
- ✅ `scripts/pre-deploy.ps1` - Pre-deployment validation
- ✅ `scripts/setup-iis.ps1` - IIS configuration on Web VM

### Application Updates
- ✅ `src/devShop/Web.config` - Updated paths for Azure deployment
  - Logs: `C:\Logs\devShop\log.txt`
  - Email: `C:\AppData\devShop\email`

### Documentation
- ✅ `docs/AZURE_DEPLOYMENT.md` - Complete Azure deployment guide
- ✅ `README.md` - Updated with Azure quick start

## Deployment Commands

### Quick Start (3 Commands)
```bash
# 1. Authentication and initialization
azd auth login
azd init

# 2. Set required passwords
azd env set SQL_ADMIN_USERNAME sqladmin
azd env set SQL_ADMIN_PASSWORD "YourStrongPass123!"
azd env set WEB_ADMIN_USERNAME webadmin  
azd env set WEB_ADMIN_PASSWORD "YourStrongPass456!"

# 3. Deploy everything
azd up
```

### Step-by-Step Commands
```bash
# Provision infrastructure only
azd provision --preview  # Preview changes
azd provision           # Create resources

# Deploy application only
azd deploy

# Full deployment (provision + deploy)
azd up
```

## What Gets Deployed

### Resource Group
- Name: `rg-{environmentName}`
- Contains all resources for the environment

### Virtual Network
- Name: `vnet-{environmentName}`
- Address Space: `10.0.0.0/16`
- Subnets:
  - Web: `10.0.1.0/24` (with web NSG)
  - Database: `10.0.2.0/24` (with db NSG)

### SQL Server VM
- Name: `vm-sql-{environmentName}`
- Size: `Standard_B4ms` (4 vCPUs, 16GB RAM, burstable)
- Image: `MicrosoftSQLServer/sql2022-ws2022/sqldev-gen2`
- Storage:
  - OS Disk: Premium SSD
  - Data Disk: 128GB Premium SSD (F:\SQLData)
- SQL Server 2022 Developer Edition pre-installed
- SQL IaaS Extension configured
- Private IP in Database subnet
- Burstable performance for dev/test workloads

### Web Server VM
- Name: `vm-web-{environmentName}`
- Size: `Standard_B2ms` (2 vCPUs, 8GB RAM, burstable)
- Image: Windows Server 2022 Datacenter Azure Edition
- Storage: Premium SSD
- Custom Script Extension installs:
  - IIS with ASP.NET 4.8
  - .NET Framework 4.8
  - Web Deploy
  - Application directories
- Public IP for HTTP/HTTPS access
- Burstable performance for cost optimization

### Network Security Groups

**Web NSG**:
- Allow HTTP (80) inbound from Internet
- Allow HTTPS (443) inbound from Internet
- Allow RDP (3389) for management
- Allow SQL (1433) outbound to Database subnet

**Database NSG**:
- Allow SQL (1433) inbound from Web subnet only
- Allow RDP (3389) for management
- Deny SQL (1433) from Internet

### Storage Account
- For deployment scripts
- Container: `scripts`
- Contains: setup-iis.ps1, CreateTables.sql, PopulateTables.sql

### Auto-Shutdown Schedules
- ✅ **Both VMs configured** to automatically shut down at **7:00 PM UTC** daily
- Saves ~50% on compute costs for dev/test environments
- Schedule can be modified in Azure Portal (VM → Auto-shutdown)
- Resource type: `Microsoft.DevTestLab/schedules`

## Post-Provision Automation

The `post-provision.ps1` hook automatically:
1. ✅ Uploads database scripts to Azure Storage
2. ✅ Uploads IIS setup script
3. ✅ Attempts to create database (if sqlcmd available)
4. ✅ Creates `.env` file with connection details
5. ✅ Displays deployment summary

## Environment Variables (azd outputs)

After provisioning, these variables are available:
- `AZURE_LOCATION` - Azure region
- `AZURE_RESOURCE_GROUP` - Resource group name
- `SQL_SERVER_NAME` - SQL VM name
- `SQL_SERVER_PRIVATE_IP` - SQL Server internal IP
- `SQL_SERVER_PUBLIC_IP` - SQL Server public IP
- `SQL_SERVER_FQDN` - SQL Server FQDN
- `WEB_SERVER_NAME` - Web VM name
- `WEB_SERVER_PRIVATE_IP` - Web Server internal IP
- `WEB_SERVER_PUBLIC_IP` - Web Server public IP
- `WEB_SERVER_FQDN` - Web Server FQDN
- `WEB_URL` - Application URL
- `CONNECTION_STRING` - SQL connection string
- `STORAGE_ACCOUNT_NAME` - Storage account name
- `VNET_NAME` - Virtual network name

View all: `azd env get-values`

## Application Configuration

### Connection String
Stored in Windows Registry on Web VM:
- Path: `HKLM\Software\Devshop\DBConnection\ConnectionString`
- Format: `Server={sql-private-ip};Database=devShopDB;User Id={username};Password={password};TrustServerCertificate=True;`

### File Paths
- Application: `C:\inetpub\wwwroot\devShop`
- Logs: `C:\Logs\devShop\log.txt`
- Emails: `C:\AppData\devShop\email`

### IIS Configuration
- Site Name: `devShop`
- Application Pool: `devShopPool`
- Port: 80 (HTTP)
- Runtime: .NET Framework 4.8

## Database Schema

Created by post-provision scripts:
- Database: `devShopDB`
- Tables:
  - `Categories` (6 categories)
  - `Products` (25 products)
  - `Customers` (10 sample customers)
  - `Orders` (10 sample orders)
  - `OrderDetails` (15 order line items)

## Timeline

Typical deployment timeline:
1. **azd provision**: 15-20 minutes
   - Resource creation: 10-12 minutes
   - VM boot and extension execution: 5-8 minutes
2. **Wait period**: 5-10 minutes (for VM setup completion)
3. **azd deploy**: 3-5 minutes
4. **Total**: ~25-35 minutes

## Cost Estimates

Monthly cost (East US, pay-as-you-go) with **B-series VMs**:

### 24/7 Operation
- Web VM (Standard_B2ms): ~$60/month
- SQL VM (Standard_B4ms): ~$120/month
- Storage (Premium SSD): ~$20-30/month
- Network (VNet, NSG, Public IPs): ~$10-15/month
- **Total**: ~$210-225/month

### With Auto-Shutdown (pre-configured)
✅ **VMs automatically shut down at 7:00 PM UTC daily**

- Web VM (Standard_B2ms): ~$27/month (~55% savings)
- SQL VM (Standard_B4ms): ~$54/month (~55% savings)
- Storage (Premium SSD): ~$20-30/month
- Network (VNet, NSG, Public IPs): ~$10-15/month
- **Total**: ~$111-126/month (**50% savings**)

**Cost optimization features**:
- ✅ Auto-shutdown at 7 PM UTC (deployed via Bicep)
- ~25% cheaper B-series VMs vs D-series
- Burstable CPU credits ideal for variable workloads
- Perfect for dev/test environments
- SQL Server Developer Edition is free

## Next Steps

1. **Wait 5-10 minutes** after `azd provision` for VMs to complete setup
2. **Run `azd deploy`** to deploy the application
3. **Access the app** at the URL shown in output
4. **Test the application**:
   - Browse products
   - View product details
   - Make a test purchase
5. **Check logs**: RDP to Web VM and view `C:\Logs\devShop\log.txt`

## Troubleshooting

### Check VM Extension Status
```bash
az vm extension list --resource-group rg-{environmentName} --vm-name vm-web-{environmentName}
```

### View Extension Logs
RDP to VM and check:
- `C:\WindowsAzure\Logs\Plugins\Microsoft.Compute.CustomScriptExtension\`
- `C:\setup-iis.log`

### Test SQL Connectivity
From Web VM:
```powershell
Test-NetConnection -ComputerName {sql-private-ip} -Port 1433
```

### Restart IIS
```powershell
iisreset /restart
```

## Cleanup

Remove all resources:
```bash
azd down --purge --force
```

This deletes:
- Resource group and all Azure resources
- Local azd environment configuration

## Key Differences from On-Premise

| On-Premise | Azure IaaS |
|------------|------------|
| Manual VM setup | Bicep IaC |
| Local scripts | Custom Script Extensions |
| Manual networking | Azure VNet + NSGs |
| PowerShell deployment | azd orchestration |
| H:\temp\logs | C:\Logs\devShop |
| K:\mountfs | C:\AppData\devShop |
| localhost SQL | Private IP SQL |

## Security Improvements

✅ Network isolation with subnets  
✅ NSG rules for least privilege access  
✅ SQL Server not exposed to Internet  
✅ Private IP communication between tiers  
✅ Public IPs only for management and web access  
✅ Azure Storage with no public access  
✅ Encrypted connection strings in azd environment  

## Production Recommendations

For production deployments:
1. **SSL/TLS**: Configure HTTPS with certificates
2. **Azure Key Vault**: Replace Registry with Key Vault
3. **Availability Zones**: Deploy across zones for HA
4. **Azure Backup**: Enable automated backups
5. **Application Gateway**: Add WAF and load balancing
6. **Monitoring**: Configure Azure Monitor + Log Analytics
7. **Auto-shutdown**: Set schedules to save costs
8. **NSG lockdown**: Restrict RDP to specific IPs
9. **Managed Identities**: Replace SQL auth with MI
10. **Consider PaaS**: Evaluate App Service + Azure SQL for managed services

---

**Status**: ✅ Complete - Ready for deployment  
**Architecture**: Two-tier Azure IaaS  
**Deployment Method**: Azure Developer CLI (azd) + Bicep  
**Time to Deploy**: ~30 minutes  
**Cost**: ~$240-285/month (24/7 operation)
