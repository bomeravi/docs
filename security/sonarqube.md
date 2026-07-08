# SonarQube

SonarQube is a self-hosted platform for continuous inspection of code quality
and security. This guide runs a SonarQube server, creates a project and token,
installs the scanner, wires SonarQube into Jenkins, and enforces a **Quality
Gate** that can fail a pipeline.

> **Prerequisites:** a Linux host with Docker + Docker Compose, and a working
> Jenkins instance (see [Jenkins Overview](/jenkins/readme.md)). SonarQube
> Community Edition is free and covers everything below.

---

## 1. How SonarQube fits in

```text
Source code ──> Jenkins pipeline ──> SonarScanner ──> SonarQube server
                                                            │
                                                     Quality Gate
                                                            │
                                              pass ✅  /  fail ❌ (breaks build)
```

1. Jenkins checks out the code and runs the **SonarScanner**.
2. The scanner uploads analysis (bugs, code smells, coverage, duplications) to
   the SonarQube server.
3. SonarQube evaluates the results against the project's **Quality Gate**.
4. The pipeline waits for the gate result and fails the build if it does not pass.

---

## 2. Run the SonarQube server

You can run the server two ways — **pick one**. Docker Compose (Option A) is the
fastest path and keeps SonarQube, its JVM, and PostgreSQL self-contained. A
bare-metal install (Option B) runs SonarQube directly on the host under systemd,
which suits environments where Docker is unavailable or tighter host control is
preferred.

### Option A — Docker Compose (recommended)

SonarQube embeds Elasticsearch, which needs a raised `vm.max_map_count`. Set it
first (persisted across reboots):

```bash
sudo sysctl -w vm.max_map_count=262144
echo 'vm.max_map_count=262144' | sudo tee /etc/sysctl.d/99-sonarqube.conf
```

Create `docker-compose.yml`:

```yaml
services:
  sonarqube:
    image: sonarqube:community
    container_name: sonarqube
    depends_on:
      - db
    ports:
      - "9000:9000"
    environment:
      SONAR_JDBC_URL: jdbc:postgresql://db:5432/sonarqube
      SONAR_JDBC_USERNAME: sonar
      SONAR_JDBC_PASSWORD: sonar
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_extensions:/opt/sonarqube/extensions
      - sonarqube_logs:/opt/sonarqube/logs
    restart: unless-stopped

  db:
    image: postgres:16
    container_name: sonarqube-db
    environment:
      POSTGRES_USER: sonar
      POSTGRES_PASSWORD: sonar
      POSTGRES_DB: sonarqube
    volumes:
      - postgresql_data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  sonarqube_data:
  sonarqube_extensions:
  sonarqube_logs:
  postgresql_data:
```

Start it and confirm it is up:

```bash
docker compose up -d
docker compose ps
```

### Option B — Bare-metal install (systemd + PostgreSQL)

Run SonarQube directly on an Ubuntu/Debian host. SonarQube runs as its own
unprivileged user and **must not run as root**.

**1. Install Java 21 and tools.** SonarQube requires Java 21.

```bash
sudo apt update
sudo apt install -y openjdk-21-jdk unzip wget curl
java -version
```

**2. Install PostgreSQL** and create the database and user (these must match the
JDBC settings in step 5):

```bash
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable --now postgresql

sudo -u postgres psql <<'SQL'
CREATE USER sonar WITH ENCRYPTED PASSWORD 'sonar';
CREATE DATABASE sonarqube OWNER sonar;
GRANT ALL PRIVILEGES ON DATABASE sonarqube TO sonar;
SQL
```

**3. Raise kernel and file-descriptor limits.** The embedded Elasticsearch needs
a higher `vm.max_map_count` and open-file limits:

```bash
# Kernel limits (persisted across reboots)
sudo tee /etc/sysctl.d/99-sonarqube.conf >/dev/null <<'EOF'
vm.max_map_count=262144
fs.file-max=131072
EOF
sudo sysctl --system

# Per-user limits for the sonarqube account
sudo tee /etc/security/limits.d/99-sonarqube.conf >/dev/null <<'EOF'
sonarqube   -   nofile   131072
sonarqube   -   nproc    8192
EOF
```

**4. Create the user and install the server.** Check the
[downloads page](https://www.sonarsource.com/products/sonarqube/downloads/) for
the current version and adjust the URL accordingly:

```bash
sudo useradd --system --shell /bin/bash --home /opt/sonarqube sonarqube

cd /tmp
curl -LO https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-25.1.0.102122.zip
sudo unzip sonarqube-25.1.0.102122.zip -d /opt
sudo mv /opt/sonarqube-25.1.0.102122 /opt/sonarqube
sudo chown -R sonarqube:sonarqube /opt/sonarqube
```

**5. Point SonarQube at PostgreSQL.** Edit `/opt/sonarqube/conf/sonar.properties`
and set:

```properties
sonar.jdbc.username=sonar
sonar.jdbc.password=sonar
sonar.jdbc.url=jdbc:postgresql://localhost:5432/sonarqube

sonar.web.port=9000
```

**6. Create a systemd service** at `/etc/systemd/system/sonarqube.service`:

```ini
[Unit]
Description=SonarQube service
After=syslog.target network.target postgresql.service

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sonarqube
Group=sonarqube
Restart=on-failure
LimitNOFILE=131072
LimitNPROC=8192
TimeoutStartSec=5min

[Install]
WantedBy=multi-user.target
```

Enable, start, and follow the log until it reports `SonarQube is operational`:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now sonarqube
sudo tail -f /opt/sonarqube/logs/sonar.log
```

---

Whichever option you chose, the server now listens on port `9000`.

> ⚠️ Do not use the default `sonar/sonar` database password in production. Also
> put SonarQube behind HTTPS with a reverse proxy — the Apache pattern in
> [Certbot](/security/certbot.md) and the [Mailpit](/developer-tools/mailpit.md) reverse
> proxy examples apply directly (proxy to `http://127.0.0.1:9000`).

The UI is now available at `http://localhost:9000` (or the server's domain,
e.g. `http://sonarqube.sajiloapps.com`).

---

## 3. First login and create a project

1. Open `http://localhost:9000` and log in with `admin` / `admin`.
2. SonarQube forces a new admin password on first login — set it now.
3. Go to **Projects → Create Project → Local project**.
4. Enter a **Project key** (e.g. `my-app`) and display name, then choose
   **Use the global setting** for the New Code definition.
5. On the analysis method screen, choose **Locally** (for a token) or **Jenkins**
   — either path leads to token generation next.
6. Under **Account → Security → Generate Tokens**, create a token (type
   *Global Analysis Token* or *Project Analysis Token*) and **copy it now** — it
   is shown only once.

> Store this token in Jenkins credentials (next section). Never commit it to Git.

---

## 4. Install SonarScanner (for local / manual runs)

Jenkins can auto-install the scanner (see §5), but for local runs install the CLI.

**Ubuntu / Debian:**

```bash
curl -LO https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-6.2.1.4610-linux-x64.zip
sudo unzip sonar-scanner-cli-6.2.1.4610-linux-x64.zip -d /opt
sudo ln -s /opt/sonar-scanner-6.2.1.4610-linux-x64/bin/sonar-scanner /usr/local/bin/sonar-scanner
sonar-scanner --version
```

Add a `sonar-project.properties` file to the repository root:

```ini
sonar.projectKey=my-app
sonar.projectName=My App
sonar.sources=src
sonar.tests=tests
sonar.sourceEncoding=UTF-8
# Language-specific coverage import, e.g.:
# sonar.python.coverage.reportPaths=coverage.xml
# sonar.javascript.lcov.reportPaths=coverage/lcov.info
```

Run an analysis manually:

```bash
sonar-scanner \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=YOUR_TOKEN
```

---

## 5. Configure SonarQube in Jenkins

Do this once per Jenkins controller.

### 5.1 Install the plugin

**Manage Jenkins → Plugins → Available** → install **SonarQube Scanner** →
restart Jenkins.

### 5.2 Add the token as a credential

**Manage Jenkins → Credentials → (global) → Add Credentials**:

- **Kind:** `Secret text`
- **Secret:** the token from §3
- **ID:** `sonarqube-token`

### 5.3 Register the SonarQube server

**Manage Jenkins → System → SonarQube servers → Add SonarQube**:

- **Name:** `SonarQube` *(this name is referenced in the pipeline)*
- **Server URL:** `http://sonarqube.sajiloapps.com` (or `http://localhost:9000`)
- **Server authentication token:** select `sonarqube-token`

### 5.4 Register the scanner tool

**Manage Jenkins → Tools → SonarQube Scanner installations → Add**:

- **Name:** `SonarScanner` *(referenced via `tool 'SonarScanner'`)*
- Tick **Install automatically** (pick the latest version).

### 5.5 Enable the Quality Gate webhook

For `waitForQualityGate()` to return, SonarQube must call back to Jenkins. In
**SonarQube → Administration → Configuration → Webhooks → Create**:

- **Name:** `Jenkins`
- **URL:** `http://<jenkins-host>/sonarqube-webhook/`

---

## 6. Use SonarQube in a Jenkins pipeline

Add an analysis stage plus a Quality Gate gate. The `withSonarQubeEnv` name must
match §5.3, and `tool` must match §5.4:

```groovy
pipeline {
  agent any
  stages {
    stage('Checkout') { steps { checkout scm } }

    stage('SonarQube Analysis') {
      steps {
        script {
          def scannerHome = tool 'SonarScanner'
          withSonarQubeEnv('SonarQube') {
            sh "${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=my-app"
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

> `waitForQualityGate abortPipeline: true` fails the build when the gate does not
> pass — this is the whole point of the integration. It depends on the webhook
> from §5.5.

A full, copy-ready template lives at
[Jenkinsfile SonarQube](/jenkins/jenkinsfiles/Jenkinsfile-sonarqube.md).

---

## 7. Verify

```bash
# Server health
curl http://localhost:9000/api/system/status
```

Expected:

```text
{"id":"...","version":"...","status":"UP"}
```

Then run the Jenkins job — the build log should show
`ANALYSIS SUCCESSFUL`, and the project page in SonarQube shows the latest
analysis with a **Passed** or **Failed** Quality Gate badge.

---

## Summary

| Step             | Action                                                        |
| ---------------- | ------------------------------------------------------------- |
| Server           | Docker Compose *or* bare-metal systemd install (port `9000`)  |
| Project & token  | Create project, generate token in **Account → Security**      |
| Scanner (local)  | Install `sonar-scanner`, add `sonar-project.properties`       |
| Jenkins plugin   | Install **SonarQube Scanner**                                 |
| Jenkins config   | Add server `SonarQube` + tool `SonarScanner` + token cred     |
| Webhook          | SonarQube → `http://<jenkins>/sonarqube-webhook/`             |
| Pipeline         | `withSonarQubeEnv` + `waitForQualityGate abortPipeline: true` |

---

## Done ✅

The result is a running SonarQube server, a project with an analysis token,
Jenkins wired to SonarQube, and a pipeline that scans code and fails the build
when the Quality Gate does not pass.
