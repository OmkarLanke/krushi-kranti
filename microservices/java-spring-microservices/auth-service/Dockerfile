FROM maven:3.9.9-eclipse-temurin-21 AS builder

WORKDIR /app

# Copy parent pom
COPY pom.xml .

# Copy all module pom files (needed for Maven to resolve parent pom)
COPY api-gateway/pom.xml ./api-gateway/
COPY auth-service/pom.xml ./auth-service/
COPY farmer-service/pom.xml ./farmer-service/

# Download dependencies for auth-service
RUN mvn dependency:go-offline -pl :auth-service -am -DskipTests

# Copy auth-service source only
COPY auth-service/src ./auth-service/src

# Build the application (spring-boot:repackage creates executable jar)
RUN mvn clean package spring-boot:repackage -DskipTests -pl :auth-service

FROM eclipse-temurin:21-jdk AS runner

# Install curl for healthcheck
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/auth-service/target/auth-service-0.0.1-SNAPSHOT.jar ./app.jar

EXPOSE 4005 9090

ENTRYPOINT ["java", "-jar", "app.jar"]
