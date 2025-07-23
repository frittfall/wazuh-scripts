#!/bin/sh

# Ensure a .env file exists in the current directory
if [ ! -f ./.env ]; then
    echo "❌ Error: .env file not found. Please create one with your credentials."
    exit 1
fi

# Load environment variables using the POSIX-compliant '.' command
. ./.env
TENANT_ID=$(echo "$TENANT_ID" | tr -d '[:space:]')
# Set the resource URL
resource="https://manage.office.com"

# Check if variables are loaded
if [ -z "$CLIENT_ID" ] || [ -z "$CLIENT_SECRET" ] || [ -z "$TENANT_ID" ]; then
    echo "❌ Error: Make sure CLIENT_ID, CLIENT_SECRET, and TENANT_ID are set in the .env file."
    exit 1
fi

# 1. Get Access Token
tokenResponseJson=$(curl -s -X POST "https://login.microsoftonline.com/$TENANT_ID/oauth2/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET" \
  -d "resource=$resource")

access_token=$(echo "$tokenResponseJson" | jq -r '.access_token')

if [ -n "$access_token" ] && [ "$access_token" != "null" ]; then
    echo "✅ Access Token acquired successfully."
else
    echo "❌ Failed to acquire access token. Exiting."
    echo "Raw response: $tokenResponseJson"
    exit
fi

# 2. Start Subscriptions
contentTypes="DLP.All Audit.AzureActiveDirectory Audit.SharePoint Audit.Exchange Audit.General"

for contentType in $contentTypes; do
    echo "Attempting to start subscription for: $contentType"

    # Changed to --fail-with-body to output response body on HTTP errors (like 400)
    response=$(curl -s -X POST "https://manage.office.com/api/v1.0/${TENANT_ID}/activity/feed/subscriptions/start?contentType=${contentType}" \
      -H "Authorization: Bearer ${access_token}" \
      -H "Content-Type: application/json" \
      -H "Content-Length: 0" 2>&1) # 2>&1 captures stderr, including curl error messages



    # Optional: Add parsing for specific error messages here based on the full response
    if echo "$response" | grep -q "does not exist"; then
        echo "❌ Monitoring is not enabled in Purview. Error: #0001"
        break
    fi
    echo "" # Newline for separation
done