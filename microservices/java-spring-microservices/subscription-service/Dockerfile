# Build stage
FROM maven:3.9.9-eclipse-temurin-21 AS build
WORKDIR /app

# Copy parent pom
COPY pom.xml .

# Create directories for all modules (Maven requires all modules in parent POM to exist)
RUN mkdir -p i18n-common api-gateway auth-service farmer-service subscription-service kyc-service

# Copy all module pom files (needed for Maven to resolve parent pom)
COPY i18n-common/pom.xml i18n-common/
COPY api-gateway/pom.xml api-gateway/
COPY auth-service/pom.xml auth-service/
COPY farmer-service/pom.xml farmer-service/
COPY subscription-service/pom.xml subscription-service/
COPY kyc-service/pom.xml kyc-service/

# Download dependencies for subscription-service
RUN mvn dependency:go-offline -pl :subscription-service -am -DskipTests

# Copy subscription-service source
COPY subscription-service/src subscription-service/src

# Build the service
RUN mvn clean package spring-boot:repackage -DskipTests -pl :subscription-service -am

# Runtime stage
FROM eclipse-temurin:21-jdk AS runner

# Install curl for healthcheck
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the built JAR
COPY --from=build /app/subscription-service/target/subscription-service-0.0.1-SNAPSHOT.jar ./app.jar

# Expose ports
EXPOSE 4013 9093

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]

