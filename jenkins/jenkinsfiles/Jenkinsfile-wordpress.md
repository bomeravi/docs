# Jenkinsfile-wordpress.md

Template pipeline for WordPress container images focused on checkout, Docker build, and registry publish steps.

## Pipeline

```groovy
pipeline {
  agent any
  environment {
    REGISTRY = "your.registry.example.com/my-wordpress"
    REGISTRY_CREDENTIALS = 'registry-credentials-id'
  }
  stages {
    stage('Checkout') { steps { checkout scm } }
    stage('Build Image') {
      steps { sh 'docker build -t ${REGISTRY}:${BUILD_NUMBER} .' }
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
