#!/bin/bash
# Sync secrets from .env.keyvault file to Azure Key Vault

VAULT_NAME="${1:-}"
ENV_FILE="${2:-.env.keyvault}"

if [ -z "$VAULT_NAME" ]; then
  echo "Usage: $0 <vault-name> [env-file]"
  echo "Example: $0 my-keyvault-dev .env.keyvault"
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  echo "❌ File not found: $ENV_FILE"
  exit 1
fi

if ! az account show &>/dev/null; then
  echo "❌ Not logged in to Azure. Run: az login"
  exit 1
fi

echo "🔐 Syncing $ENV_FILE → $VAULT_NAME"

success=0
fail=0
exec 3<"$ENV_FILE"
while IFS= read -r line <&3 || [ -n "$line" ]; do
  # Remove trailing CR for compatibility with CRLF and LF files
  line="${line%$'\r'}"

  # Skip empty lines
  [ -z "$line" ] && continue

  # Split key and value
  key="${line%%=*}"
  value="${line#*=}"

  # Skip if key or value is empty
  [ -z "$key" ] && continue
  [ -z "$value" ] && continue

  echo "  📤 $key"
  if az keyvault secret set --vault-name "$VAULT_NAME" --name "$key" --value "$value" -o none; then
    ((success++))
  else
    echo "    ⚠️ Failed to set secret: $key"
    ((fail++))
  fi
done
exec 3<&-

echo "✅ Set $success secret(s) in $VAULT_NAME"
if [ "$fail" -gt 0 ]; then
  echo "⚠️ $fail secret(s) failed to set."
fi