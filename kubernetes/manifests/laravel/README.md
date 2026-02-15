# Laravel Kubernetes Example

This example uses a PHP-FPM container behind an Nginx ingress or separate Nginx deployment. The `deployment.yaml` here is a minimal PHP-FPM deployment — adapt to your build process (Dockerfile, image registry) and add a webserver container or Ingress.

Replace `your-registry/laravel:latest` with your built image.
