FROM maven:3.9.9-eclipse-temurin-21 AS builder

WORKDIR /app

# Copy parent pom
COPY pom.xml .

# Copy all module pom files (needed for Maven to resolve parent pom)
COPY api-gateway/pom.xml ./api-gateway/
COPY auth-service/pom.xml ./auth-service/
COPY farmer-service/pom.xml ./farmer-service/

# Download dependencies for api-gateway
RUN mvn dependency:go-offline -pl :api-gateway -am -DskipTests

# Copy api-gateway source only
COPY api-gateway/src ./api-gateway/src

# Build the application (spring-boot:repackage creates executable jar)
RUN mvn clean package spring-boot:repackage -DskipTests -pl :api-gateway

FROM eclipse-temurin:21-jdk AS runner

# Install curl for healthcheck
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/api-gateway/target/api-gateway-0.0.1-SNAPSHOT.jar ./app.jar

EXPOSE 4004

ENTRYPOINT ["java", "-jar", "app.jar"]
