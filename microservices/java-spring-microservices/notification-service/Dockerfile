FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
COPY notification-service/pom.xml ./notification-service/
COPY ../pom.xml ./../
RUN mvn dependency:go-offline -B
COPY notification-service ./notification-service
RUN mvn clean package -DskipTests -pl notification-service

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /app/notification-service/target/*.jar app.jar
EXPOSE 4016
ENTRYPOINT ["java", "-jar", "app.jar"]
