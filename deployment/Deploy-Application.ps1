<#
.SYNOPSIS
    Deploy dell'applicazione devShop (solo copia file)
.DESCRIPTION
    Copia i file dell'applicazione già compilata nella directory IIS
.NOTES
    Usa questo script se hai già compilato l'applicazione
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$SourcePath = "$PSScriptRoot\..\src\devShop",
    
    [Parameter(Mandatory=$false)]
    [string]$TargetPath = "C:\inetpub\wwwroot\devShop",
    
    [Parameter(Mandatory=$false)]
    [string]$AppPoolName = "devShopPool"
)

Write-Host "=== Deploy devShop Application ===" -ForegroundColor Cyan

# 1. Verifica source directory
Write-Host "`n[1/4] Verifying source directory..." -ForegroundColor Yellow
if (-not (Test-Path $SourcePath)) {
    Write-Error "Source directory not found: $SourcePath"
    exit 1
}
Write-Host "Source directory: $SourcePath" -ForegroundColor Gray

# 2. Crea target directory
Write-Host "`n[2/4] Creating target directory..." -ForegroundColor Yellow
if (-not (Test-Path $TargetPath)) {
    New-Item -Path $TargetPath -ItemType Directory -Force | Out-Null
    Write-Host "Target directory created: $TargetPath" -ForegroundColor Gray
}
else {
    Write-Host "Target directory exists: $TargetPath" -ForegroundColor Gray
}

# 3. Stop Application Pool
Write-Host "`n[3/4] Stopping Application Pool..." -ForegroundColor Yellow
try {
    Import-Module WebAdministration
    if (Test-Path "IIS:\AppPools\$AppPoolName") {
        Stop-WebAppPool -Name $AppPoolName
        Start-Sleep -Seconds 2
        Write-Host "Application Pool stopped ✓" -ForegroundColor Green
    }
    else {
        Write-Warning "Application Pool '$AppPoolName' not found"
    }
}
catch {
    Write-Warning "Could not stop Application Pool: $_"
}

# 4. Copy files
Write-Host "`n[4/4] Copying files..." -ForegroundColor Yellow

$excludePatterns = @("*.cs", "*.csproj", "*.user", "obj", "Properties")

try {
    # Copia tutti i file necessari
    $filesToCopy = @(
        "*.asax",
        "*.config",
        "*.aspx",
        "*.ascx",
        "*.master",
        "*.cshtml",
        "bin",
        "Content",
        "Scripts",
        "Views",
        "App_Start"
    )
    
    foreach ($pattern in $filesToCopy) {
        $sourcePath = Join-Path $SourcePath $pattern
        if (Test-Path $sourcePath) {
            Copy-Item -Path $sourcePath -Destination $TargetPath -Recurse -Force
            Write-Host "  Copied: $pattern" -ForegroundColor Gray
        }
    }
    
    Write-Host "Files copied successfully ✓" -ForegroundColor Green
}
catch {
    Write-Error "Error copying files: $_"
    exit 1
}

# Start Application Pool
Write-Host "`nStarting Application Pool..." -ForegroundColor Yellow
try {
    if (Test-Path "IIS:\AppPools\$AppPoolName") {
        Start-WebAppPool -Name $AppPoolName
        Write-Host "Application Pool started ✓" -ForegroundColor Green
    }
}
catch {
    Write-Warning "Could not start Application Pool: $_"
}

# Verifica deployment
Write-Host "`n=== Deployment Verification ===" -ForegroundColor Cyan
$requiredFiles = @("Web.config", "Global.asax", "bin")
$allPresent = $true

foreach ($file in $requiredFiles) {
    $filePath = Join-Path $TargetPath $file
    if (Test-Path $filePath) {
        Write-Host "  ✓ $file" -ForegroundColor Green
    }
    else {
        Write-Host "  ✗ $file MISSING" -ForegroundColor Red
        $allPresent = $false
    }
}

if ($allPresent) {
    Write-Host "`n=== Deployment Completed Successfully ===" -ForegroundColor Cyan
    Write-Host "Application deployed to: $TargetPath" -ForegroundColor White
    Write-Host "Test your application at: http://localhost" -ForegroundColor Yellow
}
else {
    Write-Warning "Some files are missing. Deployment may be incomplete."
}
