# Build Stage - Compile the Go application
FROM golang:1.25.5-alpine AS builder

WORKDIR /build

# Copy and download dependencies first (for Docker caching)
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the binary
RUN CGO_ENABLED=0 GOOS=linux go build -o main ./cmd/api/main.go

# Runtime Stage - Run the application
FROM alpine:latest AS runtime

# Install curl for health checks
RUN apk --no-cache add ca-certificates curl

# Create non-root user
RUN adduser -D -u 1000 appuser

WORKDIR /app

# Create log directory
RUN mkdir -p /var/log/backend && chown appuser:appuser /var/log/backend

# Copy binary from build stage
COPY --from=builder /build/main .
COPY --from=builder /build/docs ./docs

# Use non-root user
USER appuser

# Expose port
EXPOSE 8080

# Health check with curl
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8080/health || exit 1

# Run the app
CMD ["./main"]