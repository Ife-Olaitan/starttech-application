#!/bin/bash
set -e

# Backend deployment script
# Usage: ./deploy-backend.sh

AWS_REGION=${AWS_REGION:-eu-west-2}
ASG_NAME=${ASG_NAME:-starttech-asg}
DOCKERHUB_REPO=${DOCKERHUB_REPO:-ifeolaitan/starttech-backend}
IMAGE_TAG=${IMAGE_TAG:-latest}

echo "Deploying Backend..."

# Build and push Docker image
echo "Building Docker image..."
cd backend
docker build -t $DOCKERHUB_REPO:$IMAGE_TAG .

echo "Pushing to Docker Hub..."
docker push $DOCKERHUB_REPO:$IMAGE_TAG

# Trigger ASG instance refresh (rolling update)
echo "Triggering rolling update..."
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name $ASG_NAME \
  --preferences '{"MinHealthyPercentage": 50, "InstanceWarmup": 120}' \
  --region $AWS_REGION

# Wait for deployment
echo "Waiting for deployment to complete..."
while true; do
  STATUS=$(aws autoscaling describe-instance-refreshes \
    --auto-scaling-group-name $ASG_NAME \
    --query 'InstanceRefreshes[0].Status' \
    --output text \
    --region $AWS_REGION)

  echo "Status: $STATUS"

  if [ "$STATUS" = "Successful" ]; then
    echo "Deployment completed successfully!"
    break
  elif [ "$STATUS" = "Failed" ] || [ "$STATUS" = "Cancelled" ]; then
    echo "Deployment failed!"
    exit 1
  fi

  sleep 30
done

echo "Backend deployment complete!"