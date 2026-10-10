# Load Testing

A comprehensive guide for load testing web applications and APIs — installing
and running the common tools, what to monitor, and how to wire load tests into
CI/CD.

> ⚠️ **Golden rule:** never load test production without permission and
> safeguards. Run tests against a staging environment you own.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Apache JMeter](#apache-jmeter)
- [k6](#k6)
- [Locust](#locust)
- [Artillery](#artillery)
- [wrk / wrk2](#wrk-wrk2)
- [ab (ApacheBench)](#ab-apachebench)
- [Vegeta](#vegeta)
- [Hey](#hey)
- [Siege](#siege)
- [Gatling](#gatling)
- [Best Practices](#best-practices)
- [Metrics to Monitor](#metrics-to-monitor)
- [CI/CD Integration](#cicd-integration)
- [Tool Comparison](#tool-comparison)
- [Quick Reference Cheat Sheet](#quick-reference-cheat-sheet)
- [Additional Resources](#additional-resources)

---

## Prerequisites

- Basic understanding of HTTP, APIs, and system resources
- Access to the target environment (staging recommended)
- Monitoring tools (Grafana, Prometheus, Datadog, etc.)
- A test plan defining goals (RPS, concurrent users, response time SLAs)

---

## Apache JMeter

### Installation

```bash
# macOS
brew install jmeter

# Linux (Debian/Ubuntu)
sudo apt update
sudo apt install jmeter

# Manual
wget https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-5.6.3.tgz
tar -xzf apache-jmeter-5.6.3.tgz
export PATH=$PATH:$(pwd)/apache-jmeter-5.6.3/bin

# Windows (choco)
choco install jmeter
```

### Basic Commands

```bash
# GUI mode (for test creation only)
jmeter

# Non-GUI mode (for actual load testing)
jmeter -n -t test-plan.jmx -l results.jtl -e -o ./report

# With custom properties
jmeter -n -t test-plan.jmx -l results.jtl -Jusers=100 -Jrampup=60 -Jduration=300

# Distributed testing
jmeter -n -t test-plan.jmx -R server1,server2,server3 -l results.jtl

# Generate HTML report from existing results
jmeter -g results.jtl -o ./html-report
```

### Flags Reference

| Flag | Description                          |
| ---- | ------------------------------------ |
| `-n` | Non-GUI mode                         |
| `-t` | Test plan file (`.jmx`)              |
| `-l` | Results log file (`.jtl`)            |
| `-e` | Generate report after test           |
| `-o` | Output folder for report             |
| `-J` | JMeter property                      |
| `-G` | Global property (distributed)        |
| `-R` | Remote servers                       |
| `-g` | Generate report from existing `.jtl` |

---

## k6

### Installation

```bash
# macOS
brew install k6

# Linux
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg \
  --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" \
  | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt update && sudo apt install k6

# Docker
docker pull grafana/k6

# Windows
choco install k6
```

### Sample Test Script (`load-test.js`)

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 50 },   // ramp up
    { duration: '2m',  target: 50 },   // steady load
    { duration: '30s', target: 0  },   // ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],   // 95% under 500ms
    http_req_failed:   ['rate<0.01'],   // <1% errors
  },
};

export default function () {
  const res = http.get('https://api.example.com/users');
  check(res, {
    'status is 200': (r) => r.status === 200,
    'body is not empty': (r) => r.body.length > 0,
  });
  sleep(1);
}
```

### Commands

```bash
# Basic run
k6 run load-test.js

# With virtual users and duration
k6 run --vus 100 --duration 5m load-test.js

# With environment variables
k6 run -e BASE_URL=https://staging.example.com load-test.js

# Output to InfluxDB
k6 run --out influxdb=http://localhost:8086/k6 load-test.js

# Output to Prometheus (remote write)
K6_PROMETHEUS_RW_SERVER_URL=http://localhost:9090/api/v1/write \
  k6 run -o experimental-prometheus-rw load-test.js

# JSON output
k6 run --out json=results.json load-test.js

# Summary export
k6 run --summary-export=summary.json load-test.js

# Cloud run
k6 cloud load-test.js

# With Docker
docker run --rm -i grafana/k6 run - < load-test.js
```

### Common k6 Scenarios

Constant arrival rate:

```javascript
export const options = {
  scenarios: {
    constant_request_rate: {
      executor: 'constant-arrival-rate',
      rate: 1000,
      timeUnit: '1s',
      duration: '5m',
      preAllocatedVUs: 100,
      maxVUs: 500,
    },
  },
};
```

Ramping arrival rate:

```javascript
export const options = {
  scenarios: {
    ramping: {
      executor: 'ramping-arrival-rate',
      startRate: 10,
      timeUnit: '1s',
      stages: [
        { target: 100, duration: '2m' },
        { target: 100, duration: '5m' },
        { target: 0,   duration: '1m' },
      ],
      preAllocatedVUs: 50,
      maxVUs: 200,
    },
  },
};
```

---

## Locust

### Installation

```bash
pip install locust
# or
pipx install locust
```

### Sample Test (`locustfile.py`)

```python
from locust import HttpUser, task, between

class WebsiteUser(HttpUser):
    wait_time = between(1, 3)
    host = "https://api.example.com"

    @task(3)
    def get_users(self):
        self.client.get("/users")

    @task(1)
    def create_user(self):
        self.client.post("/users", json={"name": "test", "email": "test@example.com"})

    def on_start(self):
        self.client.post("/login", json={"username": "user", "password": "pass"})
```

### Commands

```bash
# Web UI mode (default port 8089)
locust -f locustfile.py

# Headless mode
locust -f locustfile.py --headless -u 100 -r 10 -t 5m --host https://api.example.com

# With HTML report
locust -f locustfile.py --headless -u 100 -r 10 -t 5m --html report.html

# CSV output
locust -f locustfile.py --headless -u 100 -r 10 -t 5m --csv results

# Distributed mode - master
locust -f locustfile.py --master --expect-workers 4

# Distributed mode - worker
locust -f locustfile.py --worker --master-host=127.0.0.1

# Specify tags
locust -f locustfile.py --tags smoke

# Exclude tags
locust -f locustfile.py --exclude-tags heavy
```

### Flags Reference

| Flag         | Description            |
| ------------ | ---------------------- |
| `-f`         | Locustfile path        |
| `-u`         | Number of users        |
| `-r`         | Spawn rate (users/sec) |
| `-t`         | Run time               |
| `--headless` | No web UI              |
| `--host`     | Target host            |
| `--html`     | HTML report path       |
| `--csv`      | CSV output prefix      |
| `--master`   | Master node            |
| `--worker`   | Worker node            |

---

## Artillery

### Installation

```bash
npm install -g artillery
# or
npx artillery
```

### Sample Test (`load-test.yml`)

```yaml
config:
  target: "https://api.example.com"
  phases:
    - duration: 60
      arrivalRate: 10
      name: "Warm up"
    - duration: 120
      arrivalRate: 50
      name: "Sustained load"
    - duration: 60
      arrivalRate: 100
      name: "Peak load"
  defaults:
    headers:
      Content-Type: "application/json"

scenarios:
  - name: "Get users"
    flow:
      - get:
          url: "/users"
          expect:
            - statusCode: 200
      - think: 1
      - post:
          url: "/users"
          json:
            name: "test"
            email: "test@example.com"
```

### Commands

```bash
# Run test
artillery run load-test.yml

# With report
artillery run --output report.json load-test.yml
artillery report report.json

# Quick test (no config file)
artillery quick --count 100 --num 10 https://api.example.com

# With environment variables
artillery run -v '{"target": "https://staging.example.com"}' load-test.yml
```

---

## wrk / wrk2

### Installation

```bash
# macOS
brew install wrk
brew install wrk2  # for wrk2

# Linux (build from source)
git clone https://github.com/wg/wrk.git
cd wrk && make && sudo cp wrk /usr/local/bin/
```

### Commands

```bash
# Basic test
wrk -t12 -c400 -d30s http://example.com

# With custom script
wrk -t12 -c400 -d30s -s script.lua http://example.com

# With headers
wrk -t4 -c100 -d30s -H "Authorization: Bearer token" http://api.example.com

# POST request
wrk -t4 -c100 -d30s -s post.lua http://api.example.com

# Latency report with wrk2
wrk2 -t4 -c100 -d30s -R2000 --latency http://example.com
```

### Flags

| Flag        | Description                 |
| ----------- | --------------------------- |
| `-t`        | Threads                     |
| `-c`        | Connections                 |
| `-d`        | Duration                    |
| `-s`        | Lua script                  |
| `-H`        | Header                      |
| `-R`        | Requests per second (wrk2)  |
| `--latency` | Print latency stats         |

### POST Script (`post.lua`)

```lua
wrk.method = "POST"
wrk.body   = '{"name":"test"}'
wrk.headers["Content-Type"] = "application/json"
```

---

## ab (ApacheBench)

### Installation

```bash
# macOS (pre-installed) or
brew install httpd

# Linux
sudo apt install apache2-utils
```

### Commands

```bash
# Basic test
ab -n 1000 -c 100 http://example.com/

# With keep-alive
ab -n 10000 -c 100 -k http://example.com/

# POST with data
ab -n 1000 -c 50 -p data.json -T application/json http://api.example.com/users

# With headers
ab -n 1000 -c 50 -H "Authorization: Bearer token" http://api.example.com/

# Save results
ab -n 1000 -c 100 -g results.tsv http://example.com/
```

### Flags

| Flag | Description         |
| ---- | ------------------- |
| `-n` | Total requests      |
| `-c` | Concurrent requests |
| `-k` | Keep-alive          |
| `-p` | POST file           |
| `-T` | Content-Type        |
| `-H` | Header              |
| `-g` | gnuplot output      |

---

## Vegeta

### Installation

```bash
# macOS
brew install vegeta

# Linux
go install github.com/tsenart/vegeta@latest

# Docker
docker pull tsenart/vegeta
```

### Commands

```bash
# Basic run
echo "GET http://example.com/" | vegeta attack -duration=30s -rate=100 | vegeta report

# With target file
vegeta attack -targets=targets.txt -duration=1m -rate=500 -output=results.bin
vegeta report results.bin

# Plot results
vegeta plot results.bin > plot.html

# Encode to JSON
vegeta report -type=json results.bin > metrics.json

# HTTP/2
echo "GET http://example.com/" | vegeta attack -h2c -duration=30s | vegeta report
```

### Target File (`targets.txt`)

```text
GET http://example.com/
POST http://api.example.com/users
Content-Type: application/json
@body.json
```

---

## Hey

### Installation

```bash
# Go
go install github.com/rakyll/hey@latest

# macOS
brew install hey
```

### Commands

```bash
# Basic
hey -n 10000 -c 100 http://example.com/

# With duration
hey -z 30s -c 100 http://example.com/

# POST
hey -n 1000 -c 50 -m POST -T "application/json" -d '{"name":"test"}' http://api.example.com/users

# With headers
hey -n 1000 -c 50 -H "Authorization: Bearer token" http://api.example.com/
```

---

## Siege

### Installation

```bash
# macOS
brew install siege

# Linux
sudo apt install siege
```

### Commands

```bash
# Basic
siege -c 100 -t 30s http://example.com/

# With URL file
siege -c 100 -t 1m -f urls.txt

# Benchmark mode
siege -c 50 -r 10 -b http://example.com/

# With config
siege -R ~/.siege/siege.conf -c 100 -t 5m http://example.com/
```

### URL File (`urls.txt`)

```text
http://example.com/
http://example.com/api/users POST {"name":"test"}
```

---

## Gatling

### Installation

```bash
# Download
wget https://repo1.maven.org/maven2/io/gatling/gatling-highcharts/3.10.3/gatling-highcharts-3.10.3.zip
unzip gatling-highcharts-3.10.3.zip

# Or via SDKMAN
sdk install gatling
```

### Sample Simulation (Scala)

```scala
import io.gatling.core.Predef._
import io.gatling.http.Predef._
import scala.concurrent.duration._

class BasicSimulation extends Simulation {
  val httpProtocol = http
    .baseUrl("https://api.example.com")
    .acceptHeader("application/json")

  val scn = scenario("Basic Load Test")
    .exec(http("Get Users").get("/users").check(status.is(200)))
    .pause(1)

  setUp(
    scn.inject(
      rampUsers(100).during(30.seconds),
      constantUsersPerSec(50).during(2.minutes)
    )
  ).protocols(httpProtocol)
}
```

### Commands

```bash
# Run simulation
gatling.sh -s BasicSimulation

# With description
gatling.sh -s BasicSimulation -rd "Load test run"

# Generate report
gatling.sh -ro results/basicsimulation-20240101120000
```

---

## Best Practices

- **Define clear goals** — RPS, latency SLAs, error budgets
- **Test in staging first** — mirror production as closely as possible
- **Start small** — ramp up gradually to find breaking points
- **Isolate the system** — no other traffic competing for resources
- **Monitor everything** — app metrics, DB, network, CPU, memory
- **Use realistic data** — realistic payloads, sizes, and user flows
- **Test repeatedly** — same test, same conditions for comparison
- **Test failure modes** — what happens under 2x, 5x, 10x load?
- **Think time** — include pauses to simulate real users
- **Correlate with business metrics** — TPS, revenue, conversions

---

## Metrics to Monitor

| Metric                  | Target / Notes                |
| ----------------------- | ----------------------------- |
| Throughput (RPS)        | Requests per second handled   |
| Latency (p50, p95, p99) | Response time percentiles     |
| Error rate              | % of failed requests          |
| Concurrent users        | Active VUs                    |
| CPU usage               | App, DB, load generator       |
| Memory usage            | Heap, RSS, GC pauses          |
| DB connections          | Pool saturation               |
| Network I/O             | Bandwidth, packets            |
| Disk I/O                | Read/write IOPS               |
| Queue depth             | App server, DB                |
| GC time                 | JVM/Node/Ruby GC              |
| Cache hit ratio         | Redis/Memcached/CDN           |

### Prometheus Query Examples

```promql
# p95 latency
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))

# Error rate
sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))

# RPS
sum(rate(http_requests_total[1m]))
```

See also [Monitoring and Alerting](./monitoring-alerting.md).

---

## CI/CD Integration

### GitHub Actions — k6

```yaml
name: Load Test
on: [push]

jobs:
  k6:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: grafana/setup-k6-action@v1
      - run: k6 run --out json=results.json load-test.js
      - uses: actions/upload-artifact@v4
        with:
          name: k6-results
          path: results.json
```

### GitLab CI — Locust

```yaml
load-test:
  image: locustio/locust
  script:
    - locust -f locustfile.py --headless -u 100 -r 10 -t 5m --host $TARGET_HOST --html report.html
  artifacts:
    paths:
      - report.html
```

### Jenkins — JMeter

```groovy
pipeline {
  agent any
  stages {
    stage('Load Test') {
      steps {
        sh 'jmeter -n -t test-plan.jmx -l results.jtl -e -o report'
        perfReport sourceDataFiles: 'results.jtl'
      }
    }
  }
}
```

---

## Tool Comparison

| Tool      | Language | Protocol Support           | Distributed  | Best For                      |
| --------- | -------- | -------------------------- | ------------ | ----------------------------- |
| JMeter    | Java     | HTTP, JDBC, JMS, FTP, +    | Yes          | Enterprise, complex protocols |
| k6        | JS       | HTTP, WebSocket, gRPC      | Yes (cloud)  | Developers, CI/CD             |
| Locust    | Python   | HTTP, custom               | Yes          | Python teams, custom logic    |
| Artillery | YAML/JS  | HTTP, WebSocket, Socket.io | Yes          | Quick API tests               |
| wrk/wrk2  | C/Lua    | HTTP                       | No           | Raw HTTP throughput           |
| ab        | C        | HTTP                       | No           | Simple benchmarks             |
| Vegeta    | Go       | HTTP                       | No           | Constant-rate testing         |
| Hey       | Go       | HTTP                       | No           | Simple, fast HTTP             |
| Siege     | C        | HTTP                       | No           | Simple load tests             |
| Gatling   | Scala    | HTTP, WebSocket, JMS       | Yes          | High-perf Scala teams         |

---

## Quick Reference Cheat Sheet

```bash
# JMeter
jmeter -n -t plan.jmx -l out.jtl -e -o report/

# k6
k6 run --vus 100 --duration 5m script.js

# Locust
locust -f locustfile.py --headless -u 100 -r 10 -t 5m

# Artillery
artillery run load.yml

# wrk
wrk -t12 -c400 -d30s http://example.com

# ab
ab -n 10000 -c 100 -k http://example.com/

# Vegeta
echo "GET http://example.com/" | vegeta attack -rate=100 -duration=30s | vegeta report

# Hey
hey -n 10000 -c 100 http://example.com/

# Siege
siege -c 100 -t 30s http://example.com/
```

---

## Additional Resources

- [k6 Docs](https://grafana.com/docs/k6/latest/)
- [JMeter Docs](https://jmeter.apache.org/usermanual/index.html)
- [Locust Docs](https://docs.locust.io/)
- [Artillery Docs](https://www.artillery.io/docs)
- [Gatling Docs](https://docs.gatling.io/)
- [Google SRE Book — Load Balancing](https://sre.google/sre-book/load-balancing-frontend/)
- [Load Testing Best Practices — k6](https://grafana.com/docs/k6/latest/testing-guides/)
