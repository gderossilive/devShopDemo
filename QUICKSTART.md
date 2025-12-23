# Quick Start Guide - devShop Application

## 🚀 Setup in 5 Minuti

### 1. Prerequisiti
- Windows Server/10/11
- SQL Server installato
- PowerShell come Amministratore

### 2. Clone/Download Repository

```powershell
cd C:\
# (oppure estrai lo ZIP in C:\Ignite2025SampleApp)
```

### 3. Esegui Setup Automatico

```powershell
cd C:\Ignite2025SampleApp\deployment

# Setup VM + IIS
.\Setup-WindowsVM.ps1 -SqlSaPassword "YourPassword123!"

# Setup Database
cd ..\database
.\Setup-Database.ps1
```

### 4. Deploy Applicazione

**Con Visual Studio:**
```
Apri src\devShop.sln
Right-click devShop -> Publish -> Folder: C:\inetpub\wwwroot\devShop
```

**Senza Visual Studio:**
```powershell
cd ..\deployment
.\Deploy-Application.ps1
```

### 5. Test

Apri browser: **http://localhost**

## 📖 Documentazione Completa

- [README.md](../README.md) - Panoramica completa
- [DEPLOYMENT.md](../docs/DEPLOYMENT.md) - Guida deployment dettagliata

## 🆘 Problemi?

```powershell
# Verifica stato
Get-WebAppPoolState -Name "devShopPool"
Get-Website -Name "devShop"
Get-Service -Name "MSSQL*"

# Restart tutto
Restart-WebAppPool -Name "devShopPool"
iisreset
```

## 📊 Struttura Progetto

```
Ignite2025SampleApp/
├── src/devShop/          # Applicazione ASP.NET
├── database/             # Script SQL
├── deployment/           # Script setup
├── scripts/              # Utility
└── docs/                 # Documentazione
```

## ✅ Checklist

- [ ] Setup VM completato
- [ ] Database creato e popolato
- [ ] Applicazione deployata
- [ ] http://localhost funziona
- [ ] Test acquisto prodotto OK

Buon lavoro! 🎉
