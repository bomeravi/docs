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

- Resolves dependencies and builds a JAR with Maven.
- Copies the built JAR into a Java 17 runtime image.
- Starts the app on port `8080`.

## Required Files In Build Context

- `pom.xml`
- `mvnw`
- `.mvn/`
- `src/`

## Docker Compose Example

```yaml
version: '3.8'
services:
  app:
    build:
      context: .
      dockerfile: docker/java-microservice/Dockerfile
    container_name: java-microservice
    env_file:
      - .env
    environment:
      - SPRING_PROFILES_ACTIVE=prod
    ports:
      - "8080:8080"
    depends_on:
      - db
    restart: unless-stopped

  db:
    image: postgres:15-alpine
    container_name: java-db
    environment:
      - POSTGRES_DB=appdb
      - POSTGRES_USER=app
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  postgres_data:
```

## Other Files You Need

- `.env` with application and datasource values
- `src/main/resources/application.properties` or `application.yml`
- Database migration setup (Flyway/Liquibase) if used

## Build (Docker)

```bash
docker build -t java-microservice -f docker/java-microservice/Dockerfile .
```

## Run (Docker)

```bash
docker run --rm -p 8080:8080 java-microservice
```

## Run (Docker Compose)

```bash
docker compose up --build -d
```
