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

# Configure public download policy for volontariapp-public (GetObject only, no ListBucket)
cat << 'EOF' > /tmp/public-bucket-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::volontariapp-public/*"]
    }
  ]
}
EOF
/usr/bin/mc anonymous set-json /tmp/public-bucket-policy.json myminio/volontariapp-public
rm -f /tmp/public-bucket-policy.json

# Configure 1-day expiration lifecycle rule for quarantine in private bucket
/usr/bin/mc ilm rule add --expire-days 1 --prefix "quarantine/" myminio/volontariapp-private 2>/dev/null || true

echo "MinIO buckets 'volontariapp-public' and 'volontariapp-private' initialized successfully!"
