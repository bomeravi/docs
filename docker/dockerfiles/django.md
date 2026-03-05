# Django Dockerfile

Source: `docker/django/Dockerfile`

## Dockerfile

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
ENV PYTHONUNBUFFERED=1
CMD ["gunicorn","myproject.wsgi:application","--bind","0.0.0.0:8000"]
EXPOSE 8000
```

## What It Does

- Uses Python 3.11 slim image.
- Installs dependencies from `requirements.txt`.
- Copies project files into `/app`.
- Starts Django with Gunicorn on port `8000`.

## Required Files In Build Context

- `requirements.txt`
- `manage.py`
- Django project module containing `myproject/wsgi.py`

## Docker Compose Example

```yaml
version: '3.8'
services:
  web:
    build:
      context: .
      dockerfile: docker/django/Dockerfile
    container_name: django-app
    command: gunicorn myproject.wsgi:application --bind 0.0.0.0:8000
    env_file:
      - .env
    volumes:
      - .:/app
      - static_volume:/app/staticfiles
      - media_volume:/app/mediafiles
    depends_on:
      - db
    expose:
      - "8000"
    restart: unless-stopped

  db:
    image: postgres:15-alpine
    container_name: django-db
    environment:
      - POSTGRES_DB=django_db
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    container_name: django-nginx
    ports:
      - "80:80"
    volumes:
      - ./docker/django/nginx.conf:/etc/nginx/nginx.conf:ro
      - static_volume:/app/staticfiles
      - media_volume:/app/mediafiles
    depends_on:
      - web
    restart: unless-stopped

volumes:
  postgres_data:
  static_volume:
  media_volume:
```

## Other Files You Need

- `.env` with `SECRET_KEY`, `DEBUG`, `ALLOWED_HOSTS`, and DB vars
- `docker/django/nginx.conf` if using Nginx service
- Migration and static collection commands in your deploy/start scripts

## Build (Docker)

```bash
docker build -t django-app -f docker/django/Dockerfile .
```

## Run (Docker)

```bash
docker run --rm -p 8000:8000 django-app
```

## Run (Docker Compose)

```bash
docker compose up --build -d
```
