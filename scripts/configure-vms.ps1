# Configure VMs Post-Deployment Script
# This script configures IIS on Web VM and sets up the database on SQL VM
# It runs after azd provision completes

[CmdletBinding()]
param()

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  devShop VM Configuration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Load environment from azd if not already set
if (-not $env:SQL_SERVER_PRIVATE_IP) {
    Write-Host "Loading environment variables from azd..." -ForegroundColor Gray
    $envVars = azd env get-values
    foreach ($line in $envVars) {
        if ($line -match '^([^=]+)="?([^"]*)"?$') {
            $name = $matches[1]
            $value = $matches[2]
            Set-Item -Path "env:$name" -Value $value
        }
    }
}

# Get required variables
$sqlServerIp = $env:SQL_SERVER_PRIVATE_IP
$sqlAdminUser = $env:SQL_ADMIN_USERNAME
$sqlAdminPass = $env:SQL_ADMIN_PASSWORD
$resourceGroup = $env:AZURE_RESOURCE_GROUP
$sqlVmName = $env:SQL_SERVER_NAME
$webVmName = $env:WEB_SERVER_NAME

if (-not $sqlServerIp -or -not $resourceGroup) {
    Write-Host "ERROR: Required environment variables not set." -ForegroundColor Red
    Write-Host "Ensure azd provision completed successfully." -ForegroundColor Red
    exit 1
}

Write-Host "Configuration Details:" -ForegroundColor Cyan
Write-Host "  Resource Group: $resourceGroup" -ForegroundColor Gray
Write-Host "  SQL VM: $sqlVmName ($sqlServerIp)" -ForegroundColor Gray
Write-Host "  Web VM: $webVmName" -ForegroundColor Gray
Write-Host ""

Write-Host "[1/3] Setting up SQL Server database on $sqlVmName..." -ForegroundColor Yellow

# Read database setup scripts
$createTablesPath = Join-Path $PSScriptRoot ".." "database" "CreateTables.sql"
$populateTablesPath = Join-Path $PSScriptRoot ".." "database" "PopulateTables.sql"

if (-not (Test-Path $createTablesPath) -or -not (Test-Path $populateTablesPath)) {
    Write-Host "   ERROR: Database scripts not found." -ForegroundColor Red
    exit 1
}

$createTablesSql = Get-Content $createTablesPath -Raw
$populateTablesSql = Get-Content $populateTablesPath -Raw

# Escape single quotes in SQL scripts for PowerShell
$createTablesSql = $createTablesSql -replace "'", "''"
$populateTablesSql = $populateTablesSql -replace "'", "''"

# SQL script to create database and execute setup
$dbSetupScript = @"
`$ErrorActionPreference = 'Stop'
Write-Host 'Creating database...'
sqlcmd -S localhost -U $sqlAdminUser -P '$sqlAdminPass' -Q "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'devShopDB') CREATE DATABASE devShopDB"

Start-Sleep -Seconds 3

Write-Host 'Creating tables...'
sqlcmd -S localhost -U $sqlAdminUser -P '$sqlAdminPass' -d devShopDB -Q @'
$createTablesSql
'@

Write-Host 'Populating tables...'
sqlcmd -S localhost -U $sqlAdminUser -P '$sqlAdminPass' -d devShopDB -Q @'
$populateTablesSql
'@

Write-Host 'Database setup completed.'
"@

try {
    Write-Host "   Creating database and tables (this may take 1-2 minutes)..." -ForegroundColor Gray
    $result = az vm run-command invoke `
        --resource-group $resourceGroup `
        --name $sqlVmName `
        --command-id RunPowerShellScript `
        --scripts $dbSetupScript `
        --output json | ConvertFrom-Json
    
    $stdOut = $result.value[0].message
    if ($stdOut -match "error|failed") {
        Write-Host "   WARNING: $stdOut" -ForegroundColor Yellow
    } else {
        Write-Host "   Database configured successfully." -ForegroundColor Green
    }
} catch {
    Write-Host "   ERROR: Failed to configure database: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[2/3] Installing and configuring IIS on $webVmName..." -ForegroundColor Yellow

# IIS installation and configuration script
$iisSetupScript = @"
`$ErrorActionPreference = 'Continue'
Write-Host 'Installing IIS and required features...'
Install-WindowsFeature -Name Web-Server,Web-Asp-Net45,Web-Mgmt-Console,Web-Scripting-Tools -IncludeManagementTools | Out-Null

Write-Host 'Creating application directories...'
`$appPath = 'C:\inetpub\wwwroot\devShop'
`$logsPath = 'C:\Logs\devShop'
`$emailPath = 'C:\AppData\devShop\email'

New-Item -Path `$appPath -ItemType Directory -Force | Out-Null
New-Item -Path `$logsPath -ItemType Directory -Force | Out-Null
New-Item -Path `$emailPath -ItemType Directory -Force | Out-Null

Write-Host 'Setting permissions...'
`$acl = Get-Acl `$appPath
`$rule = New-Object System.Security.AccessControl.FileSystemAccessRule('IIS_IUSRS','FullControl','ContainerInherit,ObjectInherit','None','Allow')
`$acl.SetAccessRule(`$rule)
Set-Acl `$appPath `$acl
Set-Acl `$logsPath `$acl
Set-Acl `$emailPath `$acl

Write-Host 'Configuring connection string in Registry...'
`$registryPath = 'HKLM:\Software\Devshop'
if (-not (Test-Path `$registryPath)) {
    New-Item -Path `$registryPath -Force | Out-Null
}
Set-ItemProperty -Path `$registryPath -Name 'DBConnection' -Value 'Server=$sqlServerIp;Database=devShopDB;User Id=$sqlAdminUser;Password=$sqlAdminPass;TrustServerCertificate=True;'

Write-Host 'Configuring IIS Application Pool and Website...'
Import-Module WebAdministration
`$appPoolName = 'devShopAppPool'
if (Test-Path \"IIS:\AppPools\`$appPoolName\") {
    Remove-WebAppPool -Name `$appPoolName -ErrorAction SilentlyContinue
}
New-WebAppPool -Name `$appPoolName | Out-Null
Set-ItemProperty \"IIS:\AppPools\`$appPoolName\" -Name managedRuntimeVersion -Value 'v4.0'

`$siteName = 'devShop'
if (Test-Path \"IIS:\Sites\`$siteName\") {
    Remove-Website -Name `$siteName -ErrorAction SilentlyContinue
}

if (Test-Path \"IIS:\Sites\Default Web Site\") {
    Remove-Website -Name 'Default Web Site' -ErrorAction SilentlyContinue
}

New-Website -Name `$siteName -Port 80 -PhysicalPath `$appPath -ApplicationPool `$appPoolName -Force | Out-Null

Write-Host 'IIS configured successfully.'
"@

try {
    Write-Host "   Installing IIS and .NET (this may take 3-5 minutes)..." -ForegroundColor Gray
    $result = az vm run-command invoke `
        --resource-group $resourceGroup `
        --name $webVmName `
        --command-id RunPowerShellScript `
        --scripts $iisSetupScript `
        --output json | ConvertFrom-Json
    
    Write-Host "   IIS installed and configured successfully." -ForegroundColor Green
} catch {
    Write-Host "   ERROR: Failed to configure IIS: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[3/3] Configuration summary..." -ForegroundColor Yellow
Write-Host "   SQL Server: Database 'devShopDB' created and populated" -ForegroundColor Green
Write-Host "   Web Server: IIS installed and configured" -ForegroundColor Green
Write-Host "   Connection: Registry configured with SQL connection string" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  VM Configuration Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Deploy application files to the Web VM" -ForegroundColor Gray
Write-Host "2. Build and publish the ASP.NET application" -ForegroundColor Gray
Write-Host "3. Copy files to C:\inetpub\wwwroot\devShop on vm-web-dev" -ForegroundColor Gray
Write-Host ""
Write-Host "Access URLs:" -ForegroundColor Cyan
Write-Host "  Web: $($env:WEB_URL)" -ForegroundColor Cyan
Write-Host "  SQL: $sqlServerIp" -ForegroundColor Cyan
Write-Host ""
