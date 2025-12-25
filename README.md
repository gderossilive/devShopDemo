# devShop Application - Azure Two-Tier Architecture

Applicazione ASP.NET 4.8 basata sul **Microsoft Ignite 2025 LAB501**, modernizzata per deployment su **Azure** con architettura a due livelli: **VM IIS** (frontend) e **VM SQL Server** (backend).

## 📋 Panoramica

Questo progetto ricrea l'applicazione **devShop** del lab LAB501 con un'architettura cloud-native su Azure:

| Componente Originale | Implementazione Azure |
|----------------------|----------------------|
| Web Application | Windows Server VM + IIS |
| Database | SQL Server 2022 VM (marketplace image) |
| Networking | Azure VNet con subnet separate |
| Security | Network Security Groups (NSG) |
| Deployment | Azure Developer CLI (azd) + Bicep |
| Configuration | Registry di Windows + Azure Storage |

## 🏗️ Architettura

```
┌─────────────────────────────────────────────────────────────┐
│                     Azure Subscription                       │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │           Resource Group: rg-{environmentName}         │ │
│  │                                                        │ │
│  │  ┌──────────────────────────────────────────────┐     │ │
│  │  │         Virtual Network (10.0.0.0/16)        │     │ │
│  │  │                                               │     │ │
│  │  │  ┌─────────────────┐  ┌──────────────────┐   │     │ │
│  │  │  │  Web Subnet     │  │  Database Subnet │   │     │ │
│  │  │  │  (10.0.1.0/24)  │  │  (10.0.2.0/24)   │   │     │ │
│  │  │  │                 │  │                  │   │     │ │
│  │  │  │  ┌───────────┐  │  │  ┌────────────┐  │   │     │ │
│  │  │  │  │  Web VM   │  │  │  │  SQL VM    │  │   │     │ │
│  │  │  │  │  + IIS    │◄─┼──┼─►│ SQL Server │  │   │     │ │
│  │  │  │  │  + .NET   │  │  │  │ 2022 Dev   │  │   │     │ │
│  │  │  │  └───────────┘  │  │  └────────────┘  │   │     │ │
│  │  │  │       ▲         │  │                  │   │     │ │
│  │  │  └───────┼─────────┘  └──────────────────┘   │     │ │
│  │  └──────────┼────────────────────────────────────┘     │ │
│  │             │                                          │ │
│  │        Public IP                                       │ │
│  │        (HTTP/HTTPS)                                    │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start (Azure Deployment)
│  │  SQL Server                      │  │
│  │  └─ devShopDB                    │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  File System (Azure VM)          │  │
│  │  ├─ C:\Logs\devShop (log4net)    │  │
│  │  └─ C:\AppData\devShop\email     │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  Windows Registry                │  │
│  │  └─ HKLM\Software\Devshop\...    │  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### Prerequisiti

- **Azure Subscription** con permessi di creazione risorse
- **Azure Developer CLI (azd)** - [Installazione](https://aka.ms/azd-install)
- **Azure CLI** - [Installazione](https://aka.ms/azcli)
- **PowerShell 7+** - Per script di configurazione
- **Bash** - Per lo script di deployment automatico
- **Git** - Per clonare il repository

### Deployment Automatico (1 comando!)

```bash
# 1. Copia il file di configurazione e modifica i valori
cp .env.example .env
# Modifica .env con le tue password e il tuo IP pubblico

# 2. Esegui lo script di deployment automatico
./deploy.sh devShop
```

**Tempo stimato**: 4-5 minuti

Dopo il deployment:
- Accedi all'applicazione tramite l'URL mostrato in output
- RDP limitato al tuo IP (se configurato MY_IP in .env)
- VMs si spengono automaticamente alle 19:00 UTC (risparmio ~50%)

### Deployment Manuale (metodo alternativo)

```bash
# 1. Login
azd auth login

# 2. Configurazione ambiente
export SQL_ADMIN_USERNAME=sqladmin
export SQL_ADMIN_PASSWORD="YourStrongPass123!"
export WEB_ADMIN_USERNAME=webadmin
export WEB_ADMIN_PASSWORD="YourStrongPass456!"
export MY_IP="YOUR_PUBLIC_IP"  # Opzionale: restringe RDP al tuo IP

# 3. Deploy completo
azd up
```

📖 **Guida completa**: [docs/AZURE_DEPLOYMENT.md](docs/AZURE_DEPLOYMENT.md)

## 📁 Struttura del Progetto

```
Ignite2025SampleApp/
├── infra/                    # Infrastructure as Code (Bicep)
│   ├── main.bicep           # Orchestrator principale
│   ├── network.bicep        # VNet, Subnets, NSGs (con RDP IP restriction)
│   ├── sqlvm.bicep          # SQL Server VM (B-series + auto-shutdown)
│   ├── webvm.bicep          # IIS Web VM (B-series + auto-shutdown)
│   └── main.parameters.json # Parametri deployment (include MY_IP)
├── src/devShop/              # Applicazione ASP.NET 4.8
│   ├── Controllers/          # MVC Controllers
│   ├── Models/              # Entity Framework Models
│   ├── Views/               # Razor Views
│   ├── App_Start/           # Configurazione MVC
│   ├── Web.config           # Configurazione applicazione
│   └── devShop.csproj       # Project file
├── database/                 # Script SQL Server
│   ├── CreateTables.sql     # Schema database
│   ├── PopulateTables.sql   # Dati di esempio
│   └── Setup-Database.ps1   # Setup automatico DB
├── scripts/                  # Script deployment/configurazione
│   ├── configure-vms.ps1    # Post-provision: DB setup + IIS install
│   ├── post-provision.ps1   # Hook azd (legacy)
│   ├── pre-deploy.ps1       # Hook azd pre-deployment
│   ├── setup-iis.ps1        # Setup IIS su Web VM
│   ├── Configure-Registry.ps1
│   └── Configure-SMTP.ps1
├── deployment/               # Script legacy (on-premise)
│   └── [Script PowerShell per deployment manuale]
├── .devcontainer/            # VS Code Dev Container
│   └── devcontainer.json    # Azure development environment
├── deploy.sh                 # Script deployment automatico
├── .env.example              # Template variabili ambiente
├── .env                      # Configurazione deployment (gitignored)
├── azure.yaml                # Configurazione azd + hooks
└── docs/
    ├── AZURE_DEPLOYMENT.md   # Guida deployment Azure
    └── DEPLOYMENT.md         # Guida deployment on-premise (legacy)
```

## 🛠️ Tecnologie Utilizzate

### Infrastruttura Azure
- **Azure Virtual Machines**: Windows Server 2022 per Web e SQL
- **Azure Virtual Network**: Isolamento rete con subnets
- **Network Security Groups**: Firewall regole traffico
- **Azure Storage**: Blob storage per script deployment
- **Bicep**: Infrastructure as Code
- **Azure Developer CLI (azd)**: Orchestrazione deployment

### Application Stack
- **ASP.NET MVC 5** (.NET Framework 4.8)
- **Entity Framework 6.4.4** (Code First)
- **SQL Server 2022 Developer Edition**
- **IIS 10.0+** (Windows Server 2022)
- **Bootstrap 3.4.1** (UI Framework)
- **log4net 2.0.15** (Logging)

### Deployment & DevOps
- **PowerShell 7+**: Script automazione
- **Custom Script Extension**: Configurazione automatica VMs
- **Azure CLI**: Gestione risorse Azure
- **MSBuild**: Compilazione applicazione .NET

## 🔧 Comandi Utili

### Gestione Environment

```bash
# Visualizzare tutte le variabili d'ambiente
azd env get-values

# Aggiornare una variabile
azd env set VARIABLE_NAME "value"

# Visualizzare stato risorse
az group show --name rg-{environmentName}
```

### Gestione VMs

```bash
# ✅ Auto-shutdown già configurato: VMs si spengono automaticamente alle 19:00 UTC
# Risparmio: ~50% sui costi delle VM

# Avviare le VMs manualmente (es. al mattino)
az vm start --resource-group rg-{environmentName} --name vm-web-{environmentName}
az vm start --resource-group rg-{environmentName} --name vm-sql-{environmentName}

# Fermare le VMs manualmente (se necessario prima delle 19:00)
az vm deallocate --resource-group rg-{environmentName} --name vm-web-{environmentName}
az vm deallocate --resource-group rg-{environmentName} --name vm-sql-{environmentName}

# Modificare orario auto-shutdown (da Azure Portal o CLI)
az vm auto-shutdown --resource-group rg-{environmentName} --name vm-web-{environmentName} --time 2100  # 9 PM
```

### 💰 Ottimizzazione Costi

Questo deployment include ottimizzazioni significative per ridurre i costi:

**VM Sizes ottimizzate (B-series)**:
- **Web VM**: Standard_B2ms (~€60/mese) invece di D2s_v5 (~€80/mese) - **25% risparmio**
- **SQL VM**: Standard_B4ms (~€120/mese) invece di D4s_v5 (~€160/mese) - **25% risparmio**

**Auto-shutdown** (19:00 UTC daily):
- Spegnimento automatico ogni sera = **~50% risparmio aggiuntivo**
- Costo mensile totale: **~€90/mese** (con auto-shutdown 12h/giorno)
- Costo senza ottimizzazioni: **~€240/mese** (VM accese 24/7)

**💡 Risparmio totale: ~€150/mese (62%)**

**Sicurezza RDP**:
- Impostando `MY_IP` in `.env`, l'accesso RDP è limitato solo al tuo IP pubblico
- Riduce drasticamente la superficie di attacco
- Nessun costo aggiuntivo

### Database Management

```powershell
# Eseguire setup database manualmente
cd database
.\Setup-Database.ps1 -ServerName {sql-vm-ip} -SqlAuthMode -AdminUsername sqladmin
```

### Logs e Troubleshooting

Connettiti via RDP alla Web VM:
- **Application logs**: `C:\Logs\devShop\log.txt`
- **IIS logs**: `C:\inetpub\logs\LogFiles`
- **Setup logs**: `C:\setup-iis.log`
- **Email pickup**: `C:\AppData\devShop\email`

## 🧪 Testing

### Test Locali (Post-Deployment)

1. **Homepage**: http://{web-vm-fqdn}
2. **Product List**: http://{web-vm-fqdn}/Products
3. **Product Details**: http://{web-vm-fqdn}/Products/Details/1
4. **Purchase Flow**: Clicca "Buy Now" su un prodotto

### Verifiche Database

```sql
-- Connettiti al SQL Server VM
-- Verifica tabelle
USE devShopDB;
SELECT * FROM Products;
SELECT * FROM Categories;
SELECT * FROM Customers;
SELECT * FROM Orders;
```

## 🔒 Sicurezza

### Network Security

- **Web Subnet**: Consente HTTP/HTTPS da Internet, RDP limitato (vedi sotto)
- **Database Subnet**: Consente solo SQL (1433) da Web Subnet
- **NSG Rules**: Deny all by default, allow espliciti per traffico necessario
- **Private IP**: SQL Server accessibile solo via private IP dalla Web VM
- **RDP IP Restriction**: Se `MY_IP` è configurato in `.env`, RDP è accessibile SOLO da quell'IP

### Credentials Management

- **Passwords**: Stored in azd environment (encrypted)
- **Connection String**: Stored in Windows Registry su Web VM
- **SQL Authentication**: Username/password per connessione applicazione
- **Environment Variables**: File `.env` contiene secrets (gitignored per sicurezza)

### Best Practices

1. ✅ **RDP IP Restriction**: Imposta `MY_IP` in `.env` con il tuo IP pubblico
2. **Cambia password di default** dopo il primo deployment
3. **Configura SSL/TLS** per traffico HTTPS
4. **Abilita Azure Backup** per VMs e SQL Server
5. **Usa Azure Key Vault** per production (sostituire Registry)
6. **Non committare** il file `.env` nel repository (già in .gitignore)

## 📊 Monitoring

### Azure Monitor

Dopo deployment, configura:
- **VM Insights**: Monitoraggio performance VMs
- **Log Analytics**: Centralizzazione logs
- **Alerts**: Notifiche per CPU, memoria, disk usage

### Application Monitoring

- **log4net logs**: `C:\Logs\devShop\log.txt`
- **IIS logs**: `C:\inetpub\logs\LogFiles\W3SVC1\`
- **Event Viewer**: Windows logs applicativi

## 🚀 Performance Optimization

### Web VM
- **VM Size**: Standard_B2ms (2 vCPUs, 8GB RAM, burstable)
  - B-series VMs: ottime per carichi variabili, accumula crediti CPU
  - **Cost-effective**: ~€60/mese vs €80/mese D-series
- **Scale Up**: Cambia VM size per più risorse (es. B4ms per più performance)
- **IIS Tuning**: Application pool settings, output caching

### SQL VM
- **VM Size**: Standard_B4ms (4 vCPUs, 16GB RAM, burstable)
  - B-series VMs: perfetto per dev/test, accumula crediti CPU per burst
  - **Cost-effective**: ~€120/mese vs €160/mese D-series
- **Storage**: OS disk standard (sufficiente per dev/test)
- **SQL Tuning**: Indexes, statistics, query optimization
- **Production**: Considera D-series o E-series per workload costanti

## 🧹 Cleanup

### Rimuovere Tutto

```bash
# Elimina tutte le risorse Azure
azd down --purge --force
```

### Rimuovere Solo l'Applicazione

```bash
# Mantiene infrastruttura, rimuove solo app deployment
# (Connettiti via RDP e rimuovi da IIS)
```

## 📚 Documentazione

- **[Guida Azure Deployment](docs/AZURE_DEPLOYMENT.md)**: Guida completa deployment Azure
- **[Guida On-Premise (Legacy)](docs/DEPLOYMENT.md)**: Deployment tradizionale Windows Server
- **[Azure Developer CLI Docs](https://learn.microsoft.com/azure/developer/azure-developer-cli/)**: Documentazione azd ufficiale
- **[Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)**: Infrastructure as Code

## 🤝 Support

Per problemi o domande:

1. **Controlla i logs**: `C:\Logs\devShop\log.txt` e `C:\setup-iis.log`
2. **Verifica NSG rules**: Assicurati che il traffico sia consentito
3. **Testa connectivity**: `Test-NetConnection` da Web VM a SQL VM porta 1433
4. **Controlla VM extensions**: `az vm extension list`

## 📝 Note

### Differenze da LAB501 Originale

| LAB501 (Azure PaaS) | Questa Implementazione (Azure IaaS) |
|---------------------|--------------------------------------|
| Azure App Service | Windows Server VM + IIS |
| Azure SQL Database | SQL Server 2022 su VM |
| Azure Key Vault | Windows Registry |
| Azure Storage File Share | Directory locali su VM |
| ARM Templates | Bicep + azd |
| App Service Deploy | Web Deploy / Custom Script Extension |

### Vantaggi Architettura IaaS

✅ **Controllo completo**: Full access a IIS e SQL Server  
✅ **Migrazione semplice**: Simile a on-premise  
✅ **Customizzazione**: Qualsiasi configurazione IIS/SQL  
✅ **Debug facile**: RDP access diretto  

### Considerazioni Production

Per ambienti produttivi, considera:
- **Azure App Service** + **Azure SQL Database** (managed PaaS)
- **Azure Application Gateway** per load balancing e WAF
- **Availability Zones** per high availability
- **Azure Backup** automatico
- **Azure Key Vault** per secrets management
- **Application Insights** per APM

## 🎓 Learning Path

Questo progetto dimostra:
1. ✅ Infrastructure as Code con **Bicep**
2. ✅ Multi-tier architecture su **Azure VMs**
3. ✅ Network segmentation con **VNet e NSGs**
4. ✅ Automated deployment con **Azure Developer CLI**
5. ✅ Custom Script Extensions per **VM configuration**
6. ✅ ASP.NET deployment su **IIS in Azure**
7. ✅ SQL Server management su **Azure VMs**

## 📄 Licenza

Basato su Microsoft Ignite 2025 LAB501 - Adattato per deployment Azure IaaS.

---

**Deployment Status**: ✅ Production Ready  
**Last Updated**: December 2025  
**Azure Compatibility**: ✅ Tested on Azure Commercial Cloud

## 🔧 Configurazione Dettagliata

### Connection String

La connection string è salvata nel **Windows Registry**:

```
Path: HKLM\Software\Devshop\DBConnection
Key: ConnectionString
Value: Data Source=localhost;Initial Catalog=l501devshopdb;Integrated Security=True;TrustServerCertificate=True
```

Per modificarla:

```powershell
cd scripts
.\Configure-Registry.ps1 -ConnectionString "Data Source=YOUR_SERVER;Initial Catalog=l501devshopdb;User Id=sa;Password=YOUR_PASSWORD;TrustServerCertificate=True"
```

### Log4net Configuration

I log vengono salvati in:
- **Primario**: `H:\temp\logs\log.txt` (se disco H: disponibile)
- **Fallback**: `C:\Logs\devShop\temp\logs\log.txt`

Configurato in `Web.config`:

```xml
<log4net>
  <appender name="RollingFileAppender" type="log4net.Appender.RollingFileAppender">
    <file value="H:\temp\logs\log.txt" />
    ...
  </appender>
</log4net>
```

### SMTP Configuration

Gli email vengono salvati come file `.eml` in:
- **Primario**: `K:\mountfs` (se disco K: disponibile)
- **Fallback**: `C:\AppData\devShop\email`

Configurato in `Web.config`:

```xml
<system.net>
  <mailSettings>
    <smtp deliveryMethod="SpecifiedPickupDirectory">
      <specifiedPickupDirectory pickupDirectoryLocation="K:\mountfs" />
    </smtp>
  </mailSettings>
</system.net>
```

Per configurare:

```powershell
cd scripts
.\Configure-SMTP.ps1 -PickupDirectory "C:\AppData\devShop\email"
```

### IIS Configuration

- **Site Name**: devShop
- **Application Pool**: devShopPool
- **Runtime**: .NET v4.0
- **Pipeline Mode**: Integrated
- **Port**: 80
- **Physical Path**: `C:\inetpub\wwwroot\devShop`

Per riconfigurare IIS:

```powershell
cd deployment
.\Configure-IIS.ps1
```

## 📊 Database Schema

### Tabelle

1. **Categories** - Categorie prodotti
2. **Products** - Prodotti in catalogo
3. **Customers** - Clienti
4. **Orders** - Ordini
5. **OrderDetails** - Dettagli ordini

### Dati di Esempio

- 6 Categorie (Electronics, Computers, Software, Gaming, Networking, Accessories)
- 25 Prodotti
- 10 Clienti
- 10 Ordini con dettagli

## 🛠️ Troubleshooting

### L'applicazione non si avvia

1. Verifica che l'Application Pool sia avviato:
   ```powershell
   Import-Module WebAdministration
   Get-WebAppPoolState -Name "devShopPool"
   Start-WebAppPool -Name "devShopPool"
   ```

2. Controlla i permessi:
   ```powershell
   icacls "C:\inetpub\wwwroot\devShop" /grant "IIS_IUSRS:(OI)(CI)RX"
   ```

3. Verifica il log di IIS:
   ```
   C:\inetpub\logs\LogFiles\W3SVC1\
   ```

### Errore di connessione al database

1. Verifica la connection string nel Registry:
   ```powershell
   Get-ItemProperty -Path "HKLM:\Software\Devshop\DBConnection" -Name "ConnectionString"
   ```

2. Testa la connessione SQL:
   ```powershell
   sqlcmd -S localhost -d l501devshopdb -E -Q "SELECT COUNT(*) FROM Products"
   ```

3. Verifica che SQL Server sia in esecuzione:
   ```powershell
   Get-Service -Name "MSSQL*"
   ```

### I log non vengono creati

1. Verifica che la directory esista:
   ```powershell
   Test-Path "H:\temp\logs"
   # Se non esiste, i log andranno in C:\Logs\devShop\temp\logs
   ```

2. Verifica i permessi:
   ```powershell
   icacls "C:\Logs\devShop\temp\logs" /grant "IIS_IUSRS:(OI)(CI)F"
   ```

### Le email non vengono salvate

1. Verifica la directory SMTP:
   ```powershell
   Test-Path "K:\mountfs"
   # Se non esiste, usa C:\AppData\devShop\email
   ```

2. Aggiorna Web.config con il percorso corretto:
   ```xml
   <specifiedPickupDirectory pickupDirectoryLocation="C:\AppData\devShop\email" />
   ```

## 🔄 Differenze rispetto al LAB501 Azure

### Cosa è stato mantenuto

✅ Logica applicazione identica  
✅ Database schema uguale  
✅ Funzionalità di acquisto prodotti  
✅ Sistema di logging log4net  
✅ SMTP delivery con file .eml  
✅ Connection string dal Registry  

### Cosa è stato adattato

🔄 **Azure SQL Database** → **SQL Server on-premise**  
🔄 **Azure App Service** → **IIS su Windows Server**  
🔄 **Azure Key Vault** → **Windows Registry**  
🔄 **Azure Storage File Share** → **Cartelle locali/SMB**  
🔄 **Azure Bastion** → **RDP diretto**  
🔄 **Managed Instance** → **Application Pool IIS**  

### Cosa non è applicabile

❌ Azure Portal deployment  
❌ Azure Resource Manager (ARM) templates  
❌ Azure CLI (az) commands  
❌ VNet integration  
❌ User Managed Identity  

## 📚 Script Reference

### deployment/Setup-WindowsVM.ps1

Setup completo dell'ambiente Windows Server.

**Parametri:**
- `-SqlSaPassword` (richiesto): Password per SQL Server
- `-AppName`: Nome applicazione (default: "devShop")
- `-DatabaseName`: Nome database (default: "l501devshopdb")
- `-IISSiteName`: Nome sito IIS (default: "devShop")
- `-IISPort`: Porta IIS (default: 80)

**Esempio:**
```powershell
.\Setup-WindowsVM.ps1 -SqlSaPassword "MyP@ssw0rd123" -IISPort 8080
```

### database/Setup-Database.ps1

Setup database SQL Server.

**Parametri:**
- `-ServerName`: Nome server (default: "localhost")
- `-DatabaseName`: Nome database (default: "l501devshopdb")
- `-UseWindowsAuth`: Usa Windows Auth (default: $true)
- `-SqlUsername`: Username SQL (se non Windows Auth)
- `-SqlPassword`: Password SQL (se non Windows Auth)

**Esempio:**
```powershell
.\Setup-Database.ps1 -ServerName "SQL-SERVER-01" -UseWindowsAuth $false -SqlUsername "sa" -SqlPassword "P@ssw0rd"
```

### deployment/Build-And-Deploy.ps1

Build e deployment dell'applicazione.

**Parametri:**
- `-SolutionPath`: Percorso solution file
- `-TargetPath`: Directory di deployment (default: "C:\inetpub\wwwroot\devShop")
- `-Configuration`: Configurazione build (default: "Release")

**Esempio:**
```powershell
.\Build-And-Deploy.ps1 -Configuration Debug -TargetPath "D:\websites\devShop"
```

## 🎯 Testing dell'Applicazione

### 1. Test Funzionalità Base

1. **Homepage**: Verifica che carichi i prodotti in evidenza
2. **Products**: Naviga alle varie categorie
3. **Product Details**: Clicca su un prodotto
4. **Purchase**: Prova ad acquistare un prodotto

### 2. Test Logging

```powershell
# Verifica che i log vengano creati
Get-Content "H:\temp\logs\log.txt" -Tail 10
# oppure
Get-Content "C:\Logs\devShop\temp\logs\log.txt" -Tail 10
```

### 3. Test Email

Dopo un acquisto, verifica che l'email sia stata salvata:

```powershell
Get-ChildItem "K:\mountfs\*.eml" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
# oppure
Get-ChildItem "C:\AppData\devShop\email\*.eml" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
```

Apri il file .eml con Outlook o un editor di testo.

### 4. Test Database

```powershell
sqlcmd -S localhost -d l501devshopdb -E -Q "SELECT TOP 5 * FROM Products"
sqlcmd -S localhost -d l501devshopdb -E -Q "SELECT TOP 5 * FROM Orders ORDER BY OrderDate DESC"
```

## 📖 Risorse Aggiuntive

- [LAB501 Original Documentation](https://github.com/microsoft/ignite25-LAB501-modernizing-aspnet-applications-with-azure-migrate-and-github-copilot/blob/main/docs/lab501instruction.md)
- [IIS Configuration Reference](https://learn.microsoft.com/en-us/iis/)
- [SQL Server Documentation](https://learn.microsoft.com/en-us/sql/)
- [ASP.NET MVC 5](https://learn.microsoft.com/en-us/aspnet/mvc/overview/getting-started/)
- [Entity Framework 6](https://learn.microsoft.com/en-us/ef/ef6/)
- [log4net Documentation](https://logging.apache.org/log4net/)

## 📝 License

Questo progetto è basato sul Microsoft Ignite 2025 LAB501 ed è fornito per scopi educativi e di testing.

## 🤝 Contributing

Contributi, issue e feature request sono benvenuti!

---

**Autore:** Basato su Microsoft Ignite 2025 LAB501  
**Data:** Dicembre 2025  
**Versione:** 1.0  
