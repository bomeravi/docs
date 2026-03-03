# Jenkinsfile-go.md

Template pipeline for Go services compiling a Linux binary, executing tests, then building and publishing a container image.

## Pipeline

```groovy
pipeline {
  agent any
  environment {
    REGISTRY = "your.registry.example.com/my-go-service"
    REGISTRY_CREDENTIALS = 'registry-credentials-id'
  }
  stages {
    stage('Checkout') { steps { checkout scm } }
    stage('Build') { steps { sh 'CGO_ENABLED=0 GOOS=linux go build -v -o app .' } }
    stage('Test') { steps { sh 'go test ./...' } }
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
