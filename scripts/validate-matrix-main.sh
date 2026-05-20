#!/bin/bash

# Exit on error
set -e

JSON_FILE="e2e-matrix.json"

if [ ! -f "$JSON_FILE" ]; then
    echo "Error: $JSON_FILE not found."
    exit 1
fi

echo "Checking $JSON_FILE for non-main branches..."

# Get all values from the JSON
NON_MAIN_BRANCHES=$(jq -r 'to_entries[] | select(.value != "main") | "\(.key): \(.value)"' "$JSON_FILE")

if [ -n "$NON_MAIN_BRANCHES" ]; then
    echo "❌ Validation failed: The following services are not pointing to 'main':"
    echo "$NON_MAIN_BRANCHES"
    echo "All services in $JSON_FILE must point to 'main' before merging."
    exit 1
fi

echo "✅ All services are pointing to 'main' (or the file is empty)."
exit 0
