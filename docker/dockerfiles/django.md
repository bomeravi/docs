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

- Uses a slim Python 3.11 base image.
- Installs dependencies from `requirements.txt`.
- Copies application code into `/app`.
- Runs Django with Gunicorn on port `8000`.

## Required Files In Build Context

- `requirements.txt`
- Django project package with `myproject/wsgi.py` (or update the Gunicorn module path)

## Build

```bash
docker build -t django-app -f docker/django/Dockerfile .
```

## Run

```bash
docker run --rm -p 8000:8000 django-app
```
