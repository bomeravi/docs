# Secrets

Handling Secrets in Jenkins

1) Use Jenkins Credentials store (recommended)
   - Username/password, secret text, SSH keys, file credentials.
   - Add credentials via Jenkins UI or via Jenkins Configuration as Code.

2) Use `withCredentials` in pipelines:

```groovy
withCredentials([string(credentialsId: 'MY_SECRET', variable: 'TOKEN')]) {
  sh 'echo $TOKEN | some-command'
}

withCredentials([usernamePassword(credentialsId: 'REG_CREDS', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
  sh 'echo $PASS | docker login -u $USER --password-stdin registry'
}
```

3) Avoid printing secrets to logs. Use `mask` or credential bindings and avoid `echo` of secret variables.

4) For file-based secrets, use file credentials and reference the path provided in the pipeline.

5) For Kubernetes deployments, prefer injecting secrets via Kubernetes Secrets and using service accounts.
