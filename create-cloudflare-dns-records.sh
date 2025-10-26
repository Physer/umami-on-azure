#!/bin/bash

# Script to create or update a DNS record using Cloudflare API
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
    echo "Usage: $0 <RECORD_NAME> <RECORD_TYPE> <RECORD_VALUE> [TTL] [PROXIED]"
    echo ""
    echo "Parameters:"
    echo "  RECORD_NAME    - The name of the DNS record (e.g., 'example.com' or 'www.example.com')"
    echo "  RECORD_TYPE    - The type of DNS record (A, AAAA, CNAME, MX, TXT, etc.)"
    echo "  RECORD_VALUE   - The value for the DNS record (IP address, domain, etc.)"
    echo "  TTL            - Time to live in seconds (optional, default: 1 = auto)"
    echo "  PROXIED        - Whether the record is proxied through Cloudflare (optional, default: false)"
    echo ""
    echo "The script will automatically:"
    echo "  - Search for an existing record with the same name and type"
    echo "  - Update the record if it exists"
    echo "  - Create a new record if it doesn't exist"
    echo ""
    echo "Examples:"
    echo "  $0 www.example.com A 192.168.1.1"
    echo "  $0 www.example.com A 192.168.1.1 300 true"
    echo "  $0 mail.example.com CNAME example.com 1 false"
}

# Check if minimum required parameters are provided
if [ $# -lt 3 ]; then
    echo "Error: Missing required parameters"
    usage
    exit 1
fi

# Parse command line arguments
RECORD_NAME="$1"
RECORD_TYPE="$2"
RECORD_VALUE="$3"
TTL="${4:-1}"          # Default TTL is 1 (auto)
PROXIED="${5:-false}"  # Default is not proxied

# Convert PROXIED to boolean
if [ "$PROXIED" = "true" ] || [ "$PROXIED" = "1" ]; then
    PROXIED_BOOL=true
else
    PROXIED_BOOL=false
fi

# Function to search for existing DNS record
find_existing_record() {
    local search_name="$1"
    local search_type="$2"
    
    echo "Searching for existing DNS record: $search_name ($search_type)" >&2
    
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
    
    # Get the record ID if it exists
    local record_id=$(echo "$search_response" | jq -r '.result[0]?.id // empty')
    echo "$record_id"
}

# Create JSON payload
JSON_PAYLOAD=$(cat <<EOF
{
    "type": "$RECORD_TYPE",
    "name": "$RECORD_NAME",
    "content": "$RECORD_VALUE",
    "ttl": $TTL,
    "proxied": $PROXIED_BOOL
}
EOF
)

echo "Processing DNS record..."
echo "Name: $RECORD_NAME"
echo "Type: $RECORD_TYPE"
echo "Value: $RECORD_VALUE"
echo "TTL: $TTL"
echo "Proxied: $PROXIED_BOOL"
echo ""

# Search for existing record
EXISTING_RECORD_ID=$(find_existing_record "$RECORD_NAME" "$RECORD_TYPE")

if [ -n "$EXISTING_RECORD_ID" ]; then
    # Record exists, update it
    echo "✓ Found existing record with ID: $EXISTING_RECORD_ID"
    echo "Updating existing DNS record..."
    
    API_URL="https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$EXISTING_RECORD_ID"
    HTTP_METHOD="PUT"
    ACTION="updated"
else
    # Record doesn't exist, create it
    echo "✓ No existing record found"
    echo "Creating new DNS record..."
    
    API_URL="https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records"
    HTTP_METHOD="POST"
    ACTION="created"
fi

# Make the API call
RESPONSE=$(curl -s -X "$HTTP_METHOD" "$API_URL" \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    -H "Content-Type: application/json" \
    --data "$JSON_PAYLOAD")

# Check if we got a response
if [ -z "$RESPONSE" ]; then
    echo "❌ Error: No response received from Cloudflare API"
    echo "This could indicate:"
    echo "  - Network connectivity issues"
    echo "  - Invalid API token"
    echo "  - Incorrect Zone ID"
    echo "  - API endpoint unavailable"
    exit 1
fi

# Check if the API call was successful
SUCCESS=$(echo "$RESPONSE" | jq -r '.success' 2>/dev/null || echo "false")

if [ "$SUCCESS" = "true" ]; then
    echo "✅ DNS record $ACTION successfully!"
    
    # Extract and display the record details
    RECORD_ID=$(echo "$RESPONSE" | jq -r '.result.id')
    RECORD_NAME_RESULT=$(echo "$RESPONSE" | jq -r '.result.name')
    RECORD_TYPE_RESULT=$(echo "$RESPONSE" | jq -r '.result.type')
    RECORD_CONTENT=$(echo "$RESPONSE" | jq -r '.result.content')
    RECORD_TTL=$(echo "$RESPONSE" | jq -r '.result.ttl')
    RECORD_PROXIED=$(echo "$RESPONSE" | jq -r '.result.proxied')
    
    echo ""
    echo "Record details:"
    echo "  ID: $RECORD_ID"
    echo "  Name: $RECORD_NAME_RESULT"
    echo "  Type: $RECORD_TYPE_RESULT"
    echo "  Content: $RECORD_CONTENT"
    echo "  TTL: $RECORD_TTL"
    echo "  Proxied: $RECORD_PROXIED"
else
    echo "❌ Failed to $ACTION DNS record!"
    echo ""
    echo "Error response:"
    echo "$RESPONSE" | jq -r '.errors[]?.message // "Unknown error"'
    
    # Display additional error details if available
    if echo "$RESPONSE" | jq -e '.messages[]?' > /dev/null 2>&1; then
        echo ""
        echo "Additional messages:"
        echo "$RESPONSE" | jq -r '.messages[]?.message // empty'
    fi
    
    exit 1
fi