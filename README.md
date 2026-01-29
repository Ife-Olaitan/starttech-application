# StartTech Application

Full-stack application with React frontend and Golang backend API.

## Architecture

- **Frontend**: React + Vite
- **Backend**: Golang REST API
- **Cache**: Redis (ElastiCache)
- **Database**: MongoDB Atlas

## Repository Structure

```
starttech-application/
├── .github/workflows/
│   ├── frontend-ci-cd.yml
│   └── backend-ci-cd.yml
├── frontend/
├── backend/
└── scripts/
    ├── deploy-frontend.sh
    ├── deploy-backend.sh
    ├── health-check.sh
    └── rollback.sh
```

## Prerequisites

- Node.js >= 22.x (frontend)
- Go >= 1.22 (backend)
- Docker (backend deployment)
- AWS CLI configured

## Local Development

### Frontend

```bash
cd frontend
npm install
npm run dev
```

### Backend

```bash
cd backend
go mod download
go run main.go
```

## CI/CD Pipelines

### Frontend Pipeline

Triggers on push to `full-stack` branch:

1. **Build**: Install deps, run tests, build production bundle
2. **Security**: npm audit scan
3. **Deploy**: Sync to S3, invalidate CloudFront cache

### Backend Pipeline

Triggers on push to `full-stack` branch:

1. **Test**: Unit tests, integration tests, go vet
2. **Security**: Vulnerability scan (Nancy), Docker image scan (Trivy)
3. **Build**: Docker build and push to Docker Hub
4. **Deploy**: ASG instance refresh (rolling update)

## Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS access key |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key |
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token |
| `CLOUDFRONT_DISTRIBUTION_ID` | Set by infra pipeline |
| `ASG_NAME` | Set by infra pipeline |

## Manual Deployment

### Frontend

```bash
export CLOUDFRONT_DISTRIBUTION_ID=<your-id>
./scripts/deploy-frontend.sh
```

### Backend

```bash
./scripts/deploy-backend.sh
```

### Health Check

```bash
export FRONTEND_URL=https://<cloudfront-domain>
export BACKEND_URL=http://<alb-dns>
./scripts/health-check.sh
```

### Rollback

```bash
# Frontend (requires S3 versioning)
./scripts/rollback.sh frontend <version-id>

# Backend
./scripts/rollback.sh backend <image-tag>
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| POST | `/api/auth/register` | User registration |
| POST | `/api/auth/login` | User login |
| GET | `/api/todos` | List todos |
| POST | `/api/todos` | Create todo |

## Environment Variables (Backend)

| Variable | Description |
|----------|-------------|
| `PORT` | Server port (8080) |
| `MONGO_URI` | MongoDB connection string |
| `JWT_SECRET_KEY` | JWT signing key |
| `REDIS_ADDR` | Redis endpoint |
| `ENABLE_CACHE` | Enable Redis caching |

## Related Repository

- [starttech-infra](https://github.com/Ife-Olaitan/starttech-infra) - Infrastructure code (Terraform)