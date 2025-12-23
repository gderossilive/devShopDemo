<#
.SYNOPSIS
    Configura IIS per devShop Application
.DESCRIPTION
    Script helper per configurare IIS dopo il deployment
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$SiteName = "devShop",
    
    [Parameter(Mandatory=$false)]
    [string]$AppPath = "C:\inetpub\wwwroot\devShop",
    
    [Parameter(Mandatory=$false)]
    [int]$Port = 80
)

Import-Module WebAdministration

Write-Host "=== Configurazione IIS per devShop ===" -ForegroundColor Cyan

# Verifica che il sito esista
if (-not (Test-Path "IIS:\Sites\$SiteName")) {
    Write-Error "Sito IIS '$SiteName' non trovato. Esegui prima Setup-WindowsVM.ps1"
    exit 1
}

# 1. Configurazione Application Pool
Write-Host "`n[1/4] Configurazione Application Pool..." -ForegroundColor Yellow
$appPoolName = "${SiteName}Pool"

# Runtime version
Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name "managedRuntimeVersion" -Value "v4.0"
Write-Host "  Runtime: .NET v4.0" -ForegroundColor Gray

# Process model
Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name "processModel.identityType" -Value "ApplicationPoolIdentity"
Write-Host "  Identity: ApplicationPoolIdentity" -ForegroundColor Gray

# Advanced settings
Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name "recycling.periodicRestart.time" -Value "00:00:00"
Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name "processModel.idleTimeout" -Value "00:20:00"
Write-Host "  Idle timeout: 20 minuti" -ForegroundColor Gray

Write-Host "Application Pool configurato" -ForegroundColor Green

# 2. Configurazione Site Bindings
Write-Host "`n[2/4] Configurazione bindings..." -ForegroundColor Yellow
$bindings = Get-WebBinding -Name $SiteName
Write-Host "  Bindings attuali:" -ForegroundColor Gray
foreach ($binding in $bindings) {
    Write-Host "    - $($binding.protocol)://$($binding.bindingInformation)" -ForegroundColor Gray
}

# 3. Configurazione error pages
Write-Host "`n[3/4] Configurazione error pages..." -ForegroundColor Yellow
Set-WebConfigurationProperty -PSPath "IIS:\Sites\$SiteName" -Filter "system.webServer/httpErrors" -Name "errorMode" -Value "DetailedLocalOnly"
Write-Host "  Error mode: DetailedLocalOnly" -ForegroundColor Gray

# 4. Verifica permessi
Write-Host "`n[4/4] Verifica permessi..." -ForegroundColor Yellow
$acl = Get-Acl $AppPath
$hasIISPermission = $acl.Access | Where-Object { $_.IdentityReference -like "*IIS_IUSRS*" }
if ($hasIISPermission) {
    Write-Host "  IIS_IUSRS ha accesso al sito ✓" -ForegroundColor Green
} else {
    Write-Host "  Aggiungo permessi IIS_IUSRS..." -ForegroundColor Yellow
    $permission = "IIS_IUSRS","ReadAndExecute","ContainerInherit,ObjectInherit","None","Allow"
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
    $acl.SetAccessRule($accessRule)
    Set-Acl $AppPath $acl
    Write-Host "  Permessi aggiunti ✓" -ForegroundColor Green
}

# Restart Application Pool
Write-Host "`nRestart Application Pool..." -ForegroundColor Yellow
Restart-WebAppPool -Name $appPoolName
Write-Host "Application Pool riavviato" -ForegroundColor Green

Write-Host "`n=== Configurazione IIS Completata ===" -ForegroundColor Cyan
Write-Host "Sito disponibile su: http://localhost:$Port" -ForegroundColor White
