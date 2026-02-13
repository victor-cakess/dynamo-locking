#!/usr/bin/env bash
set -euo pipefail

BUCKET_NAME="dynamo-locking-terraform-state"
REGION="sa-east-1"

echo "==> Bootstrapping Terraform backend infrastructure"
echo "    Bucket: ${BUCKET_NAME}"
echo "    Region: ${REGION}"
echo ""

# --- S3 State Bucket ---
if aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
  echo "[OK] S3 bucket '${BUCKET_NAME}' already exists. Skipping creation."
else
  echo "[..] Creating S3 bucket '${BUCKET_NAME}'..."
  aws s3api create-bucket \
    --bucket "${BUCKET_NAME}" \
    --region "${REGION}" \
    --create-bucket-configuration LocationConstraint="${REGION}"
  echo "[OK] S3 bucket created."
fi

echo "[..] Enabling versioning on '${BUCKET_NAME}'..."
aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled
echo "[OK] Versioning enabled."

echo "[..] Blocking all public access on '${BUCKET_NAME}'..."
aws s3api put-public-access-block \
  --bucket "${BUCKET_NAME}" \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
echo "[OK] Public access blocked."

echo "[..] Enabling default encryption (AES256) on '${BUCKET_NAME}'..."
aws s3api put-bucket-encryption \
  --bucket "${BUCKET_NAME}" \
  --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"},"BucketKeyEnabled":true}]}'
echo "[OK] Encryption enabled."

echo ""
echo "==> Backend infrastructure is ready."
echo "    You can now run: cd terraform && terraform init"
