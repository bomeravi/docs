# Jenkinsfile-docs-k8s.md

Template pipeline for docs deployment:

- build image: `bomeravi/docs:latest`
- push to Docker Hub
- deploy manifests from `k8s/kubernetes`

## Pipeline

```groovy
pipeline {
  agent any

  environment {
    IMAGE_NAME = 'bomeravi/docs:latest'
    K8S_NAMESPACE = 'docs'
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build Docker Image') {
      steps { sh 'docker build -t ${IMAGE_NAME} .' }
    }

    stage('Push Docker Image') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin
            docker push ${IMAGE_NAME}
            docker logout
          '''
        }
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        withCredentials([file(credentialsId: 'kubeconfig-prod', variable: 'KUBECONFIG_FILE')]) {
          sh '''
            export KUBECONFIG="${KUBECONFIG_FILE}"
            kubectl apply -f k8s/kubernetes/01-namespace.yaml
            kubectl apply -f k8s/kubernetes/02-clusterissuer.yaml
            kubectl apply -f k8s/kubernetes/03-deployment.yaml
            kubectl apply -f k8s/kubernetes/04-service.yaml
            kubectl apply -f k8s/kubernetes/05-ingress.yaml
            kubectl rollout status deployment/docs -n ${K8S_NAMESPACE}
          '''
        }
      }
    }
  }
}
```

Copy this pipeline to repository root as `Jenkinsfile` or use the included root-level `Jenkinsfile`.
