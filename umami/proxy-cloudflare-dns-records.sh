#!/bin/bash

# Script to toggle the proxy status of a DNS record using Cloudflare API
# Uses environment variables from .env.cloudflare file

# Enable error handling but allow us to catch and handle errors gracefully
set -e
set -o pipefail

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed or not in PATH"
    echo ""
    echo "jq is required for parsing JSON responses from the Cloudflare API."
    echo ""
    echo "Please install jq using one of the following methods:"
    echo ""
    echo "Ubuntu/Debian:"
    echo "  sudo apt-get update && sudo apt-get install jq"
    echo ""
    echo "CentOS/RHEL/Fedora:"
    echo "  sudo yum install jq    # or: sudo dnf install jq"
    echo ""
    echo "macOS (with Homebrew):"
    echo "  brew install jq"
    echo ""
    echo "Windows (with Chocolatey):"
    echo "  choco install jq"
    echo ""
    echo "Windows (with Scoop):"
    echo "  scoop install jq"
    echo ""
    echo "Or download from: https://stedolan.github.io/jq/download/"
    echo ""
    exit 1
fi

# Load environment variables from .env.cloudflare file
if [ ! -f ".env.cloudflare" ]; then
    echo "Error: .env.cloudflare file not found!"
    echo "Please create .env.cloudflare with the following variables:"
    echo "  CLOUDFLARE_API_TOKEN=your_api_token_here"
    echo "  ZONE_ID=your_zone_id_here"
    exit 1
fi

# Source the environment file
source .env.cloudflare

# Check required environment variables
if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
    echo "Error: CLOUDFLARE_API_TOKEN is not set in .env.cloudflare"
    exit 1
fi

if [ -z "$ZONE_ID" ]; then
    echo "Error: ZONE_ID is not set in .env.cloudflare"
    exit 1
fi

# Function to display usage
usage() {
    echo "Usage: $0 <RECORD_NAME> <RECORD_TYPE> [PROXY_STATUS]"
    echo ""
    echo "Parameters:"
    echo "  RECORD_NAME    - The name of the DNS record (e.g., 'example.com' or 'www.example.com')"
    echo "  RECORD_TYPE    - The type of DNS record (A, AAAA, CNAME)"
    echo "  PROXY_STATUS   - Set specific proxy status (optional: 'true', 'false', or 'toggle')"
    echo "                   If not specified, the current status will be toggled"
    echo ""
    echo "The script will:"
    echo "  - Search for an existing record with the specified name and type"
    echo "  - Toggle the proxy status (true ↔ false) or set it to a specific value"
    echo "  - Update the record with the new proxy status"
    echo ""
    echo "Note: Only A, AAAA, and CNAME records can be proxied through Cloudflare"
    echo ""
    echo "Examples:"
    echo "  $0 www.example.com A                    # Toggle current proxy status"
    echo "  $0 www.example.com A true               # Enable proxy"
    echo "  $0 www.example.com A false              # Disable proxy"
    echo "  $0 api.example.com CNAME toggle         # Toggle current proxy status"
}

# Check if minimum required parameters are provided
if [ $# -lt 2 ]; then
    echo "Error: Missing required parameters"
    usage
    exit 1
fi

# Parse command line arguments
RECORD_NAME="$1"
RECORD_TYPE="$2"
PROXY_ACTION="${3:-toggle}"  # Default is to toggle

# Validate record type for proxy support
case "$RECORD_TYPE" in
    "A"|"AAAA"|"CNAME")
        # These record types support proxying
        ;;
    *)
        echo "Error: Record type '$RECORD_TYPE' cannot be proxied through Cloudflare"
        echo "Only A, AAAA, and CNAME records support proxy functionality"
        exit 1
        ;;
esac

# Function to search for existing DNS record
find_existing_record() {
    local search_name="$1"
    local search_type="$2"
    
    echo "Searching for DNS record: $search_name ($search_type)" >&2
    
    # Search for existing record by name and type
    local search_response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$search_name&type=$search_type" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        -H "Content-Type: application/json")
    
    # Check if search was successful
    local search_success=$(echo "$search_response" | jq -r '.success')
    if [ "$search_success" != "true" ]; then
        echo "Error: Failed to search for existing records" >&2
        echo "$search_response" | jq -r '.errors[]?.message // "Unknown error"' >&2
        exit 1
    fi
    
    # Check if we found exactly one record
    local record_count=$(echo "$search_response" | jq -r '.result | length')
    if [ "$record_count" -eq 0 ]; then
        echo "Error: No DNS record found with name '$search_name' and type '$search_type'" >&2
        exit 1
    elif [ "$record_count" -gt 1 ]; then
        echo "Warning: Multiple records found with name '$search_name' and type '$search_type'" >&2
        echo "Using the first record found" >&2
    fi
    
    # Return the complete record data as JSON
    echo "$search_response" | jq -r '.result[0]'
}

# Function to update DNS record proxy status
update_record_proxy() {
    local record_id="$1"
    local current_record="$2"
    local new_proxied="$3"
    
    # Extract current record details
    local record_name=$(echo "$current_record" | jq -r '.name')
    local record_type=$(echo "$current_record" | jq -r '.type')
    local record_content=$(echo "$current_record" | jq -r '.content')
    local record_ttl=$(echo "$current_record" | jq -r '.ttl')
    
    # Create JSON payload with all required fields
    local json_payload=$(cat <<EOF
{
    "type": "$record_type",
    "name": "$record_name",
    "content": "$record_content",
    "ttl": $record_ttl,
    "proxied": $new_proxied
}
EOF
)
    
    echo "Updating DNS record proxy status..."
    
    # Make the API call to update the record
    local update_response=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$record_id" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        -H "Content-Type: application/json" \
        --data "$json_payload")
    
    # Check if we got a response
    if [ -z "$update_response" ]; then
        echo "❌ Error: No response received from Cloudflare API"
        echo "This could indicate:"
        echo "  - Network connectivity issues"
        echo "  - Invalid API token"
        echo "  - Incorrect Zone ID"
        echo "  - API endpoint unavailable"
        exit 1
    fi
    
    # Check if the API call was successful
    local update_success=$(echo "$update_response" | jq -r '.success' 2>/dev/null || echo "false")
    
    if [ "$update_success" = "true" ]; then
        echo "✅ DNS record proxy status updated successfully!"
        
        # Extract and display the updated record details
        local updated_name=$(echo "$update_response" | jq -r '.result.name')
        local updated_type=$(echo "$update_response" | jq -r '.result.type')
        local updated_content=$(echo "$update_response" | jq -r '.result.content')
        local updated_proxied=$(echo "$update_response" | jq -r '.result.proxied')
        
        echo ""
        echo "Updated record details:"
        echo "  Name: $updated_name"
        echo "  Type: $updated_type"
        echo "  Content: $updated_content"
        echo "  Proxied: $updated_proxied"
        
        return 0
    else
        echo "❌ Failed to update DNS record proxy status!"
        echo ""
        echo "Error response:"
        echo "$update_response" | jq -r '.errors[]?.message // "Unknown error"'
        
        # Display additional error details if available
        if echo "$update_response" | jq -e '.messages[]?' > /dev/null 2>&1; then
            echo ""
            echo "Additional messages:"
            echo "$update_response" | jq -r '.messages[]?.message // empty'
        fi
        
        exit 1
    fi
}

echo "Processing DNS record proxy toggle..."
echo "Name: $RECORD_NAME"
echo "Type: $RECORD_TYPE"
echo "Action: $PROXY_ACTION"
echo ""

# Search for the existing record
EXISTING_RECORD=$(find_existing_record "$RECORD_NAME" "$RECORD_TYPE")

# Extract current record details
RECORD_ID=$(echo "$EXISTING_RECORD" | jq -r '.id')
CURRENT_PROXIED=$(echo "$EXISTING_RECORD" | jq -r '.proxied')
RECORD_CONTENT=$(echo "$EXISTING_RECORD" | jq -r '.content')

echo "✓ Found DNS record with ID: $RECORD_ID"
echo "  Current content: $RECORD_CONTENT"
echo "  Current proxy status: $CURRENT_PROXIED"
echo ""

# Determine new proxy status based on action
case "$PROXY_ACTION" in
    "true"|"1"|"enable"|"on")
        NEW_PROXIED=true
        ;;
    "false"|"0"|"disable"|"off")
        NEW_PROXIED=false
        ;;
    "toggle")
        if [ "$CURRENT_PROXIED" = "true" ]; then
            NEW_PROXIED=false
        else
            NEW_PROXIED=true
        fi
        ;;
    *)
        echo "Error: Invalid proxy action '$PROXY_ACTION'"
        echo "Valid actions: true, false, toggle"
        exit 1
        ;;
esac

# Check if change is needed
if [ "$CURRENT_PROXIED" = "$NEW_PROXIED" ]; then
    echo "ℹ️  Proxy status is already set to: $NEW_PROXIED"
    echo "No changes needed."
    exit 0
fi

echo "Changing proxy status from $CURRENT_PROXIED to $NEW_PROXIED..."
echo ""

# Update the record with new proxy status
update_record_proxy "$RECORD_ID" "$EXISTING_RECORD" "$NEW_PROXIED"