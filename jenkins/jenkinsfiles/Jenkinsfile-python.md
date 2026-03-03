# Jenkinsfile-python.md

Template pipeline for Python applications installing requirements, running pytest, and publishing a Docker image.

## Pipeline

```groovy
pipeline {
  agent any
  environment {
    REGISTRY = "your.registry.example.com/my-python-app"
    REGISTRY_CREDENTIALS = 'registry-credentials-id'
  }
  stages {
    stage('Checkout') { steps { checkout scm } }
    stage('Install') { steps { sh 'python -m pip install -r requirements.txt' } }
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
