# devShop - Deployment Guide

Guida dettagliata per il deployment dell'applicazione devShop su Windows Server VM con SQL Server.

## 🎯 Obiettivo

Questa guida ti accompagna passo-passo nel deployment di devShop, un'applicazione ASP.NET 4.8 MVC, su un ambiente Windows Server on-premise.

## 📋 Checklist Pre-Deployment

Prima di iniziare, assicurati di avere:

- [ ] Windows Server 2019/2022 o Windows 10/11 Pro
- [ ] Privilegi di Amministratore
- [ ] SQL Server 2019/2022 installato e funzionante
- [ ] SQL Server Management Studio (SSMS) - opzionale ma consigliato
- [ ] .NET Framework 4.8 SDK
- [ ] Visual Studio 2019/2022 (Community Edition è sufficiente)
- [ ] PowerShell 5.1 o superiore
- [ ] Almeno 10 GB di spazio disco disponibile

## 🚀 Deployment Step-by-Step

### FASE 1: Verifica dell'Ambiente

#### Step 1.1: Verifica PowerShell

Apri PowerShell come **Amministratore** e verifica la versione:

```powershell
$PSVersionTable.PSVersion
# Deve essere >= 5.1
```

#### Step 1.2: Esegui Verifica Prerequisiti

```powershell
cd C:\path\to\Ignite2025SampleApp\deployment
.\Install-Prerequisites.ps1
```

Questo script verificherà:
- Windows Server
- .NET Framework 4.8
- IIS
- ASP.NET
- SQL Server
- PowerShell

**Output Atteso:**
```
✓ .NET Framework 4.8 installato
✓ PowerShell 5.0+ installato
✓ SQL Server installato
```

**Se mancano componenti**, lo script fornirà istruzioni per installarli.

---

### FASE 2: Setup Windows Server e IIS

#### Step 2.1: Esegui Setup VM

```powershell
.\Setup-WindowsVM.ps1 -SqlSaPassword "YourStrongPassword123!"
```

**Parametri opzionali:**
```powershell
.\Setup-WindowsVM.ps1 `
    -SqlSaPassword "YourStrongPassword123!" `
    -AppName "devShop" `
    -DatabaseName "l501devshopdb" `
    -IISSiteName "devShop" `
    -IISPort 80
```

#### Step 2.2: Verifica Setup

Lo script creerà:

1. **Directory Applicazione:**
   ```
   C:\inetpub\wwwroot\devShop
   ```

2. **Directory Logs:**
   ```
   C:\Logs\devShop\temp\logs
   H:\temp\logs (se H: disponibile)
   ```

3. **Directory Email:**
   ```
   C:\AppData\devShop\email
   K:\mountfs (se K: disponibile)
   ```

4. **Registry Key:**
   ```
   HKLM\Software\Devshop\DBConnection\ConnectionString
   ```

5. **IIS Site:**
   ```
   http://localhost (o porta specificata)
   ```

**Verifica manualmente:**

```powershell
# Verifica directories
Test-Path "C:\inetpub\wwwroot\devShop"
Test-Path "C:\Logs\devShop\temp\logs"
Test-Path "C:\AppData\devShop\email"

# Verifica Registry
Get-ItemProperty -Path "HKLM:\Software\Devshop\DBConnection" -Name "ConnectionString"

# Verifica IIS
Import-Module WebAdministration
Get-Website -Name "devShop"
Get-WebAppPoolState -Name "devShopPool"
```

**Output Atteso:**
```
Name     : devShop
State    : Started
```

---

### FASE 3: Setup Database SQL Server

#### Step 3.1: Verifica SQL Server

```powershell
# Verifica che SQL Server sia in esecuzione
Get-Service -Name "MSSQL*" | Where-Object {$_.Status -eq "Running"}
```

#### Step 3.2: Esegui Setup Database

**Opzione A - Windows Authentication (consigliato):**

```powershell
cd ..\database
.\Setup-Database.ps1 -ServerName "localhost" -DatabaseName "l501devshopdb"
```

**Opzione B - SQL Authentication:**

```powershell
.\Setup-Database.ps1 `
    -ServerName "localhost" `
    -DatabaseName "l501devshopdb" `
    -UseWindowsAuth $false `
    -SqlUsername "sa" `
    -SqlPassword "YourSqlPassword"
```

**Opzione C - Server Remoto:**

```powershell
.\Setup-Database.ps1 `
    -ServerName "SQL-SERVER-01" `
    -DatabaseName "l501devshopdb" `
    -UseWindowsAuth $true
```

#### Step 3.3: Verifica Database

Usa SQL Server Management Studio (SSMS) o sqlcmd:

```powershell
# Verifica database creato
sqlcmd -S localhost -E -Q "SELECT name FROM sys.databases WHERE name = 'l501devshopdb'"

# Verifica tabelle
sqlcmd -S localhost -d l501devshopdb -E -Q "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES"

# Conta record
sqlcmd -S localhost -d l501devshopdb -E -Q "SELECT 'Categories', COUNT(*) FROM Categories UNION SELECT 'Products', COUNT(*) FROM Products UNION SELECT 'Customers', COUNT(*) FROM Customers UNION SELECT 'Orders', COUNT(*) FROM Orders UNION SELECT 'OrderDetails', COUNT(*) FROM OrderDetails"
```

**Output Atteso:**
```
Categories  6
Products    25
Customers   10
Orders      10
OrderDetails 15
```

---

### FASE 4: Build e Deployment Applicazione

#### Opzione A: Deployment con Visual Studio (Consigliato)

1. **Apri la Solution:**
   ```
   File -> Open -> Project/Solution
   Seleziona: C:\path\to\Ignite2025SampleApp\src\devShop.sln
   ```

2. **Restore NuGet Packages:**
   ```
   Tools -> NuGet Package Manager -> Restore NuGet Packages
   ```

3. **Build la Solution:**
   ```
   Build -> Build Solution (Ctrl+Shift+B)
   ```

4. **Pubblica l'Applicazione:**
   ```
   Right-click su progetto "devShop" -> Publish
   Target: Folder
   Folder Path: C:\inetpub\wwwroot\devShop
   Configuration: Release
   Target Framework: net48
   Click: Publish
   ```

#### Opzione B: Deployment con Script PowerShell

```powershell
cd ..\deployment
.\Build-And-Deploy.ps1
```

**Con parametri personalizzati:**
```powershell
.\Build-And-Deploy.ps1 `
    -SolutionPath "C:\path\to\src\devShop.sln" `
    -TargetPath "C:\inetpub\wwwroot\devShop" `
    -Configuration "Release"
```

#### Step 4.1: Verifica Deployment

```powershell
# Verifica file copiati
$appPath = "C:\inetpub\wwwroot\devShop"
Test-Path "$appPath\Web.config"
Test-Path "$appPath\Global.asax"
Test-Path "$appPath\bin\devShop.dll"
Test-Path "$appPath\bin\EntityFramework.dll"

# Lista file principali
Get-ChildItem $appPath | Select-Object Name, LastWriteTime
```

#### Step 4.2: Restart Application Pool

```powershell
Import-Module WebAdministration
Restart-WebAppPool -Name "devShopPool"
Get-WebAppPoolState -Name "devShopPool"
```

---

### FASE 5: Testing e Verifica

#### Step 5.1: Test HTTP

Apri un browser e naviga a:
```
http://localhost
```

**Pagina Attesa:**
- Titolo: "Welcome to devShop!"
- Prodotti in evidenza visibili
- Menu categorie funzionante

#### Step 5.2: Test Funzionalità

1. **Test Navigation:**
   - Click su "Products" nel menu
   - Filtra per categoria
   - Click su un prodotto per vedere i dettagli

2. **Test Purchase Flow:**
   - Vai su un prodotto (es: "Laptop i7 16GB")
   - Inserisci email: `test@example.com`
   - Quantity: `1`
   - Click "Buy Now"
   - Verifica pagina di conferma con Order ID

3. **Test Database Update:**
   ```powershell
   sqlcmd -S localhost -d l501devshopdb -E -Q "SELECT TOP 1 OrderID, CustomerID, TotalAmount, OrderDate FROM Orders ORDER BY OrderDate DESC"
   ```

4. **Test Logging:**
   ```powershell
   Get-Content "C:\Logs\devShop\temp\logs\log.txt" -Tail 20
   ```

   **Output Atteso:**
   ```
   [2025-12-23 14:30:15] INFO  - devShop Application Started
   [2025-12-23 14:30:20] INFO  - Home/Index accessed
   [2025-12-23 14:30:25] INFO  - Products/Index accessed
   [2025-12-23 14:30:30] INFO  - Products/Details accessed, id: 6
   [2025-12-23 14:30:35] INFO  - Buy action: ProductID=6, Email=test@example.com
   ```

5. **Test Email Delivery:**
   ```powershell
   # Verifica file .eml creato
   Get-ChildItem "C:\AppData\devShop\email\*.eml" | 
       Sort-Object LastWriteTime -Descending | 
       Select-Object -First 1 |
       Get-Content
   ```

   **Output Atteso:**
   File .eml con conferma ordine.

---

### FASE 6: Configurazione Avanzata (Opzionale)

#### Configurazione Custom Connection String

Se vuoi usare SQL Authentication invece di Windows Auth:

```powershell
cd ..\scripts
.\Configure-Registry.ps1 -ConnectionString "Data Source=localhost;Initial Catalog=l501devshopdb;User Id=sa;Password=YourSqlPassword;TrustServerCertificate=True"
```

#### Configurazione Custom SMTP Path

```powershell
.\Configure-SMTP.ps1 -PickupDirectory "D:\EmailPickup"
```

Poi aggiorna `Web.config`:
```xml
<specifiedPickupDirectory pickupDirectoryLocation="D:\EmailPickup" />
```

#### Configurazione Custom Log Path

Modifica `Web.config`:
```xml
<file value="D:\ApplicationLogs\devShop\log.txt" />
```

#### Configurazione HTTPS

1. **Genera Certificato Self-Signed:**
   ```powershell
   $cert = New-SelfSignedCertificate -DnsName "localhost" -CertStoreLocation "Cert:\LocalMachine\My"
   ```

2. **Aggiungi Binding HTTPS in IIS:**
   ```powershell
   Import-Module WebAdministration
   New-WebBinding -Name "devShop" -Protocol https -Port 443
   $binding = Get-WebBinding -Name "devShop" -Protocol https
   $binding.AddSslCertificate($cert.Thumbprint, "My")
   ```

3. **Testa:**
   ```
   https://localhost
   ```

---

## 🔍 Troubleshooting

### Problema: Errore 500 - Internal Server Error

**Soluzione:**

1. Abilita detailed errors in `Web.config`:
   ```xml
   <customErrors mode="Off" />
   <httpErrors errorMode="Detailed" />
   ```

2. Controlla Event Viewer:
   ```
   eventvwr.msc -> Windows Logs -> Application
   ```

3. Controlla IIS logs:
   ```
   C:\inetpub\logs\LogFiles\W3SVC1\
   ```

### Problema: Connection String Error

**Soluzione:**

1. Verifica Registry:
   ```powershell
   Get-ItemProperty -Path "HKLM:\Software\Devshop\DBConnection" -Name "ConnectionString"
   ```

2. Testa connessione manualmente:
   ```powershell
   $connString = "Data Source=localhost;Initial Catalog=l501devshopdb;Integrated Security=True"
   $conn = New-Object System.Data.SqlClient.SqlConnection($connString)
   $conn.Open()
   $conn.State  # Deve essere "Open"
   $conn.Close()
   ```

3. Verifica che IIS Application Pool abbia accesso:
   - Application Pool Identity deve avere permessi sul database
   - Oppure usa SQL Authentication

### Problema: Log4net non scrive log

**Soluzione:**

1. Verifica directory esista:
   ```powershell
   Test-Path "C:\Logs\devShop\temp\logs"
   New-Item -Path "C:\Logs\devShop\temp\logs" -ItemType Directory -Force
   ```

2. Verifica permessi:
   ```powershell
   icacls "C:\Logs\devShop\temp\logs" /grant "IIS_IUSRS:(OI)(CI)F"
   ```

3. Verifica che log4net sia configurato in `Web.config`:
   ```xml
   <section name="log4net" type="log4net.Config.Log4NetConfigurationSectionHandler, log4net" />
   ```

### Problema: SMTP Email non salvate

**Soluzione:**

1. Verifica directory:
   ```powershell
   Test-Path "C:\AppData\devShop\email"
   New-Item -Path "C:\AppData\devShop\email" -ItemType Directory -Force
   ```

2. Verifica permessi:
   ```powershell
   icacls "C:\AppData\devShop\email" /grant "IIS_IUSRS:(OI)(CI)F"
   ```

3. Verifica `Web.config`:
   ```xml
   <smtp deliveryMethod="SpecifiedPickupDirectory">
     <specifiedPickupDirectory pickupDirectoryLocation="C:\AppData\devShop\email" />
   </smtp>
   ```

### Problema: Application Pool si ferma continuamente

**Soluzione:**

1. Verifica Event Viewer per errori
2. Aumenta timeout:
   ```powershell
   Set-ItemProperty "IIS:\AppPools\devShopPool" -Name "processModel.idleTimeout" -Value "00:00:00"
   Set-ItemProperty "IIS:\AppPools\devShopPool" -Name "recycling.periodicRestart.time" -Value "00:00:00"
   ```

3. Verifica che tutti i file DLL siano presenti in `bin/`

---

## 📊 Monitoring e Maintenance

### Log Files da Monitorare

1. **Application Logs (log4net):**
   ```
   C:\Logs\devShop\temp\logs\log.txt
   ```

2. **IIS Logs:**
   ```
   C:\inetpub\logs\LogFiles\W3SVC1\
   ```

3. **Windows Event Logs:**
   ```
   eventvwr.msc -> Windows Logs -> Application
   ```

4. **SQL Server Logs:**
   ```
   C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Log\ERRORLOG
   ```

### Performance Monitoring

```powershell
# CPU e Memory dell'Application Pool
Get-Counter "\Process(w3wp*)\% Processor Time"
Get-Counter "\Process(w3wp*)\Working Set"

# SQL Server
Get-Counter "\SQLServer:General Statistics\User Connections"
Get-Counter "\SQLServer:SQL Statistics\Batch Requests/sec"
```

### Backup Recommendation

**Database Backup:**
```sql
BACKUP DATABASE l501devshopdb 
TO DISK = 'C:\Backups\devShop_Full.bak' 
WITH FORMAT, INIT, NAME = 'Full Backup of devShop';
```

**Application Backup:**
```powershell
Compress-Archive -Path "C:\inetpub\wwwroot\devShop" -DestinationPath "C:\Backups\devShop_App_$(Get-Date -Format 'yyyyMMdd').zip"
```

---

## ✅ Deployment Checklist Finale

Dopo aver completato il deployment, verifica:

- [ ] IIS Site "devShop" è Started
- [ ] Application Pool "devShopPool" è Started  
- [ ] Database "l501devshopdb" contiene dati
- [ ] Homepage carica correttamente (http://localhost)
- [ ] Prodotti sono visibili
- [ ] Purchase flow funziona
- [ ] Log vengono scritti in C:\Logs\devShop\temp\logs\log.txt
- [ ] Email vengono salvate in C:\AppData\devShop\email
- [ ] Connection string è configurata nel Registry
- [ ] Permessi IIS_IUSRS sono corretti
- [ ] .NET Framework 4.8 è installato

---

## 🎓 Prossimi Passi

Ora che l'applicazione è deployata, puoi:

1. **Customizzare l'applicazione** modificando Views, Controllers, Models
2. **Aggiungere nuovi prodotti** nel database
3. **Configurare HTTPS** per produzione
4. **Implementare autenticazione** utenti
5. **Aggiungere un sistema di gestione ordini** admin
6. **Configurare backup automatici**
7. **Monitorare performance** con Application Insights o simili

---

**Buon deployment! 🚀**
