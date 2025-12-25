# Deploy devShop Application via Git Clone
# This script clones the repository directly on the VM and copies files

[CmdletBinding()]
param()

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  devShop Application Deployment (Git)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Load environment from azd
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

Write-Host "Deploying to: $webVmName in $resourceGroup" -ForegroundColor Cyan
Write-Host ""

# PowerShell script to deploy via Git
$deployScript = @'
$ErrorActionPreference = 'Stop'
Write-Host 'Starting deployment...'

$appPath = 'C:\inetpub\wwwroot\devShop'
$tempPath = 'C:\Temp\devShop-deploy'
$zipPath = 'C:\Temp\devShop.zip'

# Stop IIS App Pool
Import-Module WebAdministration
if (Test-Path 'IIS:\AppPools\devShopPool') {
    Stop-WebAppPool -Name 'devShopPool' -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

# Clean directories
if (Test-Path $tempPath) {
    Remove-Item $tempPath -Recurse -Force
}
New-Item -ItemType Directory -Path 'C:\Temp' -Force | Out-Null

# Download repository as ZIP
Write-Host 'Downloading repository from GitHub...'
$repoUrl = 'https://github.com/gderossilive/devShopDemo/archive/refs/heads/main.zip'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $repoUrl -OutFile $zipPath -UseBasicParsing

# Extract ZIP
Write-Host 'Extracting files...'
Expand-Archive -Path $zipPath -DestinationPath $tempPath -Force

# Copy application files
Write-Host 'Copying application files...'
$sourcePath = "$tempPath\devShopDemo-main\src\devShop"
if (-not (Test-Path $sourcePath)) {
    throw "Source path not found: $sourcePath"
}

# Clear app directory
if (Test-Path $appPath) {
    Remove-Item "$appPath\*" -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $appPath -Force | Out-Null

# Copy all files
Copy-Item -Path "$sourcePath\*" -Destination $appPath -Recurse -Force

# Set permissions
icacls $appPath /grant 'IIS_IUSRS:(OI)(CI)RX' /T | Out-Null
icacls $appPath /grant 'IUSR:(OI)(CI)RX' /T | Out-Null
if (Test-Path "$appPath\App_Data") {
    icacls "$appPath\App_Data" /grant 'IIS_IUSRS:(OI)(CI)F' /T | Out-Null
}

# Ensure website is configured
if (Test-Path 'IIS:\Sites\Default Web Site') {
    Stop-Website -Name 'Default Web Site' -ErrorAction SilentlyContinue
}

if (-not (Test-Path 'IIS:\Sites\devShop')) {
    if (-not (Test-Path 'IIS:\AppPools\devShopPool')) {
        New-WebAppPool -Name 'devShopPool' | Out-Null
        Set-ItemProperty 'IIS:\AppPools\devShopPool' -Name managedRuntimeVersion -Value 'v4.0'
    }
    New-Website -Name 'devShop' -Port 80 -PhysicalPath $appPath -ApplicationPool 'devShopPool' -Force | Out-Null
}

# Start App Pool and Website
Start-WebAppPool -Name 'devShopPool'
Start-Website -Name 'devShop'

# Cleanup
Remove-Item $tempPath -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

Write-Host 'Deployment complete!'
Write-Host "Files deployed to: $appPath"
Write-Host "Files found: $((Get-ChildItem $appPath | Measure-Object).Count) items"
'@

Write-Host "Deploying application from GitHub..." -ForegroundColor Yellow
Write-Host ""

try {
    $result = az vm run-command invoke `
        --resource-group $resourceGroup `
        --name $webVmName `
        --command-id RunPowerShellScript `
        --scripts $deployScript `
        --output json | ConvertFrom-Json
    
    $stdout = ($result.value | Where-Object { $_.code -like "*StdOut*" }).message
    $stderr = ($result.value | Where-Object { $_.code -like "*StdErr*" }).message
    
    if ($stdout) {
        Write-Host $stdout -ForegroundColor Gray
    }
    if ($stderr -and $stderr.Trim()) {
        Write-Host "Warnings/Errors:" -ForegroundColor Yellow
        Write-Host $stderr -ForegroundColor DarkYellow
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  Deployment Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your application is now available at:" -ForegroundColor Cyan
    Write-Host "  $($env:WEB_URL)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Test pages:" -ForegroundColor Yellow
    Write-Host "  Homepage: $($env:WEB_URL)" -ForegroundColor Gray
    Write-Host "  Products: $($env:WEB_URL)/Products" -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "ERROR: Deployment failed: $_" -ForegroundColor Red
    exit 1
}
