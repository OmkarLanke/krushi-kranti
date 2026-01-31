# Build and Push All Images to Docker Hub
# Usage: .\build-and-push-all-images.ps1 yourusername

param(
    [Parameter(Mandatory=$true)]
    [string]$DockerHubUsername
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Building and Pushing All Images" -ForegroundColor Cyan
Write-Host "Docker Hub Username: $DockerHubUsername" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Navigate to microservices directory
Set-Location "d:\KrushiKranti\microservices"

Write-Host "==========================================" -ForegroundColor Yellow
Write-Host "Building and Pushing Microservices" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Yellow
Write-Host ""

# 1. API Gateway
Write-Host "Building API Gateway..." -ForegroundColor Green
docker build -t "$DockerHubUsername/krushi-api-gateway:latest" -f ./java-spring-microservices/api-gateway/Dockerfile ./java-spring-microservices
if ($LASTEXITCODE -eq 0) {
    docker push "$DockerHubUsername/krushi-api-gateway:latest"
    Write-Host "Done API Gateway" -ForegroundColor Green
} else {
    Write-Host "Failed to build API Gateway" -ForegroundColor Red
}
Write-Host ""

# 2. Auth Service
Write-Host "Building Auth Service..." -ForegroundColor Green
docker build -t "$DockerHubUsername/krushi-auth-service:latest" -f ./java-spring-microservices/auth-service/Dockerfile ./java-spring-microservices
if ($LASTEXITCODE -eq 0) {
    docker push "$DockerHubUsername/krushi-auth-service:latest"
    Write-Host "Done Auth Service" -ForegroundColor Green
} else {
    Write-Host "Failed to build Auth Service" -ForegroundColor Red
}
Write-Host ""

# 3. Farmer Service
Write-Host "Building Farmer Service..." -ForegroundColor Green
docker build -t "$DockerHubUsername/krushi-farmer-service:latest" -f ./java-spring-microservices/farmer-service/Dockerfile ./java-spring-microservices
if ($LASTEXITCODE -eq 0) {
    docker push "$DockerHubUsername/krushi-farmer-service:latest"
    Write-Host "Done Farmer Service" -ForegroundColor Green
} else {
    Write-Host "Failed to build Farmer Service" -ForegroundColor Red
}
Write-Host ""

# 4. Field Officer Service
Write-Host "Building Field Officer Service..." -ForegroundColor Green
docker build -t "$DockerHubUsername/krushi-field-officer-service:latest" -f ./java-spring-microservices/field-officer-service/Dockerfile ./java-spring-microservices
if ($LASTEXITCODE -eq 0) {
    docker push "$DockerHubUsername/krushi-field-officer-service:latest"
    Write-Host "Done Field Officer Service" -ForegroundColor Green
} else {
    Write-Host "Failed to build Field Officer Service" -ForegroundColor Red
}
Write-Host ""

# 5. Subscription Service
Write-Host "Building Subscription Service..." -ForegroundColor Green
docker build -t "$DockerHubUsername/krushi-subscription-service:latest" -f ./java-spring-microservices/subscription-service/Dockerfile ./java-spring-microservices
if ($LASTEXITCODE -eq 0) {
    docker push "$DockerHubUsername/krushi-subscription-service:latest"
    Write-Host "Done Subscription Service" -ForegroundColor Green
} else {
    Write-Host "Failed to build Subscription Service" -ForegroundColor Red
}
Write-Host ""

# 6. KYC Service
Write-Host "Building KYC Service..." -ForegroundColor Green
docker build -t "$DockerHubUsername/krushi-kyc-service:latest" -f ./java-spring-microservices/kyc-service/Dockerfile ./java-spring-microservices
if ($LASTEXITCODE -eq 0) {
    docker push "$DockerHubUsername/krushi-kyc-service:latest"
    Write-Host "Done KYC Service" -ForegroundColor Green
} else {
    Write-Host "Failed to build KYC Service" -ForegroundColor Red
}
Write-Host ""

# 7. Notification Service
Write-Host "Building Notification Service..." -ForegroundColor Green
docker build -t "$DockerHubUsername/krushi-notification-service:latest" -f ./java-spring-microservices/notification-service/Dockerfile ./java-spring-microservices
if ($LASTEXITCODE -eq 0) {
    docker push "$DockerHubUsername/krushi-notification-service:latest"
    Write-Host "Done Notification Service" -ForegroundColor Green
} else {
    Write-Host "Failed to build Notification Service" -ForegroundColor Red
}
Write-Host ""

# 8. File Service
Write-Host "Building File Service..." -ForegroundColor Green
docker build -t "$DockerHubUsername/krushi-file-service:latest" -f ./java-spring-microservices/file-service/Dockerfile ./java-spring-microservices
if ($LASTEXITCODE -eq 0) {
    docker push "$DockerHubUsername/krushi-file-service:latest"
    Write-Host "Done File Service" -ForegroundColor Green
} else {
    Write-Host "Failed to build File Service" -ForegroundColor Red
}
Write-Host ""

# Navigate to repo root for frontend
Set-Location "d:\KrushiKranti"

Write-Host "==========================================" -ForegroundColor Yellow
Write-Host "Building and Pushing Frontend" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Yellow
Write-Host ""

# 9. Frontend (Production)
Write-Host "Building Frontend (Production)..." -ForegroundColor Green
docker build -t "$DockerHubUsername/krushi-frontend:latest" --build-arg BASE_URL=https://api.krushikranti.ltd -f ./frontend/Dockerfile .
if ($LASTEXITCODE -eq 0) {
    docker push "$DockerHubUsername/krushi-frontend:latest"
    Write-Host "Done Frontend" -ForegroundColor Green
} else {
    Write-Host "Failed to build Frontend" -ForegroundColor Red
}
Write-Host ""

Write-Host "==========================================" -ForegroundColor Yellow
Write-Host "Re-tagging and Pushing Official Images" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Yellow
Write-Host ""

# 10. PostgreSQL
Write-Host "Re-tagging PostgreSQL..." -ForegroundColor Green
docker pull postgres:16-alpine
docker tag postgres:16-alpine "$DockerHubUsername/krushi-postgres:16-alpine"
docker push "$DockerHubUsername/krushi-postgres:16-alpine"
Write-Host "Done PostgreSQL" -ForegroundColor Green
Write-Host ""

# 11. Redis
Write-Host "Re-tagging Redis..." -ForegroundColor Green
docker pull redis:7-alpine
docker tag redis:7-alpine "$DockerHubUsername/krushi-redis:7-alpine"
docker push "$DockerHubUsername/krushi-redis:7-alpine"
Write-Host "Done Redis" -ForegroundColor Green
Write-Host ""

# 12. Zookeeper
Write-Host "Re-tagging Zookeeper..." -ForegroundColor Green
docker pull confluentinc/cp-zookeeper:7.5.0
docker tag confluentinc/cp-zookeeper:7.5.0 "$DockerHubUsername/krushi-zookeeper:7.5.0"
docker push "$DockerHubUsername/krushi-zookeeper:7.5.0"
Write-Host "Done Zookeeper" -ForegroundColor Green
Write-Host ""

# 13. Kafka
Write-Host "Re-tagging Kafka..." -ForegroundColor Green
docker pull confluentinc/cp-kafka:7.5.0
docker tag confluentinc/cp-kafka:7.5.0 "$DockerHubUsername/krushi-kafka:7.5.0"
docker push "$DockerHubUsername/krushi-kafka:7.5.0"
Write-Host "Done Kafka" -ForegroundColor Green
Write-Host ""

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "All images pushed successfully!" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
