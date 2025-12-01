

FROM eclipse-temurin:17-jre
ARG PROJECT_VERSION=0.1.0
WORKDIR /app
COPY target/shipping-service-v${PROJECT_VERSION}.jar app.jar
EXPOSE 8600
ENTRYPOINT ["java", "-jar", "app.jar"]


