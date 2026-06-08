#!/bin/bash

# Exit on error
set -e

JSON_FILE="e2e-matrix.json"
CURRENT_SERVICE=$1

if [ ! -f "$JSON_FILE" ]; then
    echo "Error: $JSON_FILE not found."
    exit 1
fi

# List of allowed services
ALLOWED_SERVICES=("api-gateway" "ms-user" "ms-event" "ms-social" "ms-post")

if [ -n "$CURRENT_SERVICE" ]; then
    echo "Checking $JSON_FILE for non-main branches (excluding $CURRENT_SERVICE)..."
    
    # Ensure current service is NOT in JSON
    IS_PRESENT=$(jq -r --arg svc "$CURRENT_SERVICE" '.[$svc] // empty' "$JSON_FILE")
    if [ -n "$IS_PRESENT" ]; then
        echo "❌ Validation failed: Current service '$CURRENT_SERVICE' must not be specified in $JSON_FILE."
        exit 1
    fi

    # Check for missing required services
    MISSING_SERVICES=""
    for SERVICE in "${ALLOWED_SERVICES[@]}"; do
        if [ "$SERVICE" != "$CURRENT_SERVICE" ]; then
            EXISTS=$(jq -r --arg svc "$SERVICE" '.[$svc] // empty' "$JSON_FILE")
            if [ -z "$EXISTS" ]; then
                MISSING_SERVICES="$MISSING_SERVICES $SERVICE"
            fi
        fi
    done

    if [ -n "$MISSING_SERVICES" ]; then
        echo "❌ Validation failed: Missing required services in $JSON_FILE:$MISSING_SERVICES"
        exit 1
    fi

    # Check for non-main branches
    NON_MAIN_BRANCHES=$(jq -r --arg EXCLUDE "$CURRENT_SERVICE" 'to_entries[] | select(.key != $EXCLUDE and .value != "main") | "\(.key): \(.value)"' "$JSON_FILE")
    SERVICE_COUNT=$(jq -r --arg EXCLUDE "$CURRENT_SERVICE" '[to_entries[] | select(.key != $EXCLUDE)] | length' "$JSON_FILE")
else
    echo "Checking $JSON_FILE for non-main branches..."
    
    # Check for missing required services
    MISSING_SERVICES=""
    for SERVICE in "${ALLOWED_SERVICES[@]}"; do
        EXISTS=$(jq -r --arg svc "$SERVICE" '.[$svc] // empty' "$JSON_FILE")
        if [ -z "$EXISTS" ]; then
            MISSING_SERVICES="$MISSING_SERVICES $SERVICE"
        fi
    done

    if [ -n "$MISSING_SERVICES" ]; then
        echo "❌ Validation failed: Missing required services in $JSON_FILE:$MISSING_SERVICES"
        exit 1
    fi

    # Check for non-main branches
    NON_MAIN_BRANCHES=$(jq -r 'to_entries[] | select(.value != "main") | "\(.key): \(.value)"' "$JSON_FILE")
    SERVICE_COUNT=$(jq -r 'length' "$JSON_FILE")
fi

if [ "$SERVICE_COUNT" -eq 0 ]; then
    echo "❌ Validation failed: No services found in $JSON_FILE (excluding $CURRENT_SERVICE)."
    exit 1
fi

if [ -n "$NON_MAIN_BRANCHES" ]; then
    echo "❌ Validation failed: The following services are not pointing to 'main':"
    echo "$NON_MAIN_BRANCHES"
    echo "All services (except potentially the current one) in $JSON_FILE must point to 'main' before merging."
    exit 1
fi

echo "✅ Validation passed ($SERVICE_COUNT service(s) checked)."
exit 0
