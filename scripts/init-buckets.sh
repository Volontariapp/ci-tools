#!/bin/sh
set -e

echo "Initializing MinIO buckets..."

# Wait for MinIO server to be reachable
until /usr/bin/mc alias set myminio http://minio:9000 "${MINIO_ROOT_USER:-minioadmin}" "${MINIO_ROOT_PASSWORD:-minioadminpassword}"; do
  echo "Waiting for MinIO server..."
  sleep 1
done

# Create public bucket if it doesn't exist
/usr/bin/mc mb --ignore-existing myminio/volontariapp-public

# Create private bucket if it doesn't exist
/usr/bin/mc mb --ignore-existing myminio/volontariapp-private

# Configure public download policy for volontariapp-public
/usr/bin/mc anonymous set download myminio/volontariapp-public

echo "MinIO buckets 'volontariapp-public' and 'volontariapp-private' initialized successfully!"
