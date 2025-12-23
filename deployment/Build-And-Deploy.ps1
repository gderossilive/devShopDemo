<#
.SYNOPSIS
    Build e deploy dell'applicazione devShop
.DESCRIPTION
    Compila e pubblica l'applicazione ASP.NET devShop su IIS
.NOTES
    Richiede MSBuild e Visual Studio
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$SolutionPath = "$PSScriptRoot\..\src\devShop.sln",
    
    [Parameter(Mandatory=$false)]
    [string]$PublishProfile = "Release",
    
    [Parameter(Mandatory=$false)]
    [string]$TargetPath = "C:\inetpub\wwwroot\devShop",
    
    [Parameter(Mandatory=$false)]
    [string]$Configuration = "Release"
)

Write-Host "=== Build and Deploy devShop Application ===" -ForegroundColor Cyan

# 1. Verifica MSBuild
Write-Host "`n[1/5] Locating MSBuild..." -ForegroundColor Yellow
$msbuildPath = $null

# Cerca MSBuild nelle posizioni comuni
$msbuildLocations = @(
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe"
)

foreach ($location in $msbuildLocations) {
    if (Test-Path $location) {
        $msbuildPath = $location
        break
    }
}

if (-not $msbuildPath) {
    # Prova con vswhere
    $vswhere = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $vsPath = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -property installationPath
        if ($vsPath) {
            $msbuildPath = Join-Path $vsPath "MSBuild\Current\Bin\MSBuild.exe"
        }
    }
}

if (-not $msbuildPath -or -not (Test-Path $msbuildPath)) {
    Write-Error "MSBuild not found. Please install Visual Studio or MSBuild tools."
    Write-Host "`nAlternative: Use Visual Studio to publish the application manually:" -ForegroundColor Yellow
    Write-Host "  1. Open devShop.sln in Visual Studio" -ForegroundColor White
    Write-Host "  2. Right-click on devShop project -> Publish" -ForegroundColor White
    Write-Host "  3. Select 'Folder' as target" -ForegroundColor White
    Write-Host "  4. Set folder path to: $TargetPath" -ForegroundColor White
    exit 1
}

Write-Host "MSBuild found: $msbuildPath" -ForegroundColor Green

# 2. Verifica solution file
Write-Host "`n[2/5] Verifying solution file..." -ForegroundColor Yellow
if (-not (Test-Path $SolutionPath)) {
    Write-Error "Solution file not found: $SolutionPath"
    Write-Host "`nTo create the solution file, use Visual Studio:" -ForegroundColor Yellow
    Write-Host "  1. Open Visual Studio" -ForegroundColor White
    Write-Host "  2. File -> New -> Project From Existing Code" -ForegroundColor White
    Write-Host "  3. Select the src\devShop folder" -ForegroundColor White
    exit 1
}

Write-Host "Solution file found: $SolutionPath" -ForegroundColor Green

# 3. Restore NuGet packages
Write-Host "`n[3/5] Restoring NuGet packages..." -ForegroundColor Yellow
try {
    & $msbuildPath $SolutionPath /t:Restore /p:Configuration=$Configuration
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "NuGet restore completed with warnings"
    }
    else {
        Write-Host "NuGet packages restored ✓" -ForegroundColor Green
    }
}
catch {
    Write-Error "Error restoring NuGet packages: $_"
    exit 1
}

# 4. Build solution
Write-Host "`n[4/5] Building solution..." -ForegroundColor Yellow
try {
    & $msbuildPath $SolutionPath /p:Configuration=$Configuration /p:DeployOnBuild=true /p:PublishProfile=$PublishProfile
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build failed"
        exit 1
    }
    Write-Host "Solution built successfully ✓" -ForegroundColor Green
}
catch {
    Write-Error "Error building solution: $_"
    exit 1
}

# 5. Copy files to IIS directory
Write-Host "`n[5/5] Deploying to IIS..." -ForegroundColor Yellow

# Crea directory se non esiste
if (-not (Test-Path $TargetPath)) {
    New-Item -Path $TargetPath -ItemType Directory -Force | Out-Null
}

# Cerca la cartella di publish
$publishPath = "$PSScriptRoot\..\src\devShop\bin\$Configuration\Publish"
if (-not (Test-Path $publishPath)) {
    $publishPath = "$PSScriptRoot\..\src\devShop\bin\$Configuration"
}

if (Test-Path $publishPath) {
    try {
        # Copia file
        Copy-Item -Path "$publishPath\*" -Destination $TargetPath -Recurse -Force
        Write-Host "Files deployed to: $TargetPath" -ForegroundColor Green
    }
    catch {
        Write-Error "Error deploying files: $_"
        exit 1
    }
}
else {
    Write-Warning "Publish folder not found at: $publishPath"
    Write-Host "`nManual deployment required:" -ForegroundColor Yellow
    Write-Host "  1. Build the solution in Visual Studio" -ForegroundColor White
    Write-Host "  2. Right-click devShop project -> Publish" -ForegroundColor White
    Write-Host "  3. Publish to: $TargetPath" -ForegroundColor White
}

# Restart Application Pool
Write-Host "`nRestarting Application Pool..." -ForegroundColor Yellow
try {
    Import-Module WebAdministration
    $appPool = "devShopPool"
    if (Test-Path "IIS:\AppPools\$appPool") {
        Restart-WebAppPool -Name $appPool
        Write-Host "Application Pool restarted ✓" -ForegroundColor Green
    }
    else {
        Write-Warning "Application Pool '$appPool' not found"
    }
}
catch {
    Write-Warning "Could not restart Application Pool: $_"
}

Write-Host "`n=== Deployment Completed ===" -ForegroundColor Cyan
Write-Host "Application deployed to: $TargetPath" -ForegroundColor White
Write-Host "`nTest your application at: http://localhost" -ForegroundColor Yellow
