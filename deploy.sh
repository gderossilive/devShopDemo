#!/usr/bin/env bash
# Automated deployment script for devShop Azure environment
# Usage: ./deploy.sh [environment-name]

set -euo pipefail

BLUE="\033[1;34m"
GREEN="\033[1;32m"
RED="\033[1;31m"
RESET="\033[0m"

log_info() {
  printf "%b[%s]%b %s\n" "$BLUE" "INFO" "$RESET" "$1"
}

log_success() {
  printf "%b[%s]%b %s\n" "$GREEN" "DONE" "$RESET" "$1"
}

log_error() {
  printf "%b[%s]%b %s\n" "$RED" "ERR" "$RESET" "$1" >&2
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log_error "Command '$1' not found. Please install it before running this script."
    exit 1
  fi
}

usage() {
  cat <<'EOF'
Automated deployment of the devShop sample to Azure using Azure Developer CLI (azd).

Usage:
  ./deploy.sh [environment-name]

Environment variables (required):
  SQL_ADMIN_USERNAME   - SQL Server administrator username
  SQL_ADMIN_PASSWORD   - SQL Server administrator password
  WEB_ADMIN_USERNAME   - Web VM administrator username
  WEB_ADMIN_PASSWORD   - Web VM administrator password

Optional environment variables:
  AZURE_LOCATION         - Azure region for the deployment (default: westeurope)
  AZURE_SUBSCRIPTION_ID  - Azure subscription ID to target
  AZURE_ENV_NAME         - Default environment name when argument is omitted
  AZURE_LOG_LEVEL        - Overrides azd log level (e.g., debug)

Examples:
  AZURE_LOCATION=westeurope ./deploy.sh dev
  SQL_ADMIN_USERNAME=sqladmin SQL_ADMIN_PASSWORD=Pass1234 \
  WEB_ADMIN_USERNAME=webadmin WEB_ADMIN_PASSWORD=Pass5678 ./deploy.sh test

Prerequisites:
  - Azure CLI (az) logged in or service principal environment variables configured
  - Azure Developer CLI (azd) installed and authenticated (service principal or az login)
  - Bash shell (Linux/macOS/WSL)
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

require_command az
require_command azd

if [[ -n "${AZURE_LOG_LEVEL:-}" ]]; then
  export AZD_LOG_LEVEL="$AZURE_LOG_LEVEL"
fi

ENVIRONMENT="${1:-${AZURE_ENV_NAME:-dev}}"
LOCATION="${AZURE_LOCATION:-westeurope}"
SUBSCRIPTION="${AZURE_SUBSCRIPTION_ID:-}"

: "${SQL_ADMIN_USERNAME:?Environment variable SQL_ADMIN_USERNAME must be set}"
: "${SQL_ADMIN_PASSWORD:?Environment variable SQL_ADMIN_PASSWORD must be set}"
: "${WEB_ADMIN_USERNAME:?Environment variable WEB_ADMIN_USERNAME must be set}"
: "${WEB_ADMIN_PASSWORD:?Environment variable WEB_ADMIN_PASSWORD must be set}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
cd "$PROJECT_ROOT"

log_info "Checking Azure CLI authentication..."
if ! az account show >/dev/null 2>&1; then
  log_error "Azure CLI is not authenticated. Run 'az login' or configure service principal credentials."
  exit 1
fi

log_info "Ensuring azd authentication context is available..."
if ! azd auth list >/dev/null 2>&1; then
  log_error "Azure Developer CLI is not authenticated. Run 'azd auth login' or configure service principal credentials."
  exit 1
fi

ENVIRONMENT_PATH="${PROJECT_ROOT}/.azure/${ENVIRONMENT}/.env"
if [[ ! -f "$ENVIRONMENT_PATH" ]]; then
  log_info "Creating azd environment '${ENVIRONMENT}'..."
  if [[ -n "$SUBSCRIPTION" ]]; then
    azd env new "$ENVIRONMENT" -l "$LOCATION" --subscription "$SUBSCRIPTION" || {
      log_error "Failed to create azd environment '${ENVIRONMENT}'."
      exit 1
    }
  else
    azd env new "$ENVIRONMENT" -l "$LOCATION" || {
      log_error "Failed to create azd environment '${ENVIRONMENT}'."
      exit 1
    }
  fi
else
  log_info "Reusing existing azd environment '${ENVIRONMENT}'."
fi

log_info "Setting environment configuration values..."
azd env set -e "$ENVIRONMENT" AZURE_LOCATION "$LOCATION"
azd env set -e "$ENVIRONMENT" SQL_ADMIN_USERNAME "$SQL_ADMIN_USERNAME"
azd env set -e "$ENVIRONMENT" SQL_ADMIN_PASSWORD "$SQL_ADMIN_PASSWORD"
azd env set -e "$ENVIRONMENT" WEB_ADMIN_USERNAME "$WEB_ADMIN_USERNAME"
azd env set -e "$ENVIRONMENT" WEB_ADMIN_PASSWORD "$WEB_ADMIN_PASSWORD"

# Set MY_IP if provided
if [[ -n "${MY_IP:-}" ]]; then
  log_info "Restricting RDP access to IP: $MY_IP"
  azd env set -e "$ENVIRONMENT" MY_IP "$MY_IP"
fi

log_info "Starting deployment (azd up)..."
azd up -e "$ENVIRONMENT"

log_success "Deployment completed. Environment '${ENVIRONMENT}' is ready."
log_info "Environment outputs:"
azd env get-values -e "$ENVIRONMENT"

log_info "Primary web endpoint:"
azd env get-values -e "$ENVIRONMENT" | grep '^WEB_URL='
