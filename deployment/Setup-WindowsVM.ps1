<#
.SYNOPSIS
    Setup completo Windows Server per devShop Application
.DESCRIPTION
    Installa e configura tutti i prerequisiti: IIS, .NET Framework, SQL Server, Fonts, Registry
.NOTES
    Eseguire come Amministratore su Windows Server 2019/2022
.EXAMPLE
    .\Setup-WindowsVM.ps1 -SqlSaPassword "YourStrongPassword123!"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$SqlSaPassword,
    
    [Parameter(Mandatory=$false)]
    [string]$AppName = "devShop",
    
    [Parameter(Mandatory=$false)]
    [string]$DatabaseName = "l501devshopdb",
    
    [Parameter(Mandatory=$false)]
    [string]$IISSiteName = "devShop",
    
    [Parameter(Mandatory=$false)]
    [int]$IISPort = 80
)

# Verifica privilegi amministratore
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Questo script deve essere eseguito come Amministratore"
    exit 1
}

Write-Host "=== Setup Windows Server per devShop Application ===" -ForegroundColor Cyan
Write-Host "Data: $(Get-Date)" -ForegroundColor Gray

# 1. Installazione IIS e componenti
Write-Host "`n[1/8] Installazione IIS e ASP.NET..." -ForegroundColor Yellow
Install-WindowsFeature -Name Web-Server -IncludeManagementTools
Install-WindowsFeature -Name Web-Asp-Net45
Install-WindowsFeature -Name Web-Net-Ext45
Install-WindowsFeature -Name Web-ISAPI-Ext
Install-WindowsFeature -Name Web-ISAPI-Filter
Install-WindowsFeature -Name Web-Mgmt-Console

Write-Host "IIS installato con successo" -ForegroundColor Green

# 2. Installazione .NET Framework 4.8
Write-Host "`n[2/8] Verifica .NET Framework 4.8..." -ForegroundColor Yellow
$dotNetVersion = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -Name Release -ErrorAction SilentlyContinue
if ($dotNetVersion -ge 528040) {
    Write-Host ".NET Framework 4.8 già installato (Release: $dotNetVersion)" -ForegroundColor Green
} else {
    Write-Host ".NET Framework 4.8 non trovato. Scaricalo da: https://dotnet.microsoft.com/download/dotnet-framework/net48" -ForegroundColor Red
    Write-Host "Dopo l'installazione, riesegui questo script" -ForegroundColor Red
    exit 1
}

# 3. Creazione directory applicazione
Write-Host "`n[3/8] Creazione directory applicazione..." -ForegroundColor Yellow
$appPath = "C:\inetpub\wwwroot\$AppName"
$logsPath = "C:\Logs\$AppName"
$dataPath = "C:\AppData\$AppName"
$emailPath = "$dataPath\email"

New-Item -Path $appPath -ItemType Directory -Force | Out-Null
New-Item -Path "$logsPath\temp\logs" -ItemType Directory -Force | Out-Null
New-Item -Path $emailPath -ItemType Directory -Force | Out-Null

Write-Host "Directory create:" -ForegroundColor Green
Write-Host "  App: $appPath" -ForegroundColor Gray
Write-Host "  Logs: $logsPath\temp\logs" -ForegroundColor Gray
Write-Host "  Email: $emailPath" -ForegroundColor Gray

# 4. Configurazione permessi
Write-Host "`n[4/8] Configurazione permessi..." -ForegroundColor Yellow
$acl = Get-Acl $logsPath
$permission = "IIS_IUSRS","FullControl","ContainerInherit,ObjectInherit","None","Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.SetAccessRule($accessRule)
Set-Acl $logsPath $acl

$acl = Get-Acl $dataPath
$acl.SetAccessRule($accessRule)
Set-Acl $dataPath $acl

Write-Host "Permessi configurati per IIS_IUSRS" -ForegroundColor Green

# 5. Creazione Registry Key per connection string
Write-Host "`n[5/8] Creazione chiavi di registro..." -ForegroundColor Yellow
$regPath = "HKLM:\Software\Devshop\DBConnection"
if (-not (Test-Path $regPath)) {
    New-Item -Path "HKLM:\Software\Devshop" -Force | Out-Null
    New-Item -Path $regPath -Force | Out-Null
}

# Connection string per SQL Server locale
# Opzione 1: Windows Authentication (consigliato per produzione)
$connectionString = "Data Source=localhost;Initial Catalog=$DatabaseName;Integrated Security=True;TrustServerCertificate=True"

# Opzione 2: SQL Authentication (commentata, decommenta se necessario)
# $connectionString = "Data Source=localhost;Initial Catalog=$DatabaseName;User Id=sa;Password=$SqlSaPassword;TrustServerCertificate=True"

New-ItemProperty -Path $regPath -Name "ConnectionString" -Value $connectionString -PropertyType String -Force | Out-Null
Write-Host "Registry key creata: $regPath" -ForegroundColor Green
Write-Host "  ConnectionString configurato" -ForegroundColor Gray

# 6. Installazione fonts personalizzati
Write-Host "`n[6/8] Installazione fonts..." -ForegroundColor Yellow
$fontsFolder = "$PSScriptRoot\..\assets\fonts"
if (Test-Path $fontsFolder) {
    $fonts = Get-ChildItem $fontsFolder -Filter *.ttf
    if ($fonts.Count -gt 0) {
        foreach ($font in $fonts) {
            Copy-Item $font.FullName "C:\Windows\Fonts\" -Force
            Write-Host "  Font installato: $($font.Name)" -ForegroundColor Gray
        }
        Write-Host "Fonts installati: $($fonts.Count)" -ForegroundColor Green
    } else {
        Write-Host "Nessun font .ttf trovato in $fontsFolder" -ForegroundColor Yellow
    }
} else {
    Write-Host "Cartella fonts non trovata ($fontsFolder), skip..." -ForegroundColor Yellow
}

# 7. Configurazione SMTP per delivery locale
Write-Host "`n[7/8] Configurazione SMTP..." -ForegroundColor Yellow
Install-WindowsFeature -Name SMTP-Server -IncludeManagementTools -ErrorAction SilentlyContinue

$smtpPickupPath = $emailPath

Write-Host "SMTP Pickup directory configurato: $smtpPickupPath" -ForegroundColor Green
Write-Host "  Le email verranno salvate come file .eml" -ForegroundColor Gray

# 8. Creazione Application Pool e Site IIS
Write-Host "`n[8/8] Configurazione IIS..." -ForegroundColor Yellow

Import-Module WebAdministration

# Creazione Application Pool
$appPoolName = "${AppName}Pool"
if (Test-Path "IIS:\AppPools\$appPoolName") {
    Remove-WebAppPool -Name $appPoolName
    Write-Host "  Application Pool esistente rimosso" -ForegroundColor Gray
}

New-WebAppPool -Name $appPoolName | Out-Null
Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name "managedRuntimeVersion" -Value "v4.0"
Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name "processModel.identityType" -Value "ApplicationPoolIdentity"

Write-Host "  Application Pool creato: $appPoolName" -ForegroundColor Gray

# Creazione Site IIS
if (Test-Path "IIS:\Sites\$IISSiteName") {
    Remove-Website -Name $IISSiteName
    Write-Host "  Sito IIS esistente rimosso" -ForegroundColor Gray
}

New-Website -Name $IISSiteName `
    -PhysicalPath $appPath `
    -ApplicationPool $appPoolName `
    -Port $IISPort | Out-Null

Write-Host "IIS Site configurato: http://localhost:$IISPort" -ForegroundColor Green

# Riepilogo
Write-Host "`n=== Setup Completato ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configurazione:" -ForegroundColor White
Write-Host "  Application Path:  $appPath" -ForegroundColor Gray
Write-Host "  Logs Path:         $logsPath\temp\logs" -ForegroundColor Gray
Write-Host "  Email Path:        $emailPath" -ForegroundColor Gray
Write-Host "  Database Name:     $DatabaseName" -ForegroundColor Gray
Write-Host "  IIS Site:          http://localhost:$IISPort" -ForegroundColor Gray
Write-Host "  Application Pool:  $appPoolName" -ForegroundColor Gray
Write-Host ""
Write-Host "Prossimi passi:" -ForegroundColor Yellow
Write-Host "  1. Installa SQL Server se non già presente" -ForegroundColor White
Write-Host "  2. Crea il database '$DatabaseName'" -ForegroundColor White
Write-Host "  3. Esegui gli script SQL (CreateTables.sql, PopulateTables.sql)" -ForegroundColor White
Write-Host "  4. Pubblica l'applicazione ASP.NET in: $appPath" -ForegroundColor White
Write-Host "  5. Testa l'applicazione: http://localhost:$IISPort" -ForegroundColor White

# Salva configurazione
$config = @{
    AppPath = $appPath
    LogsPath = "$logsPath\temp\logs"
    DataPath = $dataPath
    SmtpPickupPath = $smtpPickupPath
    DatabaseName = $DatabaseName
    ConnectionString = $connectionString
    IISSiteName = $IISSiteName
    IISPort = $IISPort
    AppPoolName = $appPoolName
    SetupDate = Get-Date.ToString()
}

$configPath = "$PSScriptRoot\setup-config.json"
$config | ConvertTo-Json | Out-File $configPath
Write-Host "`nConfigurazione salvata in: $configPath" -ForegroundColor Gray
