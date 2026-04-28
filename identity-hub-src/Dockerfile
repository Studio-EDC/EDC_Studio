FROM gradle:8.10-jdk17 AS build

WORKDIR /src
COPY . .

RUN sed -i 's/\r$//' gradlew && chmod +x gradlew
RUN ./gradlew :launchers:identity-hub:shadowJar -Ppersistence=true

FROM eclipse-temurin:17-jre-alpine

RUN apk --no-cache add curl

WORKDIR /app
COPY --from=build /src/launchers/identity-hub/build/libs/identity-hub.jar /app/identity-hub.jar

EXPOSE 8181 8182 10001

HEALTHCHECK --interval=10s --timeout=5s --retries=10 CMD curl --fail http://localhost:8181/api/check/health

ENTRYPOINT ["java", "-Dedc.fs.config=/app/configuration/config.properties", "-jar", "/app/identity-hub.jar", "--log-level=debug"]
