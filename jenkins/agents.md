# Jenkins Agents

Jenkins agents (formerly "slaves") offload build work from the controller node.
Use agents to parallelize builds, isolate environments, or target specific
hardware and operating systems.

---

## Agent Types

| Type | Use Case |
| ---- | -------- |
| SSH / Permanent | Long-lived Linux/Windows VMs or bare metal |
| Docker | Ephemeral containers, one per build |
| Kubernetes | Auto-scaled pods in a cluster |
| JNLP (Java Web Start) | Agents behind NAT or a firewall |

---

## 1. SSH Permanent Agent

### Prerequisites

- Java installed on the agent machine.
- The Jenkins controller can reach the agent over SSH.

### Add the node via the UI

1. **Manage Jenkins → Nodes → New Node**
2. Set a name, choose **Permanent Agent**, and click **Create**.
3. Fill in:
   - **Remote root directory**: `/home/jenkins` (or any writable path)
   - **Labels**: e.g. `linux`, `build-server`
   - **Launch method**: Launch agents via SSH
   - **Host**: agent IP or hostname
   - **Credentials**: SSH username and private key, added via the credentials store
4. Click **Save**. Jenkins connects and shows the agent online.

### Prepare the agent host

```bash
# Create the jenkins user on the agent
sudo useradd -m -s /bin/bash jenkins

# Add the Jenkins controller's public key
sudo mkdir -p /home/jenkins/.ssh
sudo nano /home/jenkins/.ssh/authorized_keys
# Paste the controller's public key

sudo chown -R jenkins:jenkins /home/jenkins/.ssh
sudo chmod 700 /home/jenkins/.ssh
sudo chmod 600 /home/jenkins/.ssh/authorized_keys
```

> The `700`/`600` permissions are required — SSH silently refuses to use an
> `authorized_keys` file that is group- or world-writable.

### Use it in a Jenkinsfile

```groovy
pipeline {
    agent { label 'linux' }
    stages {
        stage('Build') {
            steps {
                sh 'make build'
            }
        }
    }
}
```

---

## 2. Docker Agent

Requires the **Docker Pipeline** plugin, and Docker installed on the Jenkins
host or on a Docker-capable agent.

```groovy
pipeline {
    agent {
        docker {
            image 'node:20-alpine'
            args '-v /tmp:/tmp'
        }
    }
    stages {
        stage('Install') {
            steps {
                sh 'npm ci'
            }
        }
        stage('Test') {
            steps {
                sh 'npm test'
            }
        }
    }
}
```

### Per-stage Docker agent

Use `agent none` at the top level so each stage picks its own image.

```groovy
pipeline {
    agent none
    stages {
        stage('Build') {
            agent { docker { image 'maven:3.9-eclipse-temurin-21' } }
            steps {
                sh 'mvn package -DskipTests'
            }
        }
        stage('Test') {
            agent { docker { image 'maven:3.9-eclipse-temurin-21' } }
            steps {
                sh 'mvn test'
            }
        }
    }
}
```

> Each stage gets a fresh container, so nothing is carried between them
> implicitly. Use `stash`/`unstash` to pass build output from one stage to the
> next.

---

## 3. Kubernetes Agent

Requires the **Kubernetes** plugin. Jenkins runs one pod per build and destroys
it when the build finishes.

### Plugin setup

1. **Manage Jenkins → Clouds → New cloud → Kubernetes**
2. Set **Kubernetes URL** (leave blank if Jenkins runs inside the cluster).
3. Set **Jenkins URL** — the controller address reachable from pods:
   `http://jenkins:8080`
4. Set **Jenkins tunnel**: `jenkins-agent:50000`

### Jenkinsfile with a pod template

```groovy
pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: maven
    image: maven:3.9-eclipse-temurin-21
    command:
    - sleep
    args:
    - infinity
  - name: docker
    image: docker:24-dind
    securityContext:
      privileged: true
'''
            defaultContainer 'maven'
        }
    }
    stages {
        stage('Build') {
            steps {
                sh 'mvn package'
            }
        }
        stage('Docker Build') {
            steps {
                container('docker') {
                    sh 'docker build -t myapp:latest .'
                }
            }
        }
    }
}
```

> ⚠️ `privileged: true` on the `dind` container grants effectively full access
> to the host node. Restrict which pipelines can use this pod template, or
> switch to a rootless builder such as Kaniko or Buildah.

---

## Labels and Agent Selection

```groovy
// Run on any agent carrying the 'linux' label
agent { label 'linux' }

// Run only on an agent carrying both labels
agent { label 'linux && docker' }

// Run on the controller (not recommended for production)
agent { label 'built-in' }
```

---

## Security Notes

- ⚠️ Never run builds on the controller in production — a build would execute
  with access to Jenkins' own configuration and credentials. Use dedicated
  agents.
- Restrict agent permissions: agents should not have write access to the
  Jenkins config.
- Keep SSH keys in the credentials store, not in the Jenkinsfile — see
  [Secrets](./secrets.md).
- For dependency scanning inside agent builds, see
  [OWASP Dependency Check](../security/owasp-dependency-check.md).

---

## Summary

| Agent type | Declaration |
| ---------- | ----------- |
| Permanent (SSH) | `agent { label 'linux' }` |
| Docker | `agent { docker { image 'node:20-alpine' } }` |
| Per-stage Docker | `agent none` + per-stage `agent { docker { … } }` |
| Kubernetes | `agent { kubernetes { yaml '''…''' } }` |
| Combined labels | `agent { label 'linux && docker' }` |

---

## Related

- [Secrets](./secrets.md) — credential handling in pipelines.
- [OWASP Dependency Check](../security/owasp-dependency-check.md) — security
  scanning in agent pipelines.
- [Server Setup](./server-setup.md) — Jenkins controller setup.
