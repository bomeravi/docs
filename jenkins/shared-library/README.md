Shared Pipeline Library

Recommended structure for a Git-backed shared library:

```
vars/                 # global var steps callable from Jenkinsfile
  notify.groovy
src/                  # reusable java/groovy classes
resources/            # non-code resources (templates, config)
```

Example `vars/notify.groovy`:

```groovy
def call(String msg) {
  echo "SharedLib notify: ${msg}"
  // add Slack/Teams integration here using stored credentials
}
```

Usage in a `Jenkinsfile` (declarative):

```groovy
@Library('my-shared-lib@master') _
pipeline {
  agent any
  stages {
    stage('Build') { steps { sh 'echo build' } }
    stage('Notify') { steps { notify('Build done') } }
  }
}
```

How to configure in Jenkins:
- Create the library in Jenkins -> Manage Jenkins -> Configure System -> Global Pipeline Libraries.
- Add the Git repository, default version (branch/tag), and set retrieval method (modern SCM recommended).
