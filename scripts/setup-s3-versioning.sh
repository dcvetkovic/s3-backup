#!/bin/bash
# Enable S3 bucket versioning to keep multiple revisions of backups
# Run this once when setting up your S3 bucket

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load environment variables
ENV_FILE="${PROJECT_DIR}/config/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Environment file not found at $ENV_FILE"
    echo "Please copy config/.env.example to config/.env and fill in your credentials"
    exit 1
fi
source "$ENV_FILE"

# Configure AWS CLI
export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
export AWS_DEFAULT_REGION="$AWS_REGION"

echo "Enabling versioning on bucket: $S3_BUCKET"

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket "$S3_BUCKET" \
    --versioning-configuration Status=Enabled

echo "Versioning enabled successfully!"
echo ""
echo "Now each upload to s3://${S3_BUCKET}/${S3_PATH} will create a new version."
echo "Previous versions are retained automatically."
echo ""
echo "To list all versions of your backup file, run:"
echo "  aws s3api list-object-versions --bucket $S3_BUCKET --prefix ${S3_PATH}"
