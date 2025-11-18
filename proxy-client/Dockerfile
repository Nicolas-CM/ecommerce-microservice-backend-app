

# Imagen base ligera
FROM eclipse-temurin:17-jre-alpine

ARG PROJECT_VERSION=0.1.0
WORKDIR /app

# Copia solo el jar final
COPY target/proxy-client-v${PROJECT_VERSION}.jar app.jar

EXPOSE 8900

# Comando de arranque simple
ENTRYPOINT ["java", "-jar", "app.jar"]


