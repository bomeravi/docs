# Jenkinsfile-sonarqube.md

Template pipeline that runs a SonarQube analysis and enforces the project's
Quality Gate. Requires the SonarQube server and Jenkins configuration described
in [SonarQube](/security/sonarqube.md) (§5): the **SonarQube Scanner** plugin, a server
named `SonarQube`, a scanner tool named `SonarScanner`, and the Quality Gate
webhook.

## Pipeline

```groovy
pipeline {
  agent any
  environment {
    SONAR_PROJECT_KEY = 'my-app'
  }
  stages {
    stage('Checkout') { steps { checkout scm } }

    stage('Build & Test') {
      steps {
        // Replace with the project's build/test + coverage report generation.
        sh 'echo "run tests and produce a coverage report here"'
      }
    }

    stage('SonarQube Analysis') {
      steps {
        script {
          def scannerHome = tool 'SonarScanner'
          withSonarQubeEnv('SonarQube') {
            sh """
              ${scannerHome}/bin/sonar-scanner \
                -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                -Dsonar.sources=.
            """
          }
        }
      }
    }

    stage('Quality Gate') {
      steps {
        timeout(time: 5, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }
    }
  }
}
```

Copy the pipeline into the repository root as `Jenkinsfile` and adjust
`SONAR_PROJECT_KEY`, `sonar.sources`, and the build/test/coverage commands to
match the project. To add analysis to an existing pipeline, drop the **SonarQube
Analysis** and **Quality Gate** stages into it instead of using this file whole.
