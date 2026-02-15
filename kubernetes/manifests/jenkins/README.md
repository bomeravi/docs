# Jenkins on Kubernetes

This example deploys Jenkins as a StatefulSet with a persistent volume for `JENKINS_HOME`.

Notes:
- Use a StorageClass suitable for your cluster; the example uses a `volumeClaimTemplates` request.
- For production, secure the instance (NetworkPolicy, TLS/Ingress, RBAC) and use an external storage provider.
- Replace images, resource requests/limits, and storage sizes as needed.

Apply:

```bash
kubectl apply -f kubernetes/manifests/jenkins/ -n jenkins
```
