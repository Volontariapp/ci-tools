#!/bin/bash

# Configuration - Aligned with api-gateway default.config.json
# This script is located in ci-tools/scripts/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERTS_DIR="$SCRIPT_DIR/../certs"

# Create directory if it doesn't exist
mkdir -p "$CERTS_DIR"

echo "Generating RSA keys for access, refresh, and internal tokens in $CERTS_DIR..."

# Generate access key pair
openssl genrsa -out "$CERTS_DIR/access.key" 2048
openssl rsa -in "$CERTS_DIR/access.key" -pubout -out "$CERTS_DIR/access.pub"

# Generate refresh key pair
openssl genrsa -out "$CERTS_DIR/refresh.key" 2048
openssl rsa -in "$CERTS_DIR/refresh.key" -pubout -out "$CERTS_DIR/refresh.pub"

# Generate internal key
openssl genrsa -out "$CERTS_DIR/internal.key" 2048
openssl rsa -in "$CERTS_DIR/internal.key" -pubout -out "$CERTS_DIR/internal.pub"

chmod 600 "$CERTS_DIR"/*.key
chmod 644 "$CERTS_DIR"/*.pub

echo "Keys generated successfully in $CERTS_DIR"
echo ""
echo "⚠️  Remember to NEVER commit these keys!"
