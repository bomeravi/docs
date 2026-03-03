# Jenkinsfile-java.md

Template pipeline for Java services using Maven wrapper for build/test, followed by Docker build and push.

## Pipeline

```groovy
pipeline {
  agent any
  environment {
    REGISTRY = "your.registry.example.com/my-java-service"
    REGISTRY_CREDENTIALS = 'registry-credentials-id'
  }
  stages {
    stage('Checkout') { steps { checkout scm } }
    stage('Build') { steps { sh './mvnw -B -DskipTests clean package' } }
    stage('Test') { steps { sh './mvnw test' } }
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
