# Certbot Setup

This guide covers:

-   Standard Ubuntu setup
-   NGINX reverse proxy configuration
-   DigitalOcean deployment
-   Docker-based setup
-   Kubernetes / Ingress configuration
-   High Availability (HA) multi-server architecture

------------------------------------------------------------------------

# 1️⃣ Base Requirements

-   Ubuntu 20.04 / 22.04 / 24.04
-   Domain pointing to server public IP
-   Ports 80 and 443 open

``` bash
sudo ufw allow 80
sudo ufw allow 443
```

------------------------------------------------------------------------

# 2️⃣ Install Certbot (Recommended Snap Method)

``` bash
sudo apt update && sudo apt upgrade -y
sudo apt install snapd -y
sudo snap install core
sudo snap refresh core
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
certbot --version
```

------------------------------------------------------------------------

# 3️⃣ NGINX Reverse Proxy Setup

Install NGINX:

``` bash
sudo apt install nginx -y
```

Example reverse proxy config:

``` nginx
server {
    listen 80;
    server_name example.com www.example.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

Enable config:

``` bash
sudo nginx -t
sudo systemctl reload nginx
```

Generate SSL:

``` bash
sudo certbot --nginx -d example.com -d www.example.com --redirect
```

------------------------------------------------------------------------

# 4️⃣ DigitalOcean Setup

## Droplet Requirements

-   Public IPv4 assigned
-   DNS A record pointing to droplet IP
-   Firewall allowing 80 & 443

Verify DNS:

``` bash
dig example.com +short
```

Then run:

``` bash
sudo certbot --nginx -d example.com
```

------------------------------------------------------------------------

# 5️⃣ Docker Version

Run Certbot in Docker (Standalone mode):

``` bash
docker run -it --rm   -p 80:80   -v /etc/letsencrypt:/etc/letsencrypt   certbot/certbot certonly --standalone   -d example.com
```

Renew:

``` bash
docker run --rm   -v /etc/letsencrypt:/etc/letsencrypt   certbot/certbot renew
```

------------------------------------------------------------------------

# 6️⃣ Kubernetes / Ingress Setup

Recommended: Use cert-manager

Install cert-manager:

``` bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
```

Create ClusterIssuer:

``` yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```

Ingress Example:

``` yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - example.com
    secretName: example-tls
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: example-service
            port:
              number: 80
```

------------------------------------------------------------------------

# 7️⃣ High Availability (HA) Setup

For multiple servers behind a load balancer:

Architecture:

Client → Load Balancer → Multiple NGINX Servers

## Recommended Approach

-   Use shared storage (NFS) for `/etc/letsencrypt` OR
-   Issue certificate on one server and sync via rsync OR
-   Terminate SSL at Load Balancer

Example rsync:

``` bash
rsync -avz /etc/letsencrypt user@server2:/etc/letsencrypt
```

Best Practice:

Use Load Balancer SSL termination (DigitalOcean LB supports Let's
Encrypt automatically).

------------------------------------------------------------------------

# 8️⃣ Auto Renewal

Test renewal:

``` bash
sudo certbot renew --dry-run
```

Check timer:

``` bash
sudo systemctl list-timers | grep certbot
```

------------------------------------------------------------------------

# 9️⃣ Certificate Location

    /etc/letsencrypt/live/example.com/

Files:

-   fullchain.pem
-   privkey.pem
-   cert.pem
-   chain.pem

------------------------------------------------------------------------

# 🔟 Force Renew

``` bash
sudo certbot renew --force-renewal
```

------------------------------------------------------------------------

# 1️⃣1️⃣ Delete Certificate

``` bash
sudo certbot delete --cert-name example.com
```

------------------------------------------------------------------------

# 📅 Certificate Validity

-   Valid for 90 days
-   Auto-renewed every 60 days

------------------------------------------------------------------------

# 🎯 Production Command Example

``` bash
sudo certbot --nginx   -d example.com   -d www.example.com   --redirect   --agree-tos   -m admin@example.com
```

------------------------------------------------------------------------

# 🛡 Security Recommendations

-   Enable HTTPS redirect
-   Use HSTS
-   Disable weak TLS protocols
-   Keep Ubuntu updated