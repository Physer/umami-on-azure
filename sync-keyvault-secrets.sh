#!/bin/bash
# Sync secrets from .env.keyvault file to Azure Key Vault

set -euo pipefail

# Configuration
VAULT_NAME="${1:-}"
ENV_FILE="${2:-.env.keyvault}"

# Validate inputs
if [ -z "$VAULT_NAME" ]; then
  echo "Usage: $0 <vault-name> [env-file]"
  echo "Example: $0 my-keyvault-dev .env.keyvault"
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  echo "❌ File not found: $ENV_FILE"
  exit 1
fi

# Check Azure CLI authentication
if ! az account show &>/dev/null; then
  echo "❌ Not logged in to Azure. Run: az login"
  exit 1
fi

echo "🔐 Syncing $ENV_FILE → $VAULT_NAME"

# Process .env file and set secrets
count=0
while IFS='=' read -r key value || [ -n "$key" ]; do
  # Skip comments, empty lines, and lines without '='
  [[ "$key" =~ ^[[:space:]]*# ]] && continue
  [[ -z "$key" ]] && continue
  [[ ! "$key" =~ = ]] && [[ -z "$value" ]] && continue
  
  # Trim whitespace and remove quotes
  key=$(echo "$key" | xargs)
  value=$(echo "$value" | xargs | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
  
  # Skip if key or value is empty
  [[ -z "$key" ]] || [[ -z "$value" ]] && continue
  
  # Convert KEY_NAME to key-name (Key Vault naming convention)
  kv_key=$(echo "$key" | tr '[:upper:]' '[:lower:]' | tr '_' '-')
  
  echo "  📤 $kv_key"
  az keyvault secret set --vault-name "$VAULT_NAME" --name "$kv_key" --value "$value" -o none
  
  ((count++))
done < "$ENV_FILE"

echo "✅ Set $count secret(s) in $VAULT_NAME"