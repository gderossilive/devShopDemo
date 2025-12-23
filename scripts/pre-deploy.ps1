# Pre-Deploy Script for devShop Application
# Validates environment before deployment

[CmdletBinding()]
param()

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  devShop Pre-Deploy Validation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check required environment variables
$requiredVars = @(
    'SQL_SERVER_PRIVATE_IP',
    'SQL_ADMIN_USERNAME',
    'WEB_SERVER_NAME',
    'AZURE_RESOURCE_GROUP'
)

$missingVars = @()
foreach ($var in $requiredVars) {
    if (-not (Get-Item "env:$var" -ErrorAction SilentlyContinue)) {
        $missingVars += $var
    }
}

if ($missingVars.Count -gt 0) {
    Write-Host "ERROR: Missing required environment variables:" -ForegroundColor Red
    $missingVars | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    Write-Host ""
    Write-Host "Please run 'azd provision' first." -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] Environment variables validated" -ForegroundColor Green
Write-Host ""
Write-Host "Ready to deploy application to:" -ForegroundColor White
Write-Host "  Web Server: $env:WEB_SERVER_NAME" -ForegroundColor Cyan
Write-Host "  SQL Server: $env:SQL_SERVER_PRIVATE_IP" -ForegroundColor Cyan
Write-Host ""
