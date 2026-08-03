# kubectl Commands Reference

A practical reference of everyday `kubectl` commands: contexts, namespaces, nodes, pods,
deployments, services, ingress, config, storage, jobs, logs, debugging, RBAC, and cleanup.

> For installing `kubectl` and creating a cluster, see [Installation and Commands](./01-kubernetes-installation.md).

---

## 1. Basics and Help

### Client and server version

```bash
kubectl version --client
kubectl version
```

### Discover resources and their short names

```bash
kubectl api-resources
kubectl api-resources --namespaced=true
kubectl api-resources --namespaced=false
kubectl api-versions
```

### Built-in documentation

```bash
kubectl explain pod
kubectl explain deployment.spec.template.spec.containers
kubectl get pods --help
```

> 📌 Short names save typing: `po` (pods), `svc` (services), `deploy` (deployments),
> `rs` (replicasets), `sts` (statefulsets), `ds` (daemonsets), `ns` (namespaces),
> `cm` (configmaps), `pv`/`pvc` (volumes), `ing` (ingress), `no` (nodes).

---

## 2. Cluster Info and Contexts

### Cluster information

```bash
kubectl cluster-info
kubectl cluster-info dump
kubectl get componentstatuses
```

### List and switch contexts

```bash
kubectl config get-contexts
kubectl config current-context
kubectl config use-context <context-name>
```

### View and edit kubeconfig

```bash
kubectl config view
kubectl config view --minify
kubectl config view --raw
kubectl config rename-context <old-name> <new-name>
kubectl config delete-context <context-name>
```

### Set a default namespace for the current context

```bash
kubectl config set-context --current --namespace=demo
```

> This avoids typing `-n demo` on every command.

---

## 3. Namespaces

### List namespaces

```bash
kubectl get ns
kubectl get namespaces
kubectl get ns -o wide
kubectl get ns --show-labels
```

### Create a namespace

```bash
kubectl create namespace demo
```

Declarative (preferred for Git):

```bash
kubectl create namespace demo --dry-run=client -o yaml > manifests/namespace.yaml
kubectl apply -f manifests/namespace.yaml
```

### Inspect a namespace

```bash
kubectl describe ns demo
kubectl get ns demo -o yaml
```

### Everything inside a namespace

```bash
kubectl get all -n demo
kubectl get all --all-namespaces
kubectl get all -A
```

> ⚠️ `kubectl get all` does **not** include every resource type — secrets, configmaps,
> ingresses, PVCs and CRDs are excluded. Use the command in
> [section 18](#18-listing-everything-in-a-namespace) for a truly complete list.

### Delete a namespace

```bash
kubectl delete ns demo
```

> ⚠️ Deleting a namespace deletes **every** resource inside it. There is no undo.

---

## 4. Nodes

### List nodes

```bash
kubectl get nodes
kubectl get no -o wide
kubectl get nodes --show-labels
kubectl get nodes -l node-role.kubernetes.io/control-plane
```

### Node details and capacity

```bash
kubectl describe node <node-name>
kubectl get node <node-name> -o yaml
kubectl top node
```

### Label, taint, and schedule

```bash
kubectl label node <node-name> disktype=ssd
kubectl label node <node-name> disktype-          # remove label
kubectl taint node <node-name> key=value:NoSchedule
kubectl taint node <node-name> key-               # remove taint
```

### Drain and maintenance

```bash
kubectl cordon <node-name>                        # mark unschedulable
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
kubectl uncordon <node-name>                      # back into rotation
```

---

## 5. Pods

### List pods

```bash
kubectl get pods
kubectl get pods -n demo
kubectl get pods -A
kubectl get pods -o wide                          # includes node and pod IP
kubectl get pods --show-labels
kubectl get pods -l app=nginx
kubectl get pods --field-selector status.phase=Running
kubectl get pods --sort-by=.status.startTime
kubectl get pods --watch
```

### Inspect a pod

```bash
kubectl describe pod <pod-name> -n demo
kubectl get pod <pod-name> -n demo -o yaml
kubectl get pod <pod-name> -n demo -o jsonpath='{.spec.containers[*].image}'
```

### Run a throwaway pod

```bash
kubectl run tmp-shell --rm -it --image=busybox:1.36 --restart=Never -- sh
kubectl run curl --rm -it --image=curlimages/curl --restart=Never -- sh
kubectl run nginx --image=nginx --port=80
```

### Delete pods

```bash
kubectl delete pod <pod-name> -n demo
kubectl delete pod <pod-name> -n demo --grace-period=0 --force
kubectl delete pods -l app=nginx -n demo
kubectl delete pods --all -n demo
```

---

## 6. Deployments, ReplicaSets, StatefulSets, DaemonSets

### List workloads

```bash
kubectl get deployments -n demo
kubectl get deploy -A
kubectl get replicasets -n demo
kubectl get statefulsets -n demo
kubectl get daemonsets -A
```

### Create a deployment

```bash
kubectl create deployment nginx --image=nginx -n demo
kubectl create deployment nginx --image=nginx --replicas=3 -n demo
```

Generate the YAML instead of creating it directly:

```bash
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml > manifests/deployment.yaml
```

### Inspect

```bash
kubectl describe deployment nginx -n demo
kubectl get deploy nginx -n demo -o yaml
kubectl get rs -n demo -l app=nginx
```

### Scale

```bash
kubectl scale deployment/nginx --replicas=3 -n demo
kubectl scale deployment/nginx --replicas=0 -n demo        # stop without deleting
kubectl autoscale deployment/nginx --min=2 --max=10 --cpu-percent=80 -n demo
kubectl get hpa -n demo
```

### Update the image and roll out

```bash
kubectl set image deployment/nginx nginx=nginx:1.25 -n demo
kubectl set env deployment/nginx LOG_LEVEL=debug -n demo
kubectl set resources deployment/nginx --limits=cpu=500m,memory=512Mi -n demo
```

### Rollout control

```bash
kubectl rollout status deployment/nginx -n demo
kubectl rollout history deployment/nginx -n demo
kubectl rollout history deployment/nginx --revision=2 -n demo
kubectl rollout restart deployment/nginx -n demo
kubectl rollout undo deployment/nginx -n demo
kubectl rollout undo deployment/nginx --to-revision=2 -n demo
kubectl rollout pause deployment/nginx -n demo
kubectl rollout resume deployment/nginx -n demo
```

> `kubectl rollout restart` is the clean way to restart all pods of a deployment
> (for example, after a ConfigMap or Secret change).

---

## 7. Services

### List all services

```bash
kubectl get services
kubectl get svc -n demo
kubectl get svc -A                                # every namespace
kubectl get svc -o wide                           # includes selector
kubectl get svc --sort-by=.metadata.name -A
kubectl get svc -l app=nginx -n demo
```

### Only services of a given type

```bash
kubectl get svc -A --field-selector spec.type=LoadBalancer
kubectl get svc -A --field-selector spec.type=NodePort
```

### Service details and endpoints

```bash
kubectl describe svc nginx -n demo
kubectl get svc nginx -n demo -o yaml
kubectl get endpoints -n demo
kubectl get endpointslices -n demo
```

> If a service has **no endpoints**, its selector does not match any ready pod —
> that is the first thing to check when traffic fails.

### Expose a workload

```bash
kubectl expose deployment nginx --port=80 --type=ClusterIP -n demo
kubectl expose deployment nginx --port=80 --target-port=8080 --type=NodePort -n demo
kubectl expose deployment nginx --port=80 --type=LoadBalancer -n demo
```

### External IP of a LoadBalancer

```bash
kubectl get svc nginx -n demo -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

### Delete a service

```bash
kubectl delete svc nginx -n demo
```

---

## 8. Ingress

```bash
kubectl get ingress -n demo
kubectl get ing -A
kubectl describe ingress <ingress-name> -n demo
kubectl get ingressclass
```

Check the ingress controller itself:

```bash
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx -f
```

---

## 9. ConfigMaps and Secrets

### List and inspect

```bash
kubectl get configmaps -n demo
kubectl get cm -A
kubectl describe cm app-config -n demo
kubectl get secrets -n demo
kubectl describe secret db-credentials -n demo
```

### Create a ConfigMap

```bash
kubectl create configmap app-config --from-literal=LOG_LEVEL=info -n demo
kubectl create configmap app-config --from-file=./config/app.properties -n demo
kubectl create configmap app-config --from-env-file=./.env -n demo
```

### Create a Secret

```bash
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password='s3cr3t' -n demo

kubectl create secret docker-registry regcred \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=<user> \
  --docker-password=<token> \
  --docker-email=<email> -n demo

kubectl create secret tls my-tls --cert=tls.crt --key=tls.key -n demo
```

### Read a secret value

```bash
kubectl get secret db-credentials -n demo -o jsonpath='{.data.password}' | base64 -d
kubectl get secret db-credentials -n demo -o go-template='{{range $k,$v := .data}}{{$k}}={{$v | base64decode}}{{"\n"}}{{end}}'
```

> ⚠️ Secrets are only base64-encoded, not encrypted, in `etcd` by default. Never commit
> a rendered secret manifest to Git — use Sealed Secrets, SOPS, or an external secret store.

### Update in place

```bash
kubectl edit cm app-config -n demo
kubectl create cm app-config --from-literal=LOG_LEVEL=debug -n demo \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl rollout restart deployment/nginx -n demo     # pick up the new values
```

---

## 10. Storage: PV, PVC, StorageClass

```bash
kubectl get pv
kubectl get pvc -n demo
kubectl get pvc -A
kubectl get storageclass
kubectl get sc
kubectl describe pvc <pvc-name> -n demo
kubectl describe pv <pv-name>
```

Find which pods use a PVC:

```bash
kubectl get pods -n demo -o json | jq '.items[] | {pod: .metadata.name, pvc: .spec.volumes[]?.persistentVolumeClaim?.claimName}'
```

> ⚠️ A PVC stuck in `Terminating` usually still has a pod mounting it. Delete the pod first.

---

## 11. Jobs and CronJobs

```bash
kubectl get jobs -n demo
kubectl get cronjobs -n demo
kubectl get cj -A
kubectl describe job <job-name> -n demo
kubectl logs job/<job-name> -n demo
```

Create and control:

```bash
kubectl create job hello --image=busybox -- echo "hello"
kubectl create job manual-run --from=cronjob/nightly-backup -n demo
kubectl patch cronjob nightly-backup -n demo -p '{"spec":{"suspend":true}}'
kubectl delete job <job-name> -n demo
```

---

## 12. Logs

```bash
kubectl logs <pod-name> -n demo
kubectl logs -f <pod-name> -n demo                       # follow
kubectl logs <pod-name> -c <container-name> -n demo      # multi-container pod
kubectl logs <pod-name> --previous -n demo               # previous crashed container
kubectl logs <pod-name> --tail=100 -n demo
kubectl logs <pod-name> --since=1h -n demo
kubectl logs --timestamps <pod-name> -n demo
```

Across many pods:

```bash
kubectl logs -l app=nginx -n demo --all-containers=true --tail=50
kubectl logs deployment/nginx -n demo -f
kubectl logs job/<job-name> -n demo
```

---

## 13. Exec, Port-Forward, and Copy

### Shell into a container

```bash
kubectl exec -it <pod-name> -n demo -- /bin/bash
kubectl exec -it <pod-name> -n demo -- /bin/sh          # alpine/busybox images
kubectl exec -it <pod-name> -c <container> -n demo -- sh
kubectl exec <pod-name> -n demo -- env
kubectl exec <pod-name> -n demo -- ls -la /app
```

### Port-forward to your machine

```bash
kubectl port-forward svc/nginx 8080:80 -n demo
kubectl port-forward pod/<pod-name> 8080:80 -n demo
kubectl port-forward deployment/nginx 8080:80 -n demo
kubectl port-forward svc/nginx 8080:80 -n demo --address 0.0.0.0
```

### Copy files in and out

```bash
kubectl cp ./local-file.txt demo/<pod-name>:/tmp/local-file.txt
kubectl cp demo/<pod-name>:/var/log/app.log ./app.log
kubectl cp ./dir demo/<pod-name>:/tmp/dir -c <container>
```

### Debug a pod without a shell

```bash
kubectl debug -it <pod-name> --image=busybox:1.36 --target=<container> -n demo
kubectl debug node/<node-name> -it --image=busybox:1.36
```

---

## 14. Applying and Managing Manifests

```bash
kubectl apply -f manifests/ -n demo
kubectl apply -f deployment.yaml
kubectl apply -f https://raw.githubusercontent.com/org/repo/main/deploy.yaml
kubectl apply -k overlays/dev                            # kustomize
kubectl apply -f manifests/ --dry-run=server             # validate without applying
kubectl diff -f manifests/                               # what would change
```

Other verbs:

```bash
kubectl create -f deployment.yaml
kubectl replace -f deployment.yaml
kubectl edit deployment nginx -n demo
kubectl patch deployment nginx -n demo -p '{"spec":{"replicas":4}}'
kubectl delete -f manifests/ -n demo
```

Export a live object as a clean manifest:

```bash
kubectl get deploy nginx -n demo -o yaml > deployment.yaml
```

---

## 15. Labels, Annotations, and Selectors

```bash
kubectl label pod <pod-name> env=prod -n demo
kubectl label pod <pod-name> env=staging --overwrite -n demo
kubectl label pod <pod-name> env- -n demo                # remove
kubectl annotate deployment nginx owner=devops -n demo

kubectl get pods -l env=prod -n demo
kubectl get pods -l 'env in (prod,staging)' -n demo
kubectl get pods -l 'env!=prod' -n demo
kubectl get all -l app=nginx -n demo
```

---

## 16. Resource Usage

Requires the metrics-server to be installed.

```bash
kubectl top node
kubectl top pod -n demo
kubectl top pod -A --sort-by=memory
kubectl top pod -A --sort-by=cpu
kubectl top pod <pod-name> --containers -n demo
```

Quota and limits:

```bash
kubectl get resourcequota -n demo
kubectl describe resourcequota -n demo
kubectl get limitrange -n demo
```

---

## 17. Output Formats and JSONPath

```bash
kubectl get pods -o wide
kubectl get pods -o yaml
kubectl get pods -o json
kubectl get pods -o name
kubectl get pods -o jsonpath='{.items[*].metadata.name}'
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.podIP}{"\n"}{end}'
```

Custom columns:

```bash
kubectl get pods -o custom-columns='NAME:.metadata.name,IMAGE:.spec.containers[*].image,NODE:.spec.nodeName'
kubectl get svc -A -o custom-columns='NS:.metadata.namespace,NAME:.metadata.name,TYPE:.spec.type,CLUSTER-IP:.spec.clusterIP,PORTS:.spec.ports[*].port'
```

List every image running in the cluster:

```bash
kubectl get pods -A -o jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n' | sort -u
```

---

## 18. Listing Everything in a Namespace

`kubectl get all` misses several kinds. To list every namespaced object:

```bash
kubectl api-resources --verbs=list --namespaced -o name \
  | xargs -n 1 kubectl get --show-kind --ignore-not-found -n demo
```

Cluster-scoped objects:

```bash
kubectl api-resources --verbs=list --namespaced=false -o name \
  | xargs -n 1 kubectl get --show-kind --ignore-not-found
```

---

## 19. Events and Troubleshooting

```bash
kubectl get events -n demo
kubectl get events -n demo --sort-by=.metadata.creationTimestamp
kubectl get events -A --field-selector type=Warning
kubectl events --for pod/<pod-name> -n demo
kubectl get events -n demo -w
```

Common checks:

```bash
kubectl describe pod <pod-name> -n demo                  # image pull / scheduling errors
kubectl logs <pod-name> --previous -n demo               # why it crashed
kubectl get pods -A --field-selector status.phase=Failed
kubectl get pods -A | grep -Ev 'Running|Completed'       # anything unhealthy
kubectl get nodes -o wide                                # node NotReady?
```

DNS and connectivity from inside the cluster:

```bash
kubectl run netcheck --rm -it --image=busybox:1.36 --restart=Never -- \
  sh -c "nslookup nginx.demo.svc.cluster.local && wget -qO- http://nginx.demo"
```

> A pod stuck in `Pending` is usually unschedulable (no resources, taints, or unbound PVC) —
> `kubectl describe pod` shows the reason under **Events**.

---

## 20. RBAC and Permissions

```bash
kubectl get serviceaccounts -n demo
kubectl get roles,rolebindings -n demo
kubectl get clusterroles,clusterrolebindings
kubectl describe clusterrole cluster-admin
```

Check what you (or another identity) may do:

```bash
kubectl auth can-i create deployments -n demo
kubectl auth can-i '*' '*' --all-namespaces
kubectl auth can-i delete pods --as=system:serviceaccount:demo:builder -n demo
kubectl auth can-i --list -n demo
```

Create RBAC objects:

```bash
kubectl create serviceaccount builder -n demo
kubectl create role pod-reader --verb=get,list,watch --resource=pods -n demo
kubectl create rolebinding builder-pod-reader \
  --role=pod-reader --serviceaccount=demo:builder -n demo
```

---

## 21. Deleting and Cleaning Up

```bash
kubectl delete deployment nginx -n demo
kubectl delete svc,deploy,cm -l app=nginx -n demo
kubectl delete -f manifests/ -n demo
kubectl delete pods --field-selector status.phase=Succeeded -A
kubectl delete pods --field-selector status.phase=Failed -A
```

Force-remove a stuck object by clearing its finalizers:

```bash
kubectl patch pvc <pvc-name> -n demo -p '{"metadata":{"finalizers":null}}' --type=merge
```

> ⚠️ Removing finalizers skips cleanup logic and can leak cloud resources (disks, load
> balancers). Use it only when the controller is gone and the object is genuinely stuck.

---

## 22. Aliases and Autocompletion

Add to `~/.bashrc` (or `~/.zshrc`):

```bash
source <(kubectl completion bash)
alias k=kubectl
complete -o default -F __start_kubectl k

alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get ns'
alias kgd='kubectl get deploy'
alias kaf='kubectl apply -f'
alias kdp='kubectl describe pod'
alias kl='kubectl logs -f'
alias kx='kubectl exec -it'
```

Reload the shell:

```bash
source ~/.bashrc
```

> `kubectx` and `kubens` are worth installing for fast context/namespace switching:
> `sudo apt install -y kubectx`.

---

## Summary

| Task                     | Command                                             |
| ------------------------ | --------------------------------------------------- |
| List namespaces          | `kubectl get ns`                                     |
| List all services        | `kubectl get svc -A`                                 |
| List pods with node/IP   | `kubectl get pods -o wide -A`                        |
| Everything in namespace  | `kubectl get all -n demo`                            |
| Apply manifests          | `kubectl apply -f manifests/ -n demo`                |
| Follow logs              | `kubectl logs -f deployment/nginx -n demo`           |
| Shell into a pod         | `kubectl exec -it <pod> -n demo -- /bin/bash`        |
| Port-forward             | `kubectl port-forward svc/nginx 8080:80 -n demo`     |
| Scale                    | `kubectl scale deploy/nginx --replicas=3 -n demo`    |
| Restart pods             | `kubectl rollout restart deploy/nginx -n demo`       |
| Roll back                | `kubectl rollout undo deploy/nginx -n demo`          |
| Recent warnings          | `kubectl get events -A --field-selector type=Warning`|
| Resource usage           | `kubectl top pod -A --sort-by=memory`                |
| Default namespace        | `kubectl config set-context --current --namespace=demo` |
