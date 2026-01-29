#!/bin/bash
set -e

# Frontend deployment script
# Usage: ./deploy-frontend.sh

AWS_REGION=${AWS_REGION:-eu-west-2}
S3_BUCKET=${S3_BUCKET:-starttech-frontend-buc}
CLOUDFRONT_DISTRIBUTION_ID=${CLOUDFRONT_DISTRIBUTION_ID}

echo "Deploying Frontend..."

# Check required variables
if [ -z "$CLOUDFRONT_DISTRIBUTION_ID" ]; then
  echo "Error: CLOUDFRONT_DISTRIBUTION_ID is not set"
  exit 1
fi

# Build frontend
echo "Building frontend..."
cd frontend
npm ci
npm run build

# Sync to S3
echo "Syncing to S3 bucket: $S3_BUCKET"
aws s3 sync dist/ s3://$S3_BUCKET --delete --region $AWS_REGION

# Invalidate CloudFront cache
echo "Invalidating CloudFront cache..."
aws cloudfront create-invalidation \
  --distribution-id $CLOUDFRONT_DISTRIBUTION_ID \
  --paths "/*" \
  --region $AWS_REGION

echo "Frontend deployment complete!"