# OWASP Dependency Check

OWASP Dependency Check scans project dependencies for known CVEs (Common
Vulnerabilities and Exposures) using the NVD database. It integrates with
Jenkins via the **OWASP Dependency-Check** plugin, so a build can fail when a
vulnerable library is pulled in.

> Requires a working Jenkins controller — see
> [Jenkins Server Setup](../jenkins/server-setup.md).

---

## 1. Install the plugin

1. **Manage Jenkins → Plugins → Available plugins**
2. Search for `OWASP Dependency-Check`
3. Install and restart Jenkins.

---

## 2. Configure the tool

1. **Manage Jenkins → Tools → Dependency-Check installations**
2. Click **Add Dependency-Check**
3. Set **Name** to `OWASP-DC` — this is the name referenced in the Jenkinsfile.
4. Choose **Install automatically**, or point to a local install path.

---

## 3. Basic Jenkinsfile usage

```groovy
pipeline {
    agent any
    tools {
        dependencyCheck 'OWASP-DC'
    }
    stages {
        stage('Dependency Check') {
            steps {
                dependencyCheck(
                    additionalArguments: '--scan ./ --format HTML --format XML',
                    odcInstallation: 'OWASP-DC'
                )
            }
        }
    }
    post {
        always {
            dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
        }
    }
}
```

---

## Run on a Specific Agent

Pin the scan to a dedicated agent so a long NVD update doesn't block the
controller — see [Jenkins Agents](../jenkins/agents.md).

```groovy
pipeline {
    agent { label 'linux' }
    tools {
        dependencyCheck 'OWASP-DC'
    }
    stages {
        stage('Build') {
            steps {
                sh 'mvn package -DskipTests'
            }
        }
        stage('OWASP Scan') {
            steps {
                dependencyCheck(
                    additionalArguments: '''
                        --scan ./
                        --format HTML
                        --format XML
                        --disableYarnAudit
                        --disableNodeAudit
                    ''',
                    odcInstallation: 'OWASP-DC'
                )
            }
        }
    }
    post {
        always {
            dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
        }
    }
}
```

---

## Docker Agent with OWASP Scan

Use a Docker agent to keep the scan environment isolated.

```groovy
pipeline {
    agent {
        docker {
            image 'owasp/dependency-check:latest'
            args '--entrypoint='
        }
    }
    stages {
        stage('Scan') {
            steps {
                sh '''
                    /usr/share/dependency-check/bin/dependency-check.sh \
                      --project "MyApp" \
                      --scan /workspace \
                      --format HTML \
                      --format XML \
                      --out /workspace/reports
                '''
            }
        }
    }
    post {
        always {
            publishHTML(target: [
                allowMissing: false,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'reports',
                reportFiles: 'dependency-check-report.html',
                reportName: 'OWASP Dependency Check'
            ])
        }
    }
}
```

---

## Kubernetes Agent with OWASP Scan

```groovy
pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: owasp
    image: owasp/dependency-check:latest
    command:
    - sleep
    args:
    - infinity
  - name: maven
    image: maven:3.9-eclipse-temurin-21
    command:
    - sleep
    args:
    - infinity
'''
        }
    }
    stages {
        stage('Build') {
            steps {
                container('maven') {
                    sh 'mvn package -DskipTests'
                }
            }
        }
        stage('OWASP Scan') {
            steps {
                container('owasp') {
                    sh '''
                        /usr/share/dependency-check/bin/dependency-check.sh \
                          --project "MyApp" \
                          --scan /home/jenkins/agent/workspace \
                          --format XML \
                          --format HTML \
                          --out reports/
                    '''
                }
            }
        }
    }
    post {
        always {
            dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
        }
    }
}
```

---

## Fail the Build on High Severity

```groovy
post {
    always {
        dependencyCheckPublisher(
            pattern: '**/dependency-check-report.xml',
            failedTotalCritical: 1,   // fail if any CRITICAL
            failedTotalHigh: 5,       // fail if 5+ HIGH
            unstableTotalMedium: 10   // unstable if 10+ MEDIUM
        )
    }
}
```

---

## NVD API Key (Recommended)

Without an API key, the NVD rate-limits downloads and the vulnerability
database update is very slow.

1. Register at <https://nvd.nist.gov/developers/request-an-api-key>
2. Add it as a Jenkins secret:
   - **Manage Jenkins → Credentials → Add → Secret text**
   - ID: `NVD_API_KEY`
3. Use it in the pipeline:

```groovy
withCredentials([string(credentialsId: 'NVD_API_KEY', variable: 'NVD_KEY')]) {
    dependencyCheck(
        additionalArguments: "--nvdApiKey ${NVD_KEY} --scan ./",
        odcInstallation: 'OWASP-DC'
    )
}
```

> Bind the key through `withCredentials` as shown — never hard-code it into the
> Jenkinsfile. See [Jenkins Secrets](../jenkins/secrets.md) for credential
> handling.

---

## Common Flags

| Flag | Description |
| ---- | ----------- |
| `--scan <path>` | Directory or file to scan |
| `--format HTML\|XML\|JSON\|CSV` | Output format (can be repeated) |
| `--out <dir>` | Output directory |
| `--project <name>` | Project name shown in the report |
| `--nvdApiKey <key>` | NVD API key for faster database updates |
| `--disableYarnAudit` | Skip the Yarn audit analyzer |
| `--disableNodeAudit` | Skip the npm/Node audit analyzer |
| `--failOnCVSS <score>` | Fail if any CVE scores at or above this CVSS value (0–10) |
| `--suppression <file>` | XML file used to suppress false positives |

---

## Suppression File (False Positives)

Create `dependency-check-suppressions.xml` in the repository root:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<suppressions xmlns="https://jeremylong.github.io/DependencyCheck/dependency-suppression.1.3.xsd">
    <suppress>
        <notes>False positive — internal tool, not exposed</notes>
        <packageUrl regex="true">^pkg:maven/com\.example/internal\-lib@.*$</packageUrl>
        <cve>CVE-2023-12345</cve>
    </suppress>
</suppressions>
```

Reference it from the pipeline:

```groovy
additionalArguments: '--scan ./ --suppression dependency-check-suppressions.xml'
```

> ⚠️ A suppression silences a real finding. Scope each `<suppress>` to a
> specific CVE and package — never suppress broadly — and record the
> justification in `<notes>` so the decision can be reviewed later.

---

## Summary

| Step | Where |
| ---- | ----- |
| Install the plugin | Manage Jenkins → Plugins → `OWASP Dependency-Check` |
| Register the tool | Manage Jenkins → Tools → name it `OWASP-DC` |
| Add the NVD key | Manage Jenkins → Credentials → Secret text `NVD_API_KEY` |
| Scan in a pipeline | `dependencyCheck(odcInstallation: 'OWASP-DC', …)` |
| Publish the report | `dependencyCheckPublisher pattern: '**/dependency-check-report.xml'` |
| Gate the build | `failedTotalCritical` / `failedTotalHigh` / `--failOnCVSS` |

---

## Related

- [Jenkins Agents](../jenkins/agents.md) — run scans on dedicated agents or in
  Docker/Kubernetes pods.
- [SonarQube](./sonarqube.md) — code quality and security gates in the same
  pipeline.
- [Jenkins Secrets](../jenkins/secrets.md) — store the NVD API key and other
  credentials securely.
- [Jenkins Server Setup](../jenkins/server-setup.md) — controller
  prerequisites.
