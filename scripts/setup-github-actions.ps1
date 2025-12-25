# Setup GitHub Actions Azure Authentication
# This script creates a service principal for GitHub Actions

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  GitHub Actions Azure Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Load environment
if (-not $env:AZURE_SUBSCRIPTION_ID) {
    if (Test-Path ".env") {
        Write-Host "Loading .env file..." -ForegroundColor Gray
        Get-Content ".env" | ForEach-Object {
            if ($_ -match '^([^=]+)=(.*)$') {
                $name = $matches[1]
                $value = $matches[2].Trim('"')
                Set-Item -Path "env:$name" -Value $value
            }
        }
    }
}

$subscriptionId = $env:AZURE_SUBSCRIPTION_ID
$resourceGroup = $env:AZURE_RESOURCE_GROUP

if (-not $resourceGroup) {
    # Get from azd
    $resourceGroup = azd env get-values | Where-Object { $_ -match '^AZURE_RESOURCE_GROUP="?([^"]*)"?$' } | ForEach-Object { $matches[1] }
}

if (-not $subscriptionId -or -not $resourceGroup) {
    Write-Host "ERROR: Could not determine subscription and resource group" -ForegroundColor Red
    Write-Host "Please set AZURE_SUBSCRIPTION_ID in .env or run azd provision first" -ForegroundColor Yellow
    exit 1
}

Write-Host "Subscription ID: $subscriptionId" -ForegroundColor Cyan
Write-Host "Resource Group: $resourceGroup" -ForegroundColor Cyan
Write-Host ""

# Create service principal
Write-Host "Creating service principal for GitHub Actions..." -ForegroundColor Yellow
$spName = "sp-github-actions-devshop-$(Get-Date -Format 'yyyyMMdd')"

try {
    $sp = az ad sp create-for-rbac `
        --name $spName `
        --role Contributor `
        --scopes "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup" `
        --sdk-auth `
        --output json | ConvertFrom-Json
    
    $credentials = @{
        clientId = $sp.clientId
        clientSecret = $sp.clientSecret
        subscriptionId = $sp.subscriptionId
        tenantId = $sp.tenantId
    } | ConvertTo-Json -Compress
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  Service Principal Created!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Go to your GitHub repository settings:" -ForegroundColor White
    Write-Host "   https://github.com/gderossilive/devShopDemo/settings/secrets/actions" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "2. Click 'New repository secret'" -ForegroundColor White
    Write-Host ""
    Write-Host "3. Name: AZURE_CREDENTIALS" -ForegroundColor White
    Write-Host ""
    Write-Host "4. Value: Copy the JSON below" -ForegroundColor White
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host $credentials -ForegroundColor Gray
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This secret has been saved to: github-actions-credentials.json" -ForegroundColor Gray
    $credentials | Out-File "github-actions-credentials.json" -Encoding UTF8
    Write-Host ""
    Write-Host "⚠️  Keep this file secure and do not commit it to git!" -ForegroundColor Yellow
    Write-Host ""
    
} catch {
    Write-Host "ERROR: Failed to create service principal: $_" -ForegroundColor Red
    exit 1
}
