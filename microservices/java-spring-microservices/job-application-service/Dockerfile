FROM maven:3.9.9-eclipse-temurin-21 AS builder

WORKDIR /app

# Copy parent pom
COPY pom.xml .

# Create directories for all modules (Maven requires all modules in parent POM to exist)
RUN mkdir -p i18n-common api-gateway auth-service farmer-service field-officer-service subscription-service kyc-service file-service notification-service job-application-service support-service

# Copy all module pom files (needed for Maven to resolve parent pom)
COPY i18n-common/pom.xml ./i18n-common/
COPY api-gateway/pom.xml ./api-gateway/
COPY auth-service/pom.xml ./auth-service/
COPY farmer-service/pom.xml ./farmer-service/
COPY field-officer-service/pom.xml ./field-officer-service/
COPY subscription-service/pom.xml ./subscription-service/
COPY kyc-service/pom.xml ./kyc-service/
COPY file-service/pom.xml ./file-service/
COPY notification-service/pom.xml ./notification-service/
COPY job-application-service/pom.xml ./job-application-service/
COPY support-service/pom.xml ./support-service/

# Download dependencies for job-application-service
RUN mvn dependency:go-offline -pl :job-application-service -am -DskipTests

# Copy job-application-service source only
COPY job-application-service/src ./job-application-service/src

# Build the application (spring-boot:repackage creates executable jar)
RUN mvn clean package spring-boot:repackage -DskipTests -pl :job-application-service

# ============================================
# Runtime Stage
# ============================================
FROM eclipse-temurin:21-jre

WORKDIR /app

# Copy the built jar from builder stage
COPY --from=builder /app/job-application-service/target/*.jar app.jar

# Expose application port
EXPOSE 8086

# Set timezone
ENV TZ=Asia/Kolkata

# Run the application
ENTRYPOINT ["java", "-Duser.timezone=Asia/Kolkata", "-jar", "app.jar"]
