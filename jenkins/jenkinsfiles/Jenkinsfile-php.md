# Jenkinsfile-php.md

Template pipeline for generic PHP applications using Composer install, PHPUnit tests, Docker image build, and registry push.

## Pipeline

```groovy
pipeline {
  agent any
  environment {
    REGISTRY = "your.registry.example.com/my-php-app"
    REGISTRY_CREDENTIALS = 'registry-credentials-id'
  }
  stages {
    stage('Checkout') { steps { checkout scm } }
    stage('Install') {
      steps {
        sh 'composer install --no-interaction --prefer-dist'
      }
    }
    stage('Test') {
      steps { sh 'vendor/bin/phpunit --configuration phpunit.xml' }
    }
    stage('Build Image') {
      steps {
        sh 'docker build -t ${REGISTRY}:${BUILD_NUMBER} .'
      }
    }
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
