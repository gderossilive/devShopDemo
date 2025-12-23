<#
.SYNOPSIS
    Script di installazione componenti per devShop Application
.DESCRIPTION
    Equivalente di installcomponents.zip del lab LAB501
    Installa fonts, configura SMTP, log4net e altre dipendenze
.NOTES
    Eseguire come Amministratore
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$InstallPath = "C:\installscript"
)

$ErrorActionPreference = "Continue"
$logFile = "$InstallPath\install.txt"

# Crea directory di installazione
New-Item -Path $InstallPath -ItemType Directory -Force | Out-Null

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path $logFile -Value $logMessage
}

Write-Log "=== devShop Component Installation Started ==="
Write-Log "Installation Path: $InstallPath"

# 1. Crea directory per script
Write-Log "[1/7] Creating script directories..."
$scriptPath = "$InstallPath\script1"
New-Item -Path $scriptPath -ItemType Directory -Force | Out-Null
Write-Log "Script directory created: $scriptPath"

# 2. Installazione Fonts
Write-Log "[2/7] Installing custom fonts..."
$fontsPath = "$PSScriptRoot\..\assets\fonts"
if (Test-Path $fontsPath) {
    $fonts = Get-ChildItem $fontsPath -Filter *.ttf -ErrorAction SilentlyContinue
    foreach ($font in $fonts) {
        try {
            Copy-Item $font.FullName "C:\Windows\Fonts\" -Force
            Write-Log "  Font installed: $($font.Name)"
        }
        catch {
            Write-Log "  ERROR installing font $($font.Name): $_"
        }
    }
    Write-Log "Font installation completed"
}
else {
    Write-Log "Fonts directory not found, skipping font installation"
}

# 3. Configurazione log4net directories
Write-Log "[3/7] Configuring log4net directories..."
$logDir = "C:\Logs\devShop\temp\logs"
New-Item -Path $logDir -ItemType Directory -Force | Out-Null

# Crea anche H:\temp\logs se H: esiste (disco locale configurato nel lab)
if (Test-Path "H:\") {
    New-Item -Path "H:\temp\logs" -ItemType Directory -Force | Out-Null
    Write-Log "  Log directory created: H:\temp\logs"
}
else {
    Write-Log "  Drive H: not available, using C:\Logs\devShop\temp\logs"
}

# Imposta permessi per IIS
try {
    $acl = Get-Acl $logDir
    $permission = "IIS_IUSRS","FullControl","ContainerInherit,ObjectInherit","None","Allow"
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
    $acl.SetAccessRule($accessRule)
    Set-Acl $logDir $acl
    Write-Log "  Permissions set for IIS_IUSRS on log directory"
}
catch {
    Write-Log "  ERROR setting permissions: $_"
}

# 4. Configurazione SMTP directory
Write-Log "[4/7] Configuring SMTP pickup directory..."
$emailDir = "C:\AppData\devShop\email"
New-Item -Path $emailDir -ItemType Directory -Force | Out-Null

# Crea anche K:\mountfs se K: esiste (Azure File Share configurato nel lab)
if (Test-Path "K:\") {
    New-Item -Path "K:\mountfs" -ItemType Directory -Force | Out-Null
    Write-Log "  Email directory created: K:\mountfs"
}
else {
    Write-Log "  Drive K: not available, using C:\AppData\devShop\email"
}

try {
    $acl = Get-Acl $emailDir
    $permission = "IIS_IUSRS","FullControl","ContainerInherit,ObjectInherit","None","Allow"
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
    $acl.SetAccessRule($accessRule)
    Set-Acl $emailDir $acl
    Write-Log "  Permissions set for IIS_IUSRS on email directory"
}
catch {
    Write-Log "  ERROR setting permissions: $_"
}

# 5. Verifica IIS
Write-Log "[5/7] Verifying IIS installation..."
try {
    Import-Module WebAdministration -ErrorAction Stop
    Write-Log "  IIS module loaded successfully"
}
catch {
    Write-Log "  WARNING: IIS module not available: $_"
}

# 6. Verifica .NET Framework
Write-Log "[6/7] Verifying .NET Framework..."
try {
    $dotNetVersion = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -Name Release -ErrorAction SilentlyContinue
    if ($dotNetVersion -ge 528040) {
        Write-Log "  .NET Framework 4.8 detected (Release: $dotNetVersion)"
    }
    else {
        Write-Log "  WARNING: .NET Framework 4.8 not detected"
    }
}
catch {
    Write-Log "  ERROR checking .NET version: $_"
}

# 7. Crea file di test
Write-Log "[7/7] Creating test files..."
$testContent = @"
devShop Component Installation
Installation Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Installation Path: $InstallPath

Components Installed:
- Custom fonts (if available)
- Log4net directories
- SMTP pickup directories
- IIS permissions configured

This file can be used to verify the installation completed successfully.
"@

$testFile = "$InstallPath\installation-info.txt"
$testContent | Out-File $testFile -Encoding UTF8
Write-Log "  Test file created: $testFile"

# Riepilogo finale
Write-Log ""
Write-Log "=== Installation Summary ==="
Write-Log "Installation completed successfully"
Write-Log "Log file: $logFile"
Write-Log "Directories created:"
Write-Log "  - $scriptPath"
Write-Log "  - $logDir"
Write-Log "  - $emailDir"
Write-Log ""
Write-Log "=== Installation Completed ==="

# Copia questo log anche in c:\windows\adapters.txt come nel lab
try {
    Copy-Item $logFile "C:\Windows\adapters.txt" -Force
    Write-Log "Installation log copied to C:\Windows\adapters.txt"
}
catch {
    Write-Log "ERROR copying log to C:\Windows\adapters.txt: $_"
}

Write-Host "`nInstallation completed. Check $logFile for details." -ForegroundColor Green
