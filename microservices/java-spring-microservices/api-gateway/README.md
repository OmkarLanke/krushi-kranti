# API Gateway Service

## Overview
The API Gateway is the entry point for all external REST requests from client applications (Farmer App, VCP Operator App, Admin Portal). It handles routing, JWT validation, and header injection for downstream services.

## Port
- **4004**

## Features
- Spring Cloud Gateway for routing
- JWT token validation (to be fully implemented with Auth Service)
- Header injection (X-User-Id, X-User-Roles)
- CORS configuration
- Global exception handling
- Health check endpoint

## Routes
The gateway routes requests to the following services:
- `/auth/**` → Auth Service (4005)
- `/farmer/**` → Farmer Service (4000)
- `/funding/**` → Funding Service (4001)
- `/inventory/**` → Inventory Service (4002)
- `/procurement/**` → Procurement Service (4003)
- `/payment/**` → Payment Service (4006)
- `/profile/**` → Profile Service (4007)
- `/file/**` → File/Media Service (4008)
- `/notification/**` → Notification Service (4009)
- `/chat/**` → Chat/Tadnya Service (4010)
- `/advisory/**` → Advisory Service (4011)
- `/support/**` → Support Service (4012)

## Public Endpoints (No JWT Required)
- `/auth/login`
- `/auth/register`
- `/auth/verify-otp`
- `/actuator/health`

## Configuration
- Application properties: `application.yml`
- Docker profile: `application-docker.yml`
- JWT validation can be disabled via `gateway.jwt.enabled=false`

## Building
```bash
mvn clean install -pl :api-gateway -am
```

## Running
```bash
# Local
mvn spring-boot:run -pl :api-gateway

# Docker
docker-compose up api-gateway
```

## TODO
- [ ] Implement full JWT validation with JWKS from Auth Service
- [ ] Add rate limiting
- [ ] Add request/response logging
- [ ] Add circuit breaker pattern
- [ ] Add metrics and monitoring

