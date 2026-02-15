# React App Kubernetes Example

This example serves a built React app from an image (e.g., Nginx + static build) exposed via a ClusterIP Service. Build a production image (for example using `nginx` to serve the `build/` folder) and push to your registry before applying.

Apply:

```bash
kubectl apply -f kubernetes/manifests/react/ -n web
```
