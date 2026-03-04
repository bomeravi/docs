# Docker

## Table of Contents
- [Installation](#installation)
  - [Ubuntu](#ubuntu-installation)
  - [Windows](#windows-installation)
  - [macOS](#macos-installation)
- [Docker Commands](#docker-commands)
- [Dockerfile Examples](#dockerfile-examples)
- [Docker Compose Examples](#docker-compose-examples)

---

## Installation

### Ubuntu Installation

#### Method 1: Official Docker Repository

```bash
# Update package index
sudo apt-get update

# Install prerequisites
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verify installation
sudo docker run hello-world
```
#### Method 2: Convenience Script

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```
Post-installation Steps (Ubuntu)
Add your user to docker group
```bash
sudo usermod -aG docker $USER

# Activate changes to groups
newgrp docker

# Enable Docker to start on boot
sudo systemctl enable docker.service
sudo systemctl enable containerd.service

# Verify Docker is running
docker --version
docker compose version
```

### Windows Installation
Requirements
Windows 10 64-bit: Pro, Enterprise, or Education (Build 16299 or later)
OR Windows 11 64-bit
WSL 2 enabled
Hardware virtualization enabled in BIOS
Installation Steps
Enable WSL 2
```PowerShell

# Run in PowerShell as Administrator
wsl --install
```
Download Docker Desktop

Visit: https://www.docker.com/products/docker-desktop
Download Docker Desktop for Windows
Run the installer (Docker Desktop Installer.exe)
Installation Process

Follow the installation wizard
Ensure "Use WSL 2 instead of Hyper-V" is selected
Restart your computer when prompted
Verify Installation

```PowerShell

docker --version
docker compose version
docker run hello-world
```

Post-installation (Windows)
Configure Docker to start on boot (usually default)
Settings > General > "Start Docker Desktop when you log in"

Configure WSL 2 integration
Settings > Resources > WSL Integration
Enable integration with your WSL 2 distros

### macOS Installation
Requirements
macOS 11 or newer (for Apple Silicon)
macOS 10.15 or newer (for Intel)
Installation Steps
Download Docker Desktop

Visit: https://www.docker.com/products/docker-desktop
Choose the appropriate version:
Apple Silicon (M1/M2)
Intel Chip
Install Docker Desktop

Open the downloaded .dmg file
Drag Docker icon to Applications folder
Launch Docker from Applications
First Launch

Docker will request privileged access
Enter your password to proceed
Wait for Docker to start
Verify Installation

```bash
docker --version
docker compose version
docker run hello-world
Using Homebrew (Alternative)
```

### Install Homebrew if not installed
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
### Install Docker Desktop
```
brew install --cask docker
```
### Launch Docker Desktop
open /Applications/Docker.app
## Docker Commands
Container Management

```
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# Run a container
docker run <image>

# Run container in detached mode
docker run -d <image>

# Run container with name
docker run --name <container_name> <image>

# Run container with port mapping
docker run -p <host_port>:<container_port> <image>

# Run container with environment variables
docker run -e ENV_VAR=value <image>

# Run container with volume
docker run -v <host_path>:<container_path> <image>

# Run interactive container
docker run -it <image> /bin/bash

# Start a stopped container
docker start <container_id/name>

# Stop a running container
docker stop <container_id/name>

# Restart a container
docker restart <container_id/name>

# Pause a container
docker pause <container_id/name>

# Unpause a container
docker unpause <container_id/name>

# Remove a container
docker rm <container_id/name>

# Remove a running container (force)
docker rm -f <container_id/name>

# Remove all stopped containers
docker container prune

# Execute command in running container
docker exec <container_id/name> <command>

# Execute interactive shell in running container
docker exec -it <container_id/name> /bin/bash

# View container logs
docker logs <container_id/name>

# Follow container logs
docker logs -f <container_id/name>

# View last N lines of logs
docker logs --tail <number> <container_id/name>

# Inspect container
docker inspect <container_id/name>

# View container stats
docker stats <container_id/name>

# View container processes
docker top <container_id/name>

# Copy files from container to host
docker cp <container_id>:<container_path> <host_path>

# Copy files from host to container
docker cp <host_path> <container_id>:<container_path>

# Rename container
docker rename <old_name> <new_name>

# Wait for container to stop
docker wait <container_id/name>

# Attach to running container
docker attach <container_id/name>
```

Image Management
```

# List images
docker images

# List all images (including intermediate)
docker images -a

# Pull image from registry
docker pull <image>:<tag>

# Pull specific image version
docker pull <image>:1.0.0

# Push image to registry
docker push <image>:<tag>

# Build image from Dockerfile
docker build -t <image_name>:<tag> <path>

# Build with no cache
docker build --no-cache -t <image_name> .

# Build with build arguments
docker build --build-arg ARG_NAME=value -t <image_name> .

# Tag an image
docker tag <image_id> <new_name>:<tag>

# Remove an image
docker rmi <image_id/name>

# Remove image (force)
docker rmi -f <image_id/name>

# Remove unused images
docker image prune

# Remove all unused images
docker image prune -a

# Search for images
docker search <term>

# View image history
docker history <image>

# Inspect image
docker inspect <image>

# Save image to tar file
docker save <image> > image.tar
docker save -o image.tar <image>

# Load image from tar file
docker load < image.tar
docker load -i image.tar

# Export container to tar
docker export <container_id> > container.tar

# Import tar as image
docker import container.tar <image_name>:<tag>
```
Network Management
```

# List networks
docker network ls

# Create network
docker network create <network_name>

# Create network with subnet
docker network create --subnet=172.18.0.0/16 <network_name>

# Create bridge network
docker network create --driver bridge <network_name>

# Inspect network
docker network inspect <network_name>

# Connect container to network
docker network connect <network_name> <container_name>

# Disconnect container from network
docker network disconnect <network_name> <container_name>

# Remove network
docker network rm <network_name>

# Remove unused networks
docker network prune
Volume Management
Bash

# List volumes
docker volume ls

# Create volume
docker volume create <volume_name>

# Inspect volume
docker volume inspect <volume_name>

# Remove volume
docker volume rm <volume_name>

# Remove unused volumes
docker volume prune

# Remove all unused volumes
docker volume prune -a
Docker Compose Commands
Bash

# Start services
docker compose up

# Start services in detached mode
docker compose up -d

# Start specific service
docker compose up <service_name>

# Build services
docker compose build

# Build without cache
docker compose build --no-cache

# Start services and build
docker compose up --build

# Stop services
docker compose stop

# Stop and remove containers
docker compose down

# Stop and remove containers, networks, volumes
docker compose down -v

# View running services
docker compose ps

# View logs
docker compose logs

# Follow logs
docker compose logs -f

# View logs for specific service
docker compose logs <service_name>

# Execute command in service
docker compose exec <service_name> <command>

# Run one-off command
docker compose run <service_name> <command>

# Scale services
docker compose up -d --scale <service_name>=<number>

# Restart services
docker compose restart

# Pause services
docker compose pause

# Unpause services
docker compose unpause

# Validate compose file
docker compose config

# Pull service images
docker compose pull

# Push service images
docker compose push

# View processes
docker compose top
```
System Commands
```

# View Docker disk usage
docker system df

# Remove unused data
docker system prune

# Remove all unused data (including volumes)
docker system prune -a --volumes

# View Docker info
docker info

# View Docker version
docker version

# Login to registry
docker login

# Login to specific registry
docker login <registry_url>

# Logout from registry
docker logout

# View events
docker events

# View events with filter
docker events --filter 'event=start'
Registry Commands
Bash

# Login to Docker Hub
docker login

# Login with username and password
docker login -u <username> -p <password>

# Login to private registry
docker login <registry_url>

# Logout
docker logout

# Tag image for registry
docker tag <image> <registry>/<repository>:<tag>

# Push to registry
docker push <registry>/<repository>:<tag>

# Pull from registry
docker pull <registry>/<repository>:<tag>
```
Useful Command Combinations
```

# Stop all running containers
docker stop $(docker ps -q)

# Remove all containers
docker rm $(docker ps -a -q)

# Remove all images
docker rmi $(docker images -q)

# Remove dangling images
docker rmi $(docker images -f "dangling=true" -q)

# Remove exited containers
docker rm $(docker ps -a -f status=exited -q)

# View container IP address
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <container_name>

# View container environment variables
docker exec <container_name> env

# Clean up everything
docker system prune -a --volumes
```
## Dockerfile Examples
Basic Dockerfile (Node.js)
``` Dockerfile

# Use official Node.js runtime as base image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy application files
COPY . .

# Expose port
EXPOSE 3000

# Define environment variable
ENV NODE_ENV=production

# Run application
CMD ["node", "app.js"]
Multi-stage Build (Node.js)
Dockerfile

# Stage 1: Build
FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

# Stage 2: Production
FROM node:18-alpine

WORKDIR /app

# Copy only necessary files from builder
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

EXPOSE 3000

USER node

CMD ["node", "dist/main.js"]
```
Python Application
```Dockerfile

FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Create non-root user
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

CMD ["python", "app.py"]
```
Go Application
```Dockerfile

# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Production stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

COPY --from=builder /app/main .

EXPOSE 8080

CMD ["./main"]
```
Java Application
```Dockerfile

# Build stage
FROM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /app

COPY pom.xml .
RUN mvn dependency:go-offline

COPY src ./src
RUN mvn package -DskipTests

# Production stage
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

COPY --from=builder /app/target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
```
Nginx with Custom Config
```Dockerfile

FROM nginx:alpine

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom nginx config
COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d/ /etc/nginx/conf.d/

# Copy static files
COPY dist/ /usr/share/nginx/html/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```
PHP Application
```Dockerfile

FROM php:8.2-fpm-alpine

# Install dependencies
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    zip \
    unzip

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd pdo pdo_mysql

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY composer*.json ./
RUN composer install --no-dev --optimize-autoloader

COPY . .

RUN chown -R www-data:www-data /var/www/html

EXPOSE 9000

CMD ["php-fpm"]
```
WordPress
```Dockerfile

FROM wordpress:latest

# Install additional PHP extensions
RUN docker-php-ext-install exif

# Copy custom php.ini
COPY php.ini /usr/local/etc/php/conf.d/custom.ini

# Copy custom wp-config
COPY wp-config.php /var/www/html/

EXPOSE 80

CMD ["apache2-foreground"]
```
## Docker Compose Examples
Basic Web Application (Node.js + MongoDB)
``` YAML

version: '3.8'

services:
  app:
    build: .
    container_name: node-app
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - MONGODB_URI=mongodb://mongo:27017/mydb
    depends_on:
      - mongo
    volumes:
      - ./:/app
      - /app/node_modules
    networks:
      - app-network

  mongo:
    image: mongo:6
    container_name: mongodb
    restart: unless-stopped
    ports:
      - "27017:27017"
    environment:
      - MONGO_INITDB_ROOT_USERNAME=admin
      - MONGO_INITDB_ROOT_PASSWORD=secret
    volumes:
      - mongo-data:/data/db
    networks:
      - app-network

volumes:
  mongo-data:

networks:
  app-network:
    driver: bridge
Full Stack Application (React + Node + PostgreSQL + Redis)
YAML

version: '3.8'

services:
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: react-app
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - REACT_APP_API_URL=http://localhost:5000
    volumes:
      - ./frontend:/app
      - /app/node_modules
    networks:
      - fullstack-network
    depends_on:
      - backend

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: node-backend
    restart: unless-stopped
    ports:
      - "5000:5000"
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/myapp
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=your-secret-key
    volumes:
      - ./backend:/app
      - /app/node_modules
    depends_on:
      - db
      - redis
    networks:
      - fullstack-network

  db:
    image: postgres:15-alpine
    container_name: postgres-db
    restart: unless-stopped
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=myapp
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - fullstack-network

  redis:
    image: redis:7-alpine
    container_name: redis-cache
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    networks:
      - fullstack-network

volumes:
  postgres-data:
  redis-data:

networks:
  fullstack-network:
    driver: bridge
```

WordPress with MySQL and phpMyAdmin
``` YAML

version: '3.8'

services:
  wordpress:
    image: wordpress:latest
    container_name: wordpress
    restart: unless-stopped
    ports:
      - "8080:80"
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_DB_USER: wpuser
      WORDPRESS_DB_PASSWORD: wppassword
    volumes:
      - wordpress-data:/var/www/html
    depends_on:
      - db
    networks:
      - wp-network

  db:
    image: mysql:8.0
    container_name: mysql
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wpuser
      MYSQL_PASSWORD: wppassword
      MYSQL_ROOT_PASSWORD: rootpassword
    volumes:
      - db-data:/var/lib/mysql
    networks:
      - wp-network

  phpmyadmin:
    image: phpmyadmin:latest
    container_name: phpmyadmin
    restart: unless-stopped
    ports:
      - "8081:80"
    environment:
      PMA_HOST: db
      MYSQL_ROOT_PASSWORD: rootpassword
    depends_on:
      - db
    networks:
      - wp-network

volumes:
  wordpress-data:
  db-data:

networks:
  wp-network:
    driver: bridge
```

Python Django with PostgreSQL and Nginx
``` YAML

version: '3.8'

services:
  web:
    build: .
    container_name: django-app
    command: gunicorn config.wsgi:application --bind 0.0.0.0:8000
    volumes:
      - .:/app
      - static_volume:/app/staticfiles
      - media_volume:/app/mediafiles
    expose:
      - 8000
    environment:
      - DATABASE_URL=postgresql://postgres:postgres@db:5432/django_db
      - SECRET_KEY=your-secret-key
      - DEBUG=False
    depends_on:
      - db
    networks:
      - django-network

  db:
    image: postgres:15-alpine
    container_name: postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data/
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=django_db
    networks:
      - django-network

  nginx:
    image: nginx:alpine
    container_name: nginx
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - static_volume:/app/staticfiles
      - media_volume:/app/mediafiles
    depends_on:
      - web
    networks:
      - django-network

volumes:
  postgres_data:
  static_volume:
  media_volume:

networks:
  django-network:
    driver: bridge
```

Microservices Architecture
``` YAML

version: '3.8'

services:
  api-gateway:
    build: ./api-gateway
    container_name: api-gateway
    restart: unless-stopped
    ports:
      - "8000:8000"
    environment:
      - USER_SERVICE_URL=http://user-service:3001
      - PRODUCT_SERVICE_URL=http://product-service:3002
      - ORDER_SERVICE_URL=http://order-service:3003
    networks:
      - microservices-network
    depends_on:
      - user-service
      - product-service
      - order-service

  user-service:
    build: ./user-service
    container_name: user-service
    restart: unless-stopped
    expose:
      - 3001
    environment:
      - DB_HOST=user-db
      - DB_PORT=5432
      - DB_NAME=users
      - DB_USER=postgres
      - DB_PASSWORD=password
    depends_on:
      - user-db
      - rabbitmq
    networks:
      - microservices-network

  product-service:
    build: ./product-service
    container_name: product-service
    restart: unless-stopped
    expose:
      - 3002
    environment:
      - DB_HOST=product-db
      - DB_PORT=5432
      - DB_NAME=products
      - DB_USER=postgres
      - DB_PASSWORD=password
    depends_on:
      - product-db
      - rabbitmq
    networks:
      - microservices-network

  order-service:
    build: ./order-service
    container_name: order-service
    restart: unless-stopped
    expose:
      - 3003
    environment:
      - DB_HOST=order-db
      - DB_PORT=5432
      - DB_NAME=orders
      - DB_USER=postgres
      - DB_PASSWORD=password
    depends_on:
      - order-db
      - rabbitmq
    networks:
      - microservices-network

  user-db:
    image: postgres:15-alpine
    container_name: user-db
    environment:
      - POSTGRES_DB=users
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    volumes:
      - user-db-data:/var/lib/postgresql/data
    networks:
      - microservices-network

  product-db:
    image: postgres:15-alpine
    container_name: product-db
    environment:
      - POSTGRES_DB=products
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    volumes:
      - product-db-data:/var/lib/postgresql/data
    networks:
      - microservices-network

  order-db:
    image: postgres:15-alpine
    container_name: order-db
    environment:
      - POSTGRES_DB=orders
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    volumes:
      - order-db-data:/var/lib/postgresql/data
    networks:
      - microservices-network

  rabbitmq:
    image: rabbitmq:3-management-alpine
    container_name: rabbitmq
    restart: unless-stopped
    ports:
      - "5672:5672"
      - "15672:15672"
    environment:
      - RABBITMQ_DEFAULT_USER=admin
      - RABBITMQ_DEFAULT_PASS=admin
    volumes:
      - rabbitmq-data:/var/lib/rabbitmq
    networks:
      - microservices-network

volumes:
  user-db-data:
  product-db-data:
  order-db-data:
  rabbitmq-data:

networks:
  microservices-network:
    driver: bridge
```

Development Environment (LAMP Stack)
```YAML

version: '3.8'

services:
  apache:
    image: php:8.2-apache
    container_name: apache-php
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - ./www:/var/www/html
    depends_on:
      - mysql
    networks:
      - lamp-network

  mysql:
    image: mysql:8.0
    container_name: mysql
    restart: unless-stopped
    ports:
      - "3306:3306"
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: myapp
      MYSQL_USER: user
      MYSQL_PASSWORD: password
    volumes:
      - mysql-data:/var/lib/mysql
    networks:
      - lamp-network

  phpmyadmin:
    image: phpmyadmin:latest
    container_name: phpmyadmin
    restart: unless-stopped
    ports:
      - "8080:80"
    environment:
      PMA_HOST: mysql
      MYSQL_ROOT_PASSWORD: rootpassword
    depends_on:
      - mysql
    networks:
      - lamp-network

volumes:
  mysql-data:

networks:
  lamp-network:
    driver: bridge
```

Monitoring Stack (Prometheus + Grafana)
```YAML

version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-data:/var/lib/grafana
    depends_on:
      - prometheus
    networks:
      - monitoring

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    ports:
      - "9100:9100"
    networks:
      - monitoring

volumes:
  prometheus-data:
  grafana-data:

networks:
  monitoring:
    driver: bridge
```

#### Best Practices
##### Dockerfile Best Practices
- Use specific tags, not latest
- Minimize layers - Combine RUN commands
- Use .dockerignore - Exclude unnecessary files
- Run as non-root user
- Use multi-stage builds - Keep images small
- Order layers from least to most frequently changing
- Use COPY instead of ADD unless you need tar extraction
- Set timezone if needed
- Clean up in the same layer to reduce image size
##### Docker Compose Best Practices
- Use version control for compose files
- Use environment files (.env) for sensitive data
- Define restart policies
- Use named volumes for data persistence
- Specify resource limits (memory, CPU)
- Use health checks
- Define dependencies properly with depends_on
- Use networks to isolate services
##### Security Best Practices
- Don't run containers as root
- Scan images for vulnerabilities
- Don't store secrets in images
- Use official images from trusted sources
- Keep images updated
- Limit container resources
- Use read-only file systems where possible
- Enable Docker Content Trust

#### Troubleshooting
##### Common Issues

```
# Container keeps restarting

docker logs <container_name>
docker inspect <container_name>
docker inspect --format='{{json .State.Health}}' <container_name>

# Permission denied

sudo usermod -aG docker $USER
newgrp docker


# Port already in use

sudo lsof -i :<port>
sudo kill -9 <PID>

# Out of disk space

docker system df
docker system prune -a --volumes


# Network issues

docker network ls
docker network inspect <network_name>

# DNS resolution issues

docker run --dns 8.8.8.8 <image>
```
#### Useful Resources
Official Docker Documentation
Docker Hub
Docker Compose Documentation
Dockerfile Reference
Docker Best Practices
```
Docker basics for local builds and for Jenkins CI

Build an image locally:

```bash
cd path/to/project
docker build -t my-app:local .
docker run --rm -p 8080:80 my-app:local
```

Build & run with docker-compose:

```bash
cd path/to/project
docker-compose up --build
```

To integrate with Jenkins, ensure your `Jenkinsfile` builds the Docker image and pushes to a registry Jenkins can access (use credentials in Jenkins' credentials store).

See the sample `docker-compose.yml` and per-app `Dockerfile` templates in this folder.