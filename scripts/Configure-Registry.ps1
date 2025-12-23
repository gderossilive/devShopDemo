<#
.SYNOPSIS
    Configura le chiavi di registro per devShop
.DESCRIPTION
    Crea le chiavi di registro necessarie per l'applicazione devShop
    Utilizzato per salvare la connection string nel Registry
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$ConnectionString,
    
    [Parameter(Mandatory=$false)]
    [string]$RegistryPath = "HKLM:\Software\Devshop\DBConnection"
)

Write-Host "=== Configure Registry for devShop ===" -ForegroundColor Cyan

# Verifica privilegi amministratore
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Questo script deve essere eseguito come Amministratore"
    exit 1
}

try {
    # Crea la struttura di registry se non esiste
    $basePath = "HKLM:\Software\Devshop"
    if (-not (Test-Path $basePath)) {
        New-Item -Path $basePath -Force | Out-Null
        Write-Host "Created registry key: $basePath" -ForegroundColor Gray
    }
    
    if (-not (Test-Path $RegistryPath)) {
        New-Item -Path $RegistryPath -Force | Out-Null
        Write-Host "Created registry key: $RegistryPath" -ForegroundColor Gray
    }
    
    # Imposta la connection string
    New-ItemProperty -Path $RegistryPath -Name "ConnectionString" -Value $ConnectionString -PropertyType String -Force | Out-Null
    Write-Host "Connection string set successfully ✓" -ForegroundColor Green
    
    # Verifica
    $savedValue = Get-ItemPropertyValue -Path $RegistryPath -Name "ConnectionString"
    Write-Host "`nRegistry Configuration:" -ForegroundColor Cyan
    Write-Host "  Path: $RegistryPath" -ForegroundColor Gray
    Write-Host "  Key: ConnectionString" -ForegroundColor Gray
    Write-Host "  Value: $savedValue" -ForegroundColor Gray
    
    Write-Host "`n=== Registry Configuration Completed ===" -ForegroundColor Cyan
}
catch {
    Write-Error "Errore durante la configurazione del registry: $_"
    exit 1
}
