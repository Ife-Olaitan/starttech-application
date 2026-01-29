#!/bin/bash
set -e

# Health check script
# Usage: ./health-check.sh [frontend|backend|all]

TARGET=${1:-all}
FRONTEND_URL=${FRONTEND_URL:-https://your-cloudfront-domain.cloudfront.net}
BACKEND_URL=${BACKEND_URL:-http://your-alb-dns.eu-west-2.elb.amazonaws.com}
MAX_RETRIES=5
RETRY_INTERVAL=10

check_health() {
  local name=$1
  local url=$2
  local endpoint=$3

  echo "Checking $name health at $url$endpoint..."

  for i in $(seq 1 $MAX_RETRIES); do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$url$endpoint" || echo "000")

    if [ "$HTTP_CODE" = "200" ]; then
      echo "✅ $name is healthy (HTTP $HTTP_CODE)"
      return 0
    else
      echo "Attempt $i/$MAX_RETRIES: $name returned HTTP $HTTP_CODE"
      if [ $i -lt $MAX_RETRIES ]; then
        sleep $RETRY_INTERVAL
      fi
    fi
  done

  echo "$name health check failed"
  return 1
}

echo "Running Health Checks"

EXIT_CODE=0

if [ "$TARGET" = "frontend" ] || [ "$TARGET" = "all" ]; then
  check_health "Frontend" "$FRONTEND_URL" "/" || EXIT_CODE=1
fi

if [ "$TARGET" = "backend" ] || [ "$TARGET" = "all" ]; then
  check_health "Backend" "$BACKEND_URL" "/health" || EXIT_CODE=1
fi

echo "=========================================="
if [ $EXIT_CODE -eq 0 ]; then
  echo "All health checks passed!"
else
  echo "Some health checks failed!"
fi
echo "=========================================="

exit $EXIT_CODE