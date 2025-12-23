<#
.SYNOPSIS
    Installa prerequisiti per devShop Application
.DESCRIPTION
    Verifica e guida nell'installazione di tutti i prerequisiti necessari
#>

[CmdletBinding()]
param()

Write-Host "=== Verifica Prerequisiti devShop Application ===" -ForegroundColor Cyan

# Array per tracciare cosa manca
$missingComponents = @()

# 1. Verifica Windows Server
Write-Host "`n[1/5] Verifica Windows Server..." -ForegroundColor Yellow
$osInfo = Get-WmiObject -Class Win32_OperatingSystem
Write-Host "  OS: $($osInfo.Caption)" -ForegroundColor Gray
Write-Host "  Versione: $($osInfo.Version)" -ForegroundColor Gray

if ($osInfo.ProductType -eq 1) {
    Write-Host "  ATTENZIONE: Stai usando Windows Client (non Server)" -ForegroundColor Yellow
    Write-Host "  Alcune feature potrebbero non essere disponibili" -ForegroundColor Yellow
}

# 2. Verifica .NET Framework 4.8
Write-Host "`n[2/5] Verifica .NET Framework 4.8..." -ForegroundColor Yellow
$dotNetVersion = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -Name Release -ErrorAction SilentlyContinue
if ($dotNetVersion -ge 528040) {
    Write-Host "  .NET Framework 4.8 installato ✓" -ForegroundColor Green
} else {
    Write-Host "  .NET Framework 4.8 NON installato ✗" -ForegroundColor Red
    $missingComponents += ".NET Framework 4.8"
}

# 3. Verifica IIS
Write-Host "`n[3/5] Verifica IIS..." -ForegroundColor Yellow
$iisFeature = Get-WindowsFeature -Name Web-Server -ErrorAction SilentlyContinue
if ($iisFeature -and $iisFeature.Installed) {
    Write-Host "  IIS installato ✓" -ForegroundColor Green
    
    # Verifica ASP.NET
    $aspNet = Get-WindowsFeature -Name Web-Asp-Net45 -ErrorAction SilentlyContinue
    if ($aspNet -and $aspNet.Installed) {
        Write-Host "  ASP.NET 4.5+ installato ✓" -ForegroundColor Green
    } else {
        Write-Host "  ASP.NET 4.5+ NON installato ✗" -ForegroundColor Red
        $missingComponents += "ASP.NET 4.5+"
    }
} else {
    Write-Host "  IIS NON installato ✗" -ForegroundColor Red
    $missingComponents += "IIS"
}

# 4. Verifica SQL Server
Write-Host "`n[4/5] Verifica SQL Server..." -ForegroundColor Yellow
$sqlInstances = Get-Service -Name "MSSQL*" -ErrorAction SilentlyContinue
if ($sqlInstances) {
    Write-Host "  SQL Server installato ✓" -ForegroundColor Green
    foreach ($instance in $sqlInstances) {
        Write-Host "    - $($instance.DisplayName): $($instance.Status)" -ForegroundColor Gray
    }
} else {
    Write-Host "  SQL Server NON installato ✗" -ForegroundColor Red
    $missingComponents += "SQL Server"
}

# 5. Verifica PowerShell
Write-Host "`n[5/5] Verifica PowerShell..." -ForegroundColor Yellow
Write-Host "  Versione: $($PSVersionTable.PSVersion)" -ForegroundColor Gray
if ($PSVersionTable.PSVersion.Major -ge 5) {
    Write-Host "  PowerShell 5.0+ installato ✓" -ForegroundColor Green
} else {
    Write-Host "  PowerShell 5.0+ richiesto ✗" -ForegroundColor Red
    $missingComponents += "PowerShell 5.0+"
}

# Riepilogo
Write-Host "`n=== Riepilogo ===" -ForegroundColor Cyan

if ($missingComponents.Count -eq 0) {
    Write-Host "`nTutti i prerequisiti sono soddisfatti! ✓" -ForegroundColor Green
    Write-Host "Puoi procedere con Setup-WindowsVM.ps1" -ForegroundColor White
} else {
    Write-Host "`nComponenti mancanti:" -ForegroundColor Red
    foreach ($component in $missingComponents) {
        Write-Host "  ✗ $component" -ForegroundColor Red
    }
    
    Write-Host "`nIstruzioni per l'installazione:" -ForegroundColor Yellow
    
    if ($missingComponents -contains ".NET Framework 4.8") {
        Write-Host "`n.NET Framework 4.8:" -ForegroundColor White
        Write-Host "  Download: https://dotnet.microsoft.com/download/dotnet-framework/net48" -ForegroundColor Gray
        Write-Host "  Installer: ndp48-web.exe o ndp48-x86-x64-allos-enu.exe" -ForegroundColor Gray
    }
    
    if ($missingComponents -contains "IIS" -or $missingComponents -contains "ASP.NET 4.5+") {
        Write-Host "`nIIS e ASP.NET:" -ForegroundColor White
        Write-Host "  Esegui Setup-WindowsVM.ps1 che installerà automaticamente IIS" -ForegroundColor Gray
        Write-Host "  Oppure manualmente:" -ForegroundColor Gray
        Write-Host "    Install-WindowsFeature -Name Web-Server -IncludeManagementTools" -ForegroundColor Gray
        Write-Host "    Install-WindowsFeature -Name Web-Asp-Net45" -ForegroundColor Gray
    }
    
    if ($missingComponents -contains "SQL Server") {
        Write-Host "`nSQL Server:" -ForegroundColor White
        Write-Host "  Opzione 1 - SQL Server 2022 Developer (gratuito):" -ForegroundColor Gray
        Write-Host "    Download: https://www.microsoft.com/sql-server/sql-server-downloads" -ForegroundColor Gray
        Write-Host "  Opzione 2 - SQL Server 2022 Express (gratuito, limitato):" -ForegroundColor Gray
        Write-Host "    Download: https://www.microsoft.com/sql-server/sql-server-downloads" -ForegroundColor Gray
        Write-Host "  Opzione 3 - SQL Server 2019:" -ForegroundColor Gray
        Write-Host "    Download: https://www.microsoft.com/sql-server/sql-server-2019" -ForegroundColor Gray
        Write-Host "`n  Dopo l'installazione, installa anche SQL Server Management Studio (SSMS):" -ForegroundColor Gray
        Write-Host "    Download: https://aka.ms/ssmsfullsetup" -ForegroundColor Gray
    }
}

Write-Host ""
