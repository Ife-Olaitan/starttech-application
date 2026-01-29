#!/bin/bash
set -e

# Rollback script
# Usage: ./rollback.sh [frontend|backend] [version]

TARGET=${1}
VERSION=${2}
AWS_REGION=${AWS_REGION:-eu-west-2}

if [ -z "$TARGET" ]; then
echo "Usage: ./rollback.sh [frontend|backend] [version]"
echo "  frontend: Rollback frontend to previous S3 version"
echo "  backend:  Rollback backend to previous Docker image"
exit 1
fi

echo "Rolling back $TARGET"

case $TARGET in
frontend)
  S3_BUCKET=${S3_BUCKET:-starttech-frontend-buc}
  CLOUDFRONT_DISTRIBUTION_ID=${CLOUDFRONT_DISTRIBUTION_ID}

  if [ -z "$VERSION" ]; then
    echo "Listing available versions..."
    aws s3api list-object-versions \
      --bucket $S3_BUCKET \
      --prefix "index.html" \
      --query 'Versions[0:5].[VersionId,LastModified]' \
      --output table
    echo ""
    echo "Run: ./rollback.sh frontend <version-id>"
    exit 0
  fi

  echo "Restoring version: $VERSION"
  # Restore by copying the version back
  aws s3api get-object \
    --bucket $S3_BUCKET \
    --key "index.html" \
    --version-id $VERSION \
    /tmp/index.html

  aws s3 cp /tmp/index.html s3://$S3_BUCKET/index.html

  # Invalidate cache
  aws cloudfront create-invalidation \
    --distribution-id $CLOUDFRONT_DISTRIBUTION_ID \
    --paths "/*"

  echo "Frontend rolled back to version $VERSION"
  ;;

backend)
  ASG_NAME=${ASG_NAME:-starttech-asg}
  DOCKERHUB_REPO=${DOCKERHUB_REPO:-ifeolaitan/starttech-backend}

  if [ -z "$VERSION" ]; then
    echo "Available tags on Docker Hub:"
    echo "  - latest"
    echo "  - <commit-sha>"
    echo ""
    echo "Run: ./rollback.sh backend <tag>"
    exit 0
  fi

  echo "Rolling back to image: $DOCKERHUB_REPO:$VERSION"

  # Trigger instance refresh with the specific version
  # Note: You'll need to update launch template or use SSM to pull specific version
  aws autoscaling start-instance-refresh \
    --auto-scaling-group-name $ASG_NAME \
    --preferences '{"MinHealthyPercentage": 50, "InstanceWarmup": 120}' \
    --region $AWS_REGION

  echo "Instance refresh triggered. Instances will pull $DOCKERHUB_REPO:$VERSION"
  echo "Note: Ensure launch template or user_data references the correct tag"
  ;;

*)
  echo "Unknown target: $TARGET"
  echo "Use 'frontend' or 'backend'"
  exit 1
  ;;
esac

echo "Rollback initiated for $TARGET"