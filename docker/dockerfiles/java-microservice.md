# Java Microservice Dockerfile

Source: `docker/java-microservice/Dockerfile`

## Dockerfile

```dockerfile
FROM maven:3.8.8-eclipse-temurin-17 AS builder
WORKDIR /workspace
COPY pom.xml mvnw ./
COPY .mvn .mvn
RUN mvn -B -DskipTests dependency:go-offline
COPY src ./src
RUN mvn -B -DskipTests package

FROM eclipse-temurin:17-jdk-jammy
WORKDIR /app
COPY --from=builder /workspace/target/*.jar /app/app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/app.jar"]
```

## What It Does

- Uses Maven stage to resolve dependencies and build a JAR.
- Copies the built JAR into a Temurin Java runtime image.
- Starts the application with `java -jar` on port `8080`.

## Required Files In Build Context

- `pom.xml`
- `mvnw`
- `.mvn/`
- `src/`

## Build

```bash
docker build -t java-microservice -f docker/java-microservice/Dockerfile .
```

## Run

```bash
docker run --rm -p 8080:8080 java-microservice
```
