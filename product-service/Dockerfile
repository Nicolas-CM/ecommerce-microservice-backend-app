

FROM eclipse-temurin:17-jre-alpine
ARG PROJECT_VERSION=0.1.0
WORKDIR /app
COPY target/product-service-v${PROJECT_VERSION}.jar app.jar
EXPOSE 8500
ENTRYPOINT ["java", "-jar", "app.jar"]


