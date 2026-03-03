# Jenkinsfile-react.md

Template pipeline for React apps running npm install/build, then packaging and pushing a Docker image.

## Pipeline

```groovy
pipeline {
  agent any
  environment {
    REGISTRY = "your.registry.example.com/my-react-app"
    REGISTRY_CREDENTIALS = 'registry-credentials-id'
  }
  stages {
    stage('Checkout') { steps { checkout scm } }
    stage('Install') { steps { sh 'npm ci' } }
    stage('Build') { steps { sh 'npm run build' } }
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
