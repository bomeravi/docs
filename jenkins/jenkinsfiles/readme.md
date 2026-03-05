# Jenkinsfiles

Jenkins declarative pipeline templates for common stacks. All templates in this folder are now Markdown files with descriptions and embedded pipeline snippets.

## Files

- [Jenkinsfile-docs-k8s.md](./Jenkinsfile-docs-k8s.md) - Docs pipeline building `bomeravi/docs:latest`, pushing Docker Hub, and deploying Kubernetes manifests.
- [Jenkinsfile-django.md](./Jenkinsfile-django.md) - Django pipeline with migrate, collectstatic, tests, build, and push.
- [Jenkinsfile-go.md](./Jenkinsfile-go.md) - Go pipeline with binary build, tests, container build, and push.
- [Jenkinsfile-java.md](./Jenkinsfile-java.md) - Java pipeline using Maven wrapper build/test, then image build and push.
- [Jenkinsfile-laravel.md](./Jenkinsfile-laravel.md) - Laravel pipeline with Composer install, migration, tests, and publish.
- [Jenkinsfile-php.md](./Jenkinsfile-php.md) - PHP pipeline with Composer install, PHPUnit tests, and publish.
- [Jenkinsfile-python.md](./Jenkinsfile-python.md) - Python pipeline with requirements install, pytest, and publish.
- [Jenkinsfile-react.md](./Jenkinsfile-react.md) - React pipeline with npm build and container publish.
- [Jenkinsfile-wordpress.md](./Jenkinsfile-wordpress.md) - WordPress pipeline with container build and publish.
