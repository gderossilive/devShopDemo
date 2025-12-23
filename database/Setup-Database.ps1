<#
.SYNOPSIS
    Setup completo del database SQL Server per devShop
.DESCRIPTION
    Crea il database e esegue gli script SQL per creare e popolare le tabelle
.EXAMPLE
    .\Setup-Database.ps1 -ServerName "localhost" -DatabaseName "l501devshopdb"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ServerName = "localhost",
    
    [Parameter(Mandatory=$false)]
    [string]$DatabaseName = "l501devshopdb",
    
    [Parameter(Mandatory=$false)]
    [switch]$UseWindowsAuth = $true,
    
    [Parameter(Mandatory=$false)]
    [string]$SqlUsername = "sa",
    
    [Parameter(Mandatory=$false)]
    [string]$SqlPassword
)

Write-Host "=== Setup Database devShop ===" -ForegroundColor Cyan
Write-Host "Server: $ServerName" -ForegroundColor Gray
Write-Host "Database: $DatabaseName" -ForegroundColor Gray

# Costruisci connection string
if ($UseWindowsAuth) {
    $connectionString = "Server=$ServerName;Database=master;Integrated Security=True;TrustServerCertificate=True"
    Write-Host "Autenticazione: Windows Authentication" -ForegroundColor Gray
} else {
    if (-not $SqlPassword) {
        $securePassword = Read-Host "Password per $SqlUsername" -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
        $SqlPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    }
    $connectionString = "Server=$ServerName;Database=master;User Id=$SqlUsername;Password=$SqlPassword;TrustServerCertificate=True"
    Write-Host "Autenticazione: SQL Authentication ($SqlUsername)" -ForegroundColor Gray
}

# Verifica connessione a SQL Server
Write-Host "`nVerifica connessione a SQL Server..." -ForegroundColor Yellow
try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    Write-Host "Connessione a SQL Server riuscita ✓" -ForegroundColor Green
    $connection.Close()
} catch {
    Write-Error "Impossibile connettersi a SQL Server: $_"
    Write-Host "`nVerifica che:" -ForegroundColor Yellow
    Write-Host "  1. SQL Server sia in esecuzione" -ForegroundColor White
    Write-Host "  2. Il nome del server sia corretto" -ForegroundColor White
    Write-Host "  3. Le credenziali siano corrette" -ForegroundColor White
    Write-Host "  4. Il firewall consenta la connessione" -ForegroundColor White
    exit 1
}

# 1. Crea database se non esiste
Write-Host "`n[1/3] Creazione database..." -ForegroundColor Yellow
$createDbQuery = @"
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'$DatabaseName')
BEGIN
    CREATE DATABASE [$DatabaseName];
    PRINT 'Database $DatabaseName creato';
END
ELSE
BEGIN
    PRINT 'Database $DatabaseName già esistente';
END
"@

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandText = $createDbQuery
    $command.ExecuteNonQuery() | Out-Null
    $connection.Close()
    Write-Host "Database creato/verificato ✓" -ForegroundColor Green
} catch {
    Write-Error "Errore durante la creazione del database: $_"
    exit 1
}

# 2. Esegui CreateTables.sql
Write-Host "`n[2/3] Creazione tabelle..." -ForegroundColor Yellow
$createTablesScript = Join-Path $PSScriptRoot "CreateTables.sql"

if (-not (Test-Path $createTablesScript)) {
    Write-Error "File CreateTables.sql non trovato: $createTablesScript"
    exit 1
}

try {
    if ($UseWindowsAuth) {
        sqlcmd -S $ServerName -d $DatabaseName -E -i $createTablesScript
    } else {
        sqlcmd -S $ServerName -d $DatabaseName -U $SqlUsername -P $SqlPassword -i $createTablesScript
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Tabelle create con successo ✓" -ForegroundColor Green
    } else {
        Write-Error "Errore durante la creazione delle tabelle"
        exit 1
    }
} catch {
    Write-Error "Errore durante l'esecuzione di CreateTables.sql: $_"
    exit 1
}

# 3. Esegui PopulateTables.sql
Write-Host "`n[3/3] Popolamento tabelle..." -ForegroundColor Yellow
$populateTablesScript = Join-Path $PSScriptRoot "PopulateTables.sql"

if (-not (Test-Path $populateTablesScript)) {
    Write-Error "File PopulateTables.sql non trovato: $populateTablesScript"
    exit 1
}

try {
    if ($UseWindowsAuth) {
        sqlcmd -S $ServerName -d $DatabaseName -E -i $populateTablesScript
    } else {
        sqlcmd -S $ServerName -d $DatabaseName -U $SqlUsername -P $SqlPassword -i $populateTablesScript
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Dati inseriti con successo ✓" -ForegroundColor Green
    } else {
        Write-Error "Errore durante il popolamento delle tabelle"
        exit 1
    }
} catch {
    Write-Error "Errore durante l'esecuzione di PopulateTables.sql: $_"
    exit 1
}

# Verifica finale
Write-Host "`n=== Verifica Database ===" -ForegroundColor Cyan

$verifyQuery = @"
USE [$DatabaseName];
SELECT 'Categories' AS TableName, COUNT(*) AS RecordCount FROM dbo.Categories
UNION ALL
SELECT 'Products', COUNT(*) FROM dbo.Products
UNION ALL
SELECT 'Customers', COUNT(*) FROM dbo.Customers
UNION ALL
SELECT 'Orders', COUNT(*) FROM dbo.Orders
UNION ALL
SELECT 'OrderDetails', COUNT(*) FROM dbo.OrderDetails;
"@

try {
    if ($UseWindowsAuth) {
        $connectionString = "Server=$ServerName;Database=$DatabaseName;Integrated Security=True;TrustServerCertificate=True"
    } else {
        $connectionString = "Server=$ServerName;Database=$DatabaseName;User Id=$SqlUsername;Password=$SqlPassword;TrustServerCertificate=True"
    }
    
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandText = $verifyQuery
    $reader = $command.ExecuteReader()
    
    while ($reader.Read()) {
        $tableName = $reader["TableName"]
        $count = $reader["RecordCount"]
        Write-Host "  $tableName : $count record" -ForegroundColor Gray
    }
    
    $reader.Close()
    $connection.Close()
} catch {
    Write-Warning "Impossibile verificare i dati: $_"
}

Write-Host "`n=== Setup Database Completato ===" -ForegroundColor Cyan
Write-Host "Database '$DatabaseName' pronto per l'uso!" -ForegroundColor Green
