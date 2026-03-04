# Python Dockerfile

Source: `docker/python/Dockerfile`

## Dockerfile

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["python","-m","http.server","8000"]
EXPOSE 8000
```

## What It Does

- Uses Python 3.11 slim image.
- Installs dependencies from `requirements.txt`.
- Starts a basic Python HTTP server on port `8000`.

## Required Files In Build Context

- `requirements.txt`
- Python project files

## Build

```bash
docker build -t python-app -f docker/python/Dockerfile .
```

## Run

```bash
docker run --rm -p 8000:8000 python-app
```
