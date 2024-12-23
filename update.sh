#!/bin/bash
# Script Name: coupa-api/update.sh
# Description: Process Coupa API bulk updates. Auth with OIDC.

base_url="https://company.coupahost.com"
api_url="$base_url/api/suppliers"
token_url="$base_url/oauth2/token"
client_id=""
client_secret=""
scope="core.supplier.read core.supplier.write" # Scopes are space delimited
id_file="ids.txt"
body_file="body.json"

# Ensure token variables exist
if [[ -z "$client_id" ]]; then
    echo "Error: client_id not found" >&2
    exit 1
fi

if [[ -z "$client_secret" ]]; then
    echo "Error: client_secret not found" >&2
    exit 1
fi

if [[ -z "$scope" ]]; then
    echo "Error: scope not found" >&2
    exit 1
fi

# Get the OAuth2 token
token=$(curl -s -X POST "$token_url" \
-H "Content-Type: application/x-www-form-urlencoded" \
-d "grant_type=client_credentials" \
-d "client_id=$client_id" \
-d "client_secret=$client_secret" \
-d "scope=$scope" | jq -r '.access_token')

# Ensure curl is installed
if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is not installed" >&2
    exit 1
fi

# Ensure the JSON file exists
if [[ ! -f "$body_file" ]]; then
    echo "Error: JSON body file '$body_file' not found" >&2
    exit 1
fi

# Ensure the ID_FILE exists
if [[ ! -f "$id_file" ]]; then
    echo "Error: ID file '$id_file' not found" >&2
    exit 1
fi

for id in $(cat "$id_file"); do
    
    # Remove any leading/trailing whitespace or newline characters
    id=$(echo "$id" | tr -d '\n' | tr -d '[:space:]')

    # Skip empty lines
    if [[ -z "$id" ]]; then
        continue
    fi

    echo "Processing URL: $api_url/$id"

    # Send request and capture response
    response=$(curl -s -w "\n%{http_code}" -X PUT "$api_url/$id" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    --data-binary "@$body_file") 

    # Extract the response_body and response_code
    response_code=$(echo "$response" | tail -n 1)
    response_body=$(echo "$response" | sed '$d')

    # Output the response_code and response_body
    echo "Response Code: $response_code"
    echo $response_body | jq -r '.errors // "No errors"'
done
