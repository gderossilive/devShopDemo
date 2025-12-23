# devShop Dev Container

## Overview

This dev container provides a complete Azure development environment with all the tools needed to develop, deploy, and manage the devShop application on Azure.

## Installed Tools

### Azure Tools
- **Azure Developer CLI (azd)** - Simplified Azure deployment orchestration
- **Azure CLI (az)** - Azure resource management
- **Bicep** - Infrastructure as Code (included with Azure CLI)

### Development Tools
- **PowerShell 7+** - Cross-platform scripting for deployment automation
- **Git** - Version control
- **GitHub CLI (gh)** - GitHub integration for CI/CD
- **Docker** - Containerization support

### VS Code Extensions

Pre-installed extensions for enhanced productivity:
- **Azure Bicep** - Bicep language support and IntelliSense
- **Azure Developer CLI** - azd integration
- **Azure Account** - Azure authentication and subscription management
- **PowerShell** - PowerShell language support
- **C#** - ASP.NET development support
- **GitHub Copilot** - AI-powered code completion

## Quick Start

After the container is created, all tools are ready to use:

```bash
# Verify installations
azd version
az version
pwsh --version
git --version
gh --version
docker --version

# Authenticate to Azure
azd auth login
az login

# Deploy the application
azd up
```

## Container Features

### 1. Azure Developer CLI (azd)
- **Purpose**: Simplified deployment workflow
- **Commands**:
  - `azd init` - Initialize environment
  - `azd provision` - Create Azure resources
  - `azd deploy` - Deploy application
  - `azd up` - Provision + deploy in one command
  - `azd down` - Delete all resources

### 2. Azure CLI (az)
- **Purpose**: Direct Azure resource management
- **Commands**:
  - `az login` - Authenticate
  - `az account list` - List subscriptions
  - `az vm list` - List VMs
  - `az group show` - Show resource group details

### 3. Bicep
- **Purpose**: Infrastructure as Code
- **Files**: Located in `infra/` folder
- **Commands**:
  - `az bicep build` - Compile Bicep to ARM
  - `az deployment sub validate` - Validate templates

### 4. PowerShell
- **Purpose**: Deployment and configuration scripts
- **Scripts**: Located in `scripts/` and `deployment/` folders
- **Default Shell**: PowerShell is the default terminal

### 5. GitHub CLI
- **Purpose**: CI/CD pipeline management
- **Commands**:
  - `gh auth login` - Authenticate to GitHub
  - `azd pipeline config` - Setup GitHub Actions

## Development Workflow

### Initial Setup
```bash
# 1. Open in dev container (automatically installs everything)
# 2. Authenticate
azd auth login
az login

# 3. Initialize environment
azd init
```

### Daily Development
```bash
# Start VMs (if auto-shutdown happened)
az vm start --resource-group rg-{env} --name vm-web-{env}
az vm start --resource-group rg-{env} --name vm-sql-{env}

# Make code changes
# Edit files in src/devShop/

# Deploy updates
azd deploy

# Test changes
# Browse to http://{web-vm-fqdn}
```

### Infrastructure Changes
```bash
# Edit Bicep files in infra/

# Preview changes
azd provision --preview

# Apply changes
azd provision

# Or do both with azd up
azd up
```

## Terminal Configuration

**Default Shell**: PowerShell 7  
**Why**: PowerShell is cross-platform and matches the deployment scripts

To switch shells:
```bash
# Switch to bash
bash

# Switch back to PowerShell
pwsh
```

## VS Code Integration

### Bicep Support
- Syntax highlighting
- IntelliSense for Azure resources
- Validation and linting
- Template snippets

### Azure Account
- View subscriptions
- Browse resources
- Deploy directly from VS Code

### PowerShell
- Integrated debugging
- Script execution
- IntelliSense for cmdlets

## Customization

### Add More Extensions
Edit `.devcontainer/devcontainer.json`:
```json
"customizations": {
  "vscode": {
    "extensions": [
      "your-extension-id"
    ]
  }
}
```

### Add More Features
```json
"features": {
  "ghcr.io/devcontainers/features/node:1": {
    "version": "latest"
  }
}
```

### Change Default Shell
```json
"customizations": {
  "vscode": {
    "settings": {
      "terminal.integrated.defaultProfile.linux": "bash"
    }
  }
}
```

## Troubleshooting

### Tools Not Found
Rebuild the container:
1. Press `F1` or `Ctrl+Shift+P`
2. Select "Dev Containers: Rebuild Container"

### Authentication Issues
```bash
# Re-authenticate
azd auth login --use-device-code
az login --use-device-code
```

### Permission Issues
Some operations may require elevated permissions. The container runs as a non-root user by default for security.

## Post-Create Command

The container automatically runs a post-creation script that:
- Displays installed tool versions
- Shows a welcome message
- Verifies azd and az CLI are working

## Resource Links

- [Azure Developer CLI Docs](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Azure CLI Docs](https://learn.microsoft.com/cli/azure/)
- [Bicep Docs](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [PowerShell Docs](https://learn.microsoft.com/powershell/)
- [Dev Containers](https://containers.dev/)

## Benefits

✅ **Consistent Environment**: Everyone works with the same tools  
✅ **No Local Setup**: All tools in the container  
✅ **Pre-configured**: VS Code extensions and settings ready  
✅ **Isolated**: Doesn't affect host system  
✅ **Portable**: Works on Windows, Mac, Linux  
✅ **Cloud-Ready**: Deploy directly from the container  

## Next Steps

1. **Authenticate**: `azd auth login` and `az login`
2. **Deploy**: `azd up`
3. **Develop**: Edit code, deploy changes
4. **Monitor**: Check logs, manage resources

Happy coding! 🚀
