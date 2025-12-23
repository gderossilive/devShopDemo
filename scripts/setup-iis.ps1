# Setup IIS and configure devShop application
# This script runs on the Web VM via Custom Script Extension

param(
    [string]$SqlServerIp,
    [string]$SqlAdminUser,
    [string]$SqlAdminPass
)

$ErrorActionPreference = "Continue"
$logFile = "C:\setup-iis.log"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append
    Write-Host $Message
}

Write-Log "========================================="
Write-Log "Starting IIS Setup for devShop"
Write-Log "========================================="

# Install IIS and required features
Write-Log "Installing IIS and ASP.NET features..."
try {
    Install-WindowsFeature -Name Web-Server `
        -IncludeManagementTools `
        -IncludeAllSubFeature

    Install-WindowsFeature -Name Web-Asp-Net45 `
        -IncludeAllSubFeature

    Install-WindowsFeature -Name Web-Net-Ext45

    Write-Log "IIS installed successfully"
} catch {
    Write-Log "ERROR: Failed to install IIS: $_"
    exit 1
}

# Create application directories
Write-Log "Creating application directories..."
$appPath = "C:\inetpub\wwwroot\devShop"
$logsPath = "C:\Logs\devShop"
$emailPath = "C:\AppData\devShop\email"

New-Item -Path $appPath -ItemType Directory -Force | Out-Null
New-Item -Path $logsPath -ItemType Directory -Force | Out-Null
New-Item -Path $emailPath -ItemType Directory -Force | Out-Null

Write-Log "Directories created: $appPath, $logsPath, $emailPath"

# Set permissions for IIS_IUSRS
Write-Log "Setting folder permissions..."
$acl = Get-Acl $logsPath
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS_IUSRS", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($rule)
Set-Acl $logsPath $acl

$acl = Get-Acl $emailPath
$acl.SetAccessRule($rule)
Set-Acl $emailPath $acl

Write-Log "Permissions set successfully"

# Download and install .NET Framework 4.8 if not present
Write-Log "Checking .NET Framework version..."
$dotNetVersion = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Release

if ($dotNetVersion -lt 528040) {
    Write-Log ".NET Framework 4.8 not found, installing..."
    $dotNetInstaller = "C:\Temp\ndp48-web.exe"
    New-Item -Path "C:\Temp" -ItemType Directory -Force | Out-Null
    
    Invoke-WebRequest -Uri "https://download.visualstudio.microsoft.com/download/pr/2d6bb6b2-226a-4baa-bdec-798822606ff1/8494001c276a4b96804cde7829c04d7f/ndp48-x86-x64-allos-enu.exe" `
        -OutFile $dotNetInstaller `
        -UseBasicParsing

    Start-Process -FilePath $dotNetInstaller -ArgumentList "/q /norestart" -Wait
    Write-Log ".NET Framework 4.8 installed"
} else {
    Write-Log ".NET Framework 4.8 already installed"
}

# Install Web Deploy (for future deployments)
Write-Log "Installing Web Deploy..."
try {
    $webDeployUrl = "https://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi"
    $webDeployInstaller = "C:\Temp\WebDeploy.msi"
    
    Invoke-WebRequest -Uri $webDeployUrl -OutFile $webDeployInstaller -UseBasicParsing
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$webDeployInstaller`" /quiet /norestart" -Wait
    Write-Log "Web Deploy installed"
} catch {
    Write-Log "WARNING: Web Deploy installation failed: $_"
}

# Create IIS Application Pool
Write-Log "Creating IIS Application Pool..."
Import-Module WebAdministration

$poolName = "devShopPool"
if (-not (Test-Path "IIS:\AppPools\$poolName")) {
    New-WebAppPool -Name $poolName
    Set-ItemProperty "IIS:\AppPools\$poolName" -Name managedRuntimeVersion -Value "v4.0"
    Set-ItemProperty "IIS:\AppPools\$poolName" -Name enable32BitAppOnWin64 -Value $false
    Write-Log "Application pool '$poolName' created"
} else {
    Write-Log "Application pool '$poolName' already exists"
}

# Create IIS Website
Write-Log "Creating IIS Website..."
$siteName = "devShop"

if (Test-Path "IIS:\Sites\$siteName") {
    Remove-Website -Name $siteName
}

New-Website -Name $siteName `
    -PhysicalPath $appPath `
    -ApplicationPool $poolName `
    -Port 80 `
    -Force

Write-Log "IIS Website '$siteName' created"

# Create placeholder page
$placeholderHtml = @"
<!DOCTYPE html>
<html>
<head>
    <title>devShop - Setup Complete</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 50px; background: #f0f0f0; }
        .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        h1 { color: #0078d4; }
        .info { background: #e7f3ff; padding: 15px; margin: 20px 0; border-left: 4px solid #0078d4; }
    </style>
</head>
<body>
    <div class="container">
        <h1>devShop Application</h1>
        <p>IIS setup completed successfully!</p>
        <div class="info">
            <strong>Status:</strong> Ready for deployment<br>
            <strong>SQL Server:</strong> $SqlServerIp<br>
            <strong>Next Step:</strong> Run 'azd deploy' to deploy the application
        </div>
    </div>
</body>
</html>
"@

Set-Content -Path (Join-Path $appPath "index.html") -Value $placeholderHtml
Write-Log "Placeholder page created"

# Configure connection string in registry (for compatibility)
Write-Log "Configuring connection string in registry..."
$regPath = "HKLM:\Software\Devshop\DBConnection"
if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}

$connectionString = "Server=$SqlServerIp;Database=devShopDB;User Id=$SqlAdminUser;Password=$SqlAdminPass;TrustServerCertificate=True;"
Set-ItemProperty -Path $regPath -Name "ConnectionString" -Value $connectionString
Write-Log "Connection string stored in registry"

# Restart IIS
Write-Log "Restarting IIS..."
iisreset /restart

Write-Log "========================================="
Write-Log "IIS Setup Completed Successfully!"
Write-Log "========================================="
Write-Log "Application ready at: http://localhost"

exit 0
