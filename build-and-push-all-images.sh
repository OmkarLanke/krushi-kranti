#!/bin/bash
# Build and Push All Images to Docker Hub
# Usage: ./build-and-push-all-images.sh yourusername

# Check if Docker Hub username is provided
if [ -z "$1" ]; then
    echo "Error: Docker Hub username required"
    echo "Usage: ./build-and-push-all-images.sh yourusername"
    exit 1
fi

DOCKER_HUB_USERNAME=$1
echo "Using Docker Hub username: $DOCKER_HUB_USERNAME"
echo ""

# Navigate to microservices directory
cd d:/KrushiKranti/microservices

echo "=========================================="
echo "Building and Pushing Microservices"
echo "=========================================="

# 1. API Gateway
echo "Building API Gateway..."
docker build -t $DOCKER_HUB_USERNAME/krushi-api-gateway:latest -f ./java-spring-microservices/api-gateway/Dockerfile ./java-spring-microservices
docker push $DOCKER_HUB_USERNAME/krushi-api-gateway:latest
echo "✓ API Gateway done"
echo ""

# 2. Auth Service
echo "Building Auth Service..."
docker build -t $DOCKER_HUB_USERNAME/krushi-auth-service:latest -f ./java-spring-microservices/auth-service/Dockerfile ./java-spring-microservices
docker push $DOCKER_HUB_USERNAME/krushi-auth-service:latest
echo "✓ Auth Service done"
echo ""

# 3. Farmer Service
echo "Building Farmer Service..."
docker build -t $DOCKER_HUB_USERNAME/krushi-farmer-service:latest -f ./java-spring-microservices/farmer-service/Dockerfile ./java-spring-microservices
docker push $DOCKER_HUB_USERNAME/krushi-farmer-service:latest
echo "✓ Farmer Service done"
echo ""

# 4. Field Officer Service
echo "Building Field Officer Service..."
docker build -t $DOCKER_HUB_USERNAME/krushi-field-officer-service:latest -f ./java-spring-microservices/field-officer-service/Dockerfile ./java-spring-microservices
docker push $DOCKER_HUB_USERNAME/krushi-field-officer-service:latest
echo "✓ Field Officer Service done"
echo ""

# 5. Subscription Service
echo "Building Subscription Service..."
docker build -t $DOCKER_HUB_USERNAME/krushi-subscription-service:latest -f ./java-spring-microservices/subscription-service/Dockerfile ./java-spring-microservices
docker push $DOCKER_HUB_USERNAME/krushi-subscription-service:latest
echo "✓ Subscription Service done"
echo ""

# 6. KYC Service
echo "Building KYC Service..."
docker build -t $DOCKER_HUB_USERNAME/krushi-kyc-service:latest -f ./java-spring-microservices/kyc-service/Dockerfile ./java-spring-microservices
docker push $DOCKER_HUB_USERNAME/krushi-kyc-service:latest
echo "✓ KYC Service done"
echo ""

# 7. Notification Service
echo "Building Notification Service..."
docker build -t $DOCKER_HUB_USERNAME/krushi-notification-service:latest -f ./java-spring-microservices/notification-service/Dockerfile ./java-spring-microservices
docker push $DOCKER_HUB_USERNAME/krushi-notification-service:latest
echo "✓ Notification Service done"
echo ""

# 8. File Service
echo "Building File Service..."
docker build -t $DOCKER_HUB_USERNAME/krushi-file-service:latest -f ./java-spring-microservices/file-service/Dockerfile ./java-spring-microservices
docker push $DOCKER_HUB_USERNAME/krushi-file-service:latest
echo "✓ File Service done"
echo ""

# Navigate to repo root for frontend
cd d:/KrushiKranti

echo "=========================================="
echo "Building and Pushing Frontend"
echo "=========================================="

# 9. Frontend (Production)
echo "Building Frontend (Production)..."
docker build -t $DOCKER_HUB_USERNAME/krushi-frontend:latest --build-arg BASE_URL=https://api.krushikranti.ltd -f ./frontend/Dockerfile .
docker push $DOCKER_HUB_USERNAME/krushi-frontend:latest
echo "✓ Frontend done"
echo ""

echo "=========================================="
echo "Re-tagging and Pushing Official Images"
echo "=========================================="

# 10. PostgreSQL
echo "Re-tagging PostgreSQL..."
docker pull postgres:16-alpine
docker tag postgres:16-alpine $DOCKER_HUB_USERNAME/krushi-postgres:16-alpine
docker push $DOCKER_HUB_USERNAME/krushi-postgres:16-alpine
echo "✓ PostgreSQL done"
echo ""

# 11. Redis
echo "Re-tagging Redis..."
docker pull redis:7-alpine
docker tag redis:7-alpine $DOCKER_HUB_USERNAME/krushi-redis:7-alpine
docker push $DOCKER_HUB_USERNAME/krushi-redis:7-alpine
echo "✓ Redis done"
echo ""

# 12. Zookeeper
echo "Re-tagging Zookeeper..."
docker pull confluentinc/cp-zookeeper:7.5.0
docker tag confluentinc/cp-zookeeper:7.5.0 $DOCKER_HUB_USERNAME/krushi-zookeeper:7.5.0
docker push $DOCKER_HUB_USERNAME/krushi-zookeeper:7.5.0
echo "✓ Zookeeper done"
echo ""

# 13. Kafka
echo "Re-tagging Kafka..."
docker pull confluentinc/cp-kafka:7.5.0
docker tag confluentinc/cp-kafka:7.5.0 $DOCKER_HUB_USERNAME/krushi-kafka:7.5.0
docker push $DOCKER_HUB_USERNAME/krushi-kafka:7.5.0
echo "✓ Kafka done"
echo ""

echo "=========================================="
echo "All images pushed successfully!"
echo "=========================================="
echo "Docker Hub: https://hub.docker.com/u/$DOCKER_HUB_USERNAME"
echo ""
