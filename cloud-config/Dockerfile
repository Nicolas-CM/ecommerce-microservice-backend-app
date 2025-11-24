

FROM eclipse-temurin:17-jre-alpine
ARG PROJECT_VERSION=0.1.0
WORKDIR /app
COPY target/cloud-config-v${PROJECT_VERSION}.jar app.jar
EXPOSE 9296
ENTRYPOINT ["java", "-jar", "app.jar"]


