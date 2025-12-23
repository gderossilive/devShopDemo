<#
.SYNOPSIS
    Configura SMTP per devShop Application
.DESCRIPTION
    Configura il pickup directory per SMTP e verifica la configurazione
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$PickupDirectory = "C:\AppData\devShop\email"
)

Write-Host "=== Configure SMTP for devShop ===" -ForegroundColor Cyan

# Crea directory se non esiste
if (-not (Test-Path $PickupDirectory)) {
    New-Item -Path $PickupDirectory -ItemType Directory -Force | Out-Null
    Write-Host "Created pickup directory: $PickupDirectory" -ForegroundColor Gray
}

# Imposta permessi
try {
    $acl = Get-Acl $PickupDirectory
    
    # IIS_IUSRS
    $permission = "IIS_IUSRS","FullControl","ContainerInherit,ObjectInherit","None","Allow"
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
    $acl.SetAccessRule($accessRule)
    
    # NETWORK SERVICE (per compatibilità)
    $permission2 = "NETWORK SERVICE","FullControl","ContainerInherit,ObjectInherit","None","Allow"
    $accessRule2 = New-Object System.Security.AccessControl.FileSystemAccessRule $permission2
    $acl.SetAccessRule($accessRule2)
    
    Set-Acl $PickupDirectory $acl
    Write-Host "Permissions configured ✓" -ForegroundColor Green
}
catch {
    Write-Warning "Error setting permissions: $_"
}

# Verifica installazione SMTP Server (opzionale)
Write-Host "`nVerifying SMTP Server feature..."
$smtpFeature = Get-WindowsFeature -Name SMTP-Server -ErrorAction SilentlyContinue
if ($smtpFeature -and $smtpFeature.Installed) {
    Write-Host "  SMTP Server feature installed ✓" -ForegroundColor Green
}
else {
    Write-Host "  SMTP Server feature not installed" -ForegroundColor Yellow
    Write-Host "  Install with: Install-WindowsFeature -Name SMTP-Server -IncludeManagementTools" -ForegroundColor Gray
}

# Crea un file .eml di test
$testEmail = @"
From: test@devshop.com
To: customer@example.com
Subject: SMTP Test Email
Date: $(Get-Date -Format "ddd, dd MMM yyyy HH:mm:ss K")
MIME-Version: 1.0
Content-Type: text/plain; charset=utf-8

This is a test email to verify SMTP configuration.

SMTP Pickup Directory: $PickupDirectory

If you see this file, the SMTP configuration is working correctly.
Emails will be saved as .eml files in this directory.

devShop Team
"@

$testEmailFile = Join-Path $PickupDirectory "test-$(Get-Date -Format 'yyyyMMddHHmmss').eml"
$testEmail | Out-File $testEmailFile -Encoding UTF8
Write-Host "`nTest email created: $testEmailFile" -ForegroundColor Gray

Write-Host "`n=== SMTP Configuration Summary ===" -ForegroundColor Cyan
Write-Host "Pickup Directory: $PickupDirectory" -ForegroundColor White
Write-Host "Permissions: IIS_IUSRS, NETWORK SERVICE (Full Control)" -ForegroundColor White
Write-Host "`nEmails will be saved as .eml files in the pickup directory." -ForegroundColor Gray
Write-Host "You can open .eml files with Outlook or any email client." -ForegroundColor Gray

Write-Host "`n=== SMTP Configuration Completed ===" -ForegroundColor Cyan
