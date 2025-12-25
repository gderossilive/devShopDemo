# Deploy devShop Application to Azure Web VM (Direct method without blob storage)
# This script embeds the application files directly in the VM command

[CmdletBinding()]
param()

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  devShop Application Deployment" -ForegroundColor Cyan
Write-Host "  (Direct Transfer Method)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Load environment from azd if not already set
if (-not $env:WEB_SERVER_NAME) {
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

$resourceGroup = $env:AZURE_RESOURCE_GROUP
$webVmName = $env:WEB_SERVER_NAME

if (-not $resourceGroup -or -not $webVmName) {
    Write-Host "ERROR: Required environment variables not set." -ForegroundColor Red
    exit 1
}

Write-Host "Deployment Details:" -ForegroundColor Cyan
Write-Host "  Resource Group: $resourceGroup" -ForegroundColor Gray
Write-Host "  Web VM: $webVmName" -ForegroundColor Gray
Write-Host ""

# Get script directory and project root
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$srcPath = Join-Path $projectRoot "src" "devShop"

if (-not (Test-Path $srcPath)) {
    Write-Host "ERROR: Source path not found: $srcPath" -ForegroundColor Red
    exit 1
}

Write-Host "[1/2] Preparing deployment package..." -ForegroundColor Yellow

# Create base64 encoded package of essential files
Write-Host "   Encoding application files..." -ForegroundColor Gray

# Read key files and encode them
$webConfigContent = Get-Content "$srcPath/Web.config" -Raw
$globalAsaxContent = Get-Content "$srcPath/Global.asax" -Raw
$globalAsaxCsContent = if (Test-Path "$srcPath/Global.asax.cs") { Get-Content "$srcPath/Global.asax.cs" -Raw } else { "" }

Write-Host ""
Write-Host "[2/2] Deploying to Web VM..." -ForegroundColor Yellow

# PowerShell script to create the application structure on VM
$deployScript = @"
`$ErrorActionPreference = 'Stop'
Write-Host 'Deploying devShop application...'

`$appPath = 'C:\inetpub\wwwroot\devShop'

# Stop IIS App Pool if exists
Import-Module WebAdministration -ErrorAction SilentlyContinue
if (Test-Path 'IIS:\AppPools\devShopPool') {
    Stop-WebAppPool -Name 'devShopPool' -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

# Create fresh directory structure
if (Test-Path `$appPath) {
    Remove-Item "`$appPath\*" -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path `$appPath -Force | Out-Null

# Create subdirectories
'App_Start', 'bin', 'Content', 'Controllers', 'Models', 'Scripts', 'Views\Home', 'Views\Products', 'Views\Shared', 'App_Data' | ForEach-Object {
    New-Item -ItemType Directory -Path "`$appPath\`$_" -Force | Out-Null
}

# Write critical files
@'
$webConfigContent
'@ | Out-File "`$appPath\Web.config" -Encoding UTF8 -Force

@'
$globalAsaxContent
'@ | Out-File "`$appPath\Global.asax" -Encoding UTF8 -Force

# Set permissions
icacls `$appPath /grant 'IIS_IUSRS:(OI)(CI)RX' /T | Out-Null
icacls `$appPath /grant 'IUSR:(OI)(CI)RX' /T | Out-Null
icacls "`$appPath\App_Data" /grant 'IIS_IUSRS:(OI)(CI)F' /T | Out-Null
icacls "`$appPath\Content" /grant 'IIS_IUSRS:(OI)(CI)F' /T -ErrorAction SilentlyContinue | Out-Null

# Ensure devShop site exists and is running
if (-not (Test-Path 'IIS:\Sites\devShop')) {
    if (Test-Path 'IIS:\Sites\Default Web Site') {
        Remove-Website -Name 'Default Web Site' -ErrorAction SilentlyContinue
    }
    if (-not (Test-Path 'IIS:\AppPools\devShopPool')) {
        New-WebAppPool -Name 'devShopPool' | Out-Null
        Set-ItemProperty 'IIS:\AppPools\devShopPool' -Name managedRuntimeVersion -Value 'v4.0'
    }
    New-Website -Name 'devShop' -Port 80 -PhysicalPath `$appPath -ApplicationPool 'devShopPool' -Force | Out-Null
}

# Start App Pool
Start-WebAppPool -Name 'devShopPool' -ErrorAction SilentlyContinue

Write-Host 'Basic structure deployed. Full application requires additional files.'
"@

try {
    Write-Host "   Configuring IIS and application structure..." -ForegroundColor Gray
    $result = az vm run-command invoke `
        --resource-group $resourceGroup `
        --name $webVmName `
        --command-id RunPowerShellScript `
        --scripts $deployScript `
        --output json | ConvertFrom-Json
    
    Write-Host "   Deployment completed." -ForegroundColor Green
    
    # Show output
    $stdout = ($result.value | Where-Object { $_.code -like "*StdOut*" }).message
    if ($stdout) {
        Write-Host ""
        Write-Host "VM Output:" -ForegroundColor Gray
        Write-Host $stdout -ForegroundColor DarkGray
    }
} catch {
    Write-Host "   ERROR: Failed to deploy: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "  Partial Deployment Complete" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "NOTE: Due to storage access restrictions, only the basic structure" -ForegroundColor Yellow
Write-Host "has been deployed. To complete the deployment:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Option 1 - RDP to the VM and manual copy:" -ForegroundColor Cyan
Write-Host "  1. RDP to $webVmName" -ForegroundColor Gray
Write-Host "  2. Copy files from local machine to C:\inetpub\wwwroot\devShop" -ForegroundColor Gray
Write-Host ""
Write-Host "Option 2 - Use Azure Bastion or Azure Files:" -ForegroundColor Cyan
Write-Host "  Configure Azure Bastion for secure file transfer" -ForegroundColor Gray
Write-Host ""
Write-Host "Your web endpoint: $($env:WEB_URL)" -ForegroundColor Cyan
Write-Host ""
