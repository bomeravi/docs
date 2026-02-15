**Jenkins**

This document shows how to install Jenkins on Windows, Ubuntu/Linux, and macOS, plus example `Jenkinsfile` templates, shared library guidance, and secrets handling.

**Installation (Ubuntu / Debian)**

- Install Java (recommended OpenJDK 21):

```bash
sudo apt update
sudo apt install fontconfig openjdk-21-jre
```

- Add Jenkins repository and install:

```bash
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install jenkins
```

- Initial admin password:

```
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

**Installation (Windows)**

- Download the Windows installer from https://www.jenkins.io/download/
- Install using the MSI; the installer will set up Jenkins as a Windows service. Ensure Java (JDK/JRE) is installed and JAVA_HOME is set.
- Open http://localhost:8080 and use the initial admin password from `%ProgramData%/Jenkins/secrets/initialAdminPassword`.

**Installation (macOS)**

- Install Java (OpenJDK 11) and Jenkins LTS via Homebrew:

```bash
brew install openjdk@11
brew install jenkins-lts
brew services start jenkins-lts
```

- Open http://localhost:8080 and follow the web setup.

**Notes**
- Ensure the Jenkins host has required ports open (default 8080).
- Use a dedicated service user for Jenkins where possible.
- For production, configure HTTPS (Apache/Nginx reverse proxy or built-in support with TLS) and set up backups.

**Jenkinsfiles & Templates**

See `jenkins/jenkinsfiles/` for pipeline templates for common stacks (PHP, Laravel, WordPress, React, Java, Go, Python, Django). Copy a template to your repo as `Jenkinsfile` and adapt variables (registry, credentials, build commands).

**Shared Library & Utilities**

See `jenkins/shared-library/README.md` for recommended layout and examples of custom steps, and `jenkins/secrets.md` for handling credentials.

**Docker & CI**

This repo contains a `docker/` folder with Dockerfile templates and a `docker-compose.yml` sample to help you build images locally and integrate with Jenkins. See `docker/readme.md`.
