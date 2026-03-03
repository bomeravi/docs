# Jenkinsfile-django.md

Template pipeline for Django apps including dependency install, migrations, collectstatic, tests, and Docker image publish.

## Pipeline

```groovy
pipeline {
  agent any
  environment {
    REGISTRY = "your.registry.example.com/my-django-app"
    REGISTRY_CREDENTIALS = 'registry-credentials-id'
  }
  stages {
    stage('Checkout') { steps { checkout scm } }
    stage('Install') { steps { sh 'python -m pip install -r requirements.txt' } }
    stage('Migrate/Collect') {
      steps {
        sh 'python manage.py migrate --noinput'
        sh 'python manage.py collectstatic --noinput'
      }
    }
    stage('Test') { steps { sh 'pytest -q' } }
    stage('Build Image') { steps { sh 'docker build -t ${REGISTRY}:${BUILD_NUMBER} .' } }
    stage('Push') {
      steps {
        withCredentials([usernamePassword(credentialsId: env.REGISTRY_CREDENTIALS, usernameVariable: 'USER', passwordVariable: 'PASS')]) {
          sh 'echo $PASS | docker login -u $USER --password-stdin your.registry.example.com'
          sh 'docker push ${REGISTRY}:${BUILD_NUMBER}'
        }
      }
    }
  }
}
```

Copy the pipeline into your repository root as `Jenkinsfile` and adjust registry/credentials/build commands for your project.
