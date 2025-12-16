# Build stage
FROM maven:3.9-eclipse-temurin-21-alpine AS build
WORKDIR /app

# Copy parent pom
COPY pom.xml .

# Copy subscription-service pom and source
COPY subscription-service/pom.xml subscription-service/
COPY subscription-service/src subscription-service/src

# Build the service
RUN mvn clean package -pl :subscription-service -am -DskipTests

# Runtime stage
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Copy the built JAR
COPY --from=build /app/subscription-service/target/*.jar app.jar

# Expose ports
EXPOSE 4013 9093

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]

