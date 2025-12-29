FROM maven:3.9.9-eclipse-temurin-21 AS builder

WORKDIR /app

# Copy parent pom
COPY pom.xml .

# Create directories for all modules (Maven requires all modules in parent POM to exist)
RUN mkdir -p i18n-common api-gateway auth-service farmer-service field-officer-service subscription-service kyc-service

# Copy all module pom files (needed for Maven to resolve parent pom)
COPY i18n-common/pom.xml ./i18n-common/
COPY api-gateway/pom.xml ./api-gateway/
COPY auth-service/pom.xml ./auth-service/
COPY farmer-service/pom.xml ./farmer-service/
COPY field-officer-service/pom.xml ./field-officer-service/
COPY subscription-service/pom.xml ./subscription-service/
COPY kyc-service/pom.xml ./kyc-service/

# Download dependencies for auth-service (includes i18n-common)
RUN mvn dependency:go-offline -pl :auth-service -am -DskipTests

# Install parent POM first (needed by i18n-common)
RUN mvn install -N -DskipTests

# Copy i18n-common source (dependency)
COPY i18n-common/src ./i18n-common/src

# Build and install i18n-common first (needed by auth-service)
RUN mvn clean install -pl :i18n-common -DskipTests

# Copy auth-service source
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
