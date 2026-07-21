# Multi-stage build for the NayaSantha API. Any Docker-based PaaS can build this.
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn -q -B dependency:go-offline
COPY src ./src
# Skip tests in the image build (integration tests need Docker/testcontainers).
RUN mvn -q -B clean package -DskipTests

FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /app/target/nayasantha-api-*.jar app.jar
# The platform injects PORT; Spring reads it via server.port=${PORT:8080}.
ENV JAVA_OPTS=""
ENTRYPOINT ["sh","-c","java $JAVA_OPTS -jar app.jar"]
