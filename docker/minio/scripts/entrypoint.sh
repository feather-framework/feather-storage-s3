#!/bin/sh
set -e

# Start MinIO server in the background
minio server /data --console-address ":9001" &
MINIO_PID=$!

echo "Waiting for MinIO to be ready..."
until curl -s http://localhost:9000/minio/health/ready > /dev/null; do
    sleep 1
done

# Configure local alias with default root credentials
mc alias set local http://localhost:9000 "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}"

# Create new user (access + secret key)
#mc admin user add local newuser newpassword

# Optionally assign policies
#mc admin policy attach local readwrite --user newuser

mc admin accesskey create local "${MINIO_ROOT_USER}" \
    --access-key "${MINIO_ACCESS_KEY_ID}" \
    --secret-key "${MINIO_SECRET_ACCESS_KEY}" || echo "Access key already exists"

mc mb "local/${MINIO_BUCKET_NAME}" || echo "Bucket already exists"

# Wait for MinIO to terminate if foreground fails (optional)
wait "$MINIO_PID"
