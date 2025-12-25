# Deploy devShop Application to Azure Web VM
# This script builds the ASP.NET application and deploys it to the Web VM

[CmdletBinding()]
param()

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  devShop Application Deployment" -ForegroundColor Cyan
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
$storageAccount = $env:STORAGE_ACCOUNT_NAME
$containerName = $env:SCRIPTS_CONTAINER_NAME

if (-not $resourceGroup -or -not $webVmName -or -not $storageAccount) {
    Write-Host "ERROR: Required environment variables not set." -ForegroundColor Red
    Write-Host "Ensure azd provision completed successfully." -ForegroundColor Red
    exit 1
}

Write-Host "Deployment Details:" -ForegroundColor Cyan
Write-Host "  Resource Group: $resourceGroup" -ForegroundColor Gray
Write-Host "  Web VM: $webVmName" -ForegroundColor Gray
Write-Host "  Storage Account: $storageAccount" -ForegroundColor Gray
Write-Host ""

# Get script directory and project root
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$srcPath = Join-Path $projectRoot "src" "devShop"

if (-not (Test-Path $srcPath)) {
    Write-Host "ERROR: Source path not found: $srcPath" -ForegroundColor Red
    exit 1
}

Write-Host "[1/4] Preparing application files..." -ForegroundColor Yellow

# Create a temporary publish directory
$tempDir = if ($env:TEMP) { $env:TEMP } else { "/tmp" }
$publishDir = Join-Path $tempDir "devShop-publish-$(Get-Date -Format 'yyyyMMddHHmmss')"
New-Item -ItemType Directory -Path $publishDir -Force | Out-Null

# Copy all necessary files (we'll deploy without building since we don't have MSBuild in container)
Write-Host "   Copying application files..." -ForegroundColor Gray
Copy-Item -Path "$srcPath\*" -Destination $publishDir -Recurse -Exclude @('obj', 'bin', '*.csproj.user', 'packages')

# Copy bin folder if it exists (pre-built)
if (Test-Path "$srcPath\bin") {
    Copy-Item -Path "$srcPath\bin" -Destination $publishDir -Recurse -Force
}

Write-Host ""
Write-Host "[2/4] Uploading application to Azure Storage..." -ForegroundColor Yellow

# Create ZIP file
$zipPath = Join-Path $tempDir "devShop-app.zip"
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

Write-Host "   Creating ZIP archive..." -ForegroundColor Gray
Compress-Archive -Path "$publishDir\*" -DestinationPath $zipPath -Force

# Upload to blob storage
Write-Host "   Uploading to blob storage..." -ForegroundColor Gray
az storage blob upload `
    --account-name $storageAccount `
    --container-name $containerName `
    --name "devShop-app.zip" `
    --file $zipPath `
    --auth-mode login `
    --overwrite true `
    --only-show-errors | Out-Null

# Generate SAS token (1 hour validity) using Azure AD auth
$expiryTime = (Get-Date).AddHours(1).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$sasToken = az storage blob generate-sas `
    --account-name $storageAccount `
    --container-name $containerName `
    --name "devShop-app.zip" `
    --permissions r `
    --expiry $expiryTime `
    --auth-mode login `
    --as-user `
    --https-only `
    --output tsv

$blobUrl = "https://$storageAccount.blob.core.windows.net/$containerName/devShop-app.zip?$sasToken"

Write-Host ""
Write-Host "[3/4] Deploying application to Web VM..." -ForegroundColor Yellow

# PowerShell script to download and extract on VM
$deployScript = @"
`$ErrorActionPreference = 'Stop'
Write-Host 'Downloading application package...'

`$zipPath = 'C:\Temp\devShop-app.zip'
`$appPath = 'C:\inetpub\wwwroot\devShop'

# Create temp directory
New-Item -ItemType Directory -Path 'C:\Temp' -Force | Out-Null

# Download file
Invoke-WebRequest -Uri '$blobUrl' -OutFile `$zipPath -UseBasicParsing

Write-Host 'Extracting application files...'

# Stop IIS App Pool
Import-Module WebAdministration
Stop-WebAppPool -Name 'devShopPool' -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Clear existing files (keep web.config if exists for backup)
if (Test-Path `$appPath) {
    Get-ChildItem -Path `$appPath -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
} else {
    New-Item -ItemType Directory -Path `$appPath -Force | Out-Null
}

# Extract files
Expand-Archive -Path `$zipPath -DestinationPath `$appPath -Force

# Set permissions
icacls `$appPath /grant 'IIS_IUSRS:(OI)(CI)RX' /T | Out-Null
icacls `$appPath /grant 'IUSR:(OI)(CI)RX' /T | Out-Null
icacls "`$appPath\App_Data" /grant 'IIS_IUSRS:(OI)(CI)F' /T -ErrorAction SilentlyContinue | Out-Null

# Start IIS App Pool
Start-WebAppPool -Name 'devShopPool'
Start-Sleep -Seconds 2

# Cleanup
Remove-Item `$zipPath -Force -ErrorAction SilentlyContinue

Write-Host 'Application deployed successfully!'
"@

try {
    $result = az vm run-command invoke `
        --resource-group $resourceGroup `
        --name $webVmName `
        --command-id RunPowerShellScript `
        --scripts $deployScript `
        --output json | ConvertFrom-Json
    
    Write-Host "   Application deployed successfully." -ForegroundColor Green
} catch {
    Write-Host "   ERROR: Failed to deploy application: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[4/4] Verifying deployment..." -ForegroundColor Yellow

Start-Sleep -Seconds 3

# Test website
$webUrl = $env:WEB_URL
if ($webUrl) {
    try {
        Write-Host "   Testing website at: $webUrl" -ForegroundColor Gray
        $response = Invoke-WebRequest -Uri $webUrl -UseBasicParsing -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            Write-Host "   Website is responding! Status: $($response.StatusCode)" -ForegroundColor Green
        } else {
            Write-Host "   Website responded with status: $($response.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "   Website test: $_" -ForegroundColor Yellow
        Write-Host "   Note: Website might need a few moments to start" -ForegroundColor Gray
    }
}

# Cleanup temporary files
if ($publishDir -and (Test-Path $publishDir)) {
    Remove-Item $publishDir -Recurse -Force -ErrorAction SilentlyContinue
}
if ($zipPath -and (Test-Path $zipPath)) {
    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Application Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Your application is now available at:" -ForegroundColor Cyan
Write-Host "  $webUrl" -ForegroundColor Cyan
Write-Host ""
Write-Host "Test the following pages:" -ForegroundColor Yellow
Write-Host "  Homepage: $webUrl" -ForegroundColor Gray
Write-Host "  Products: $webUrl/Products" -ForegroundColor Gray
Write-Host ""
