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

### Sample Test Plan (`test-plan.jmx`)

A minimal plan you can run without opening the GUI. Thread count, ramp-up,
duration and target are read from `-J` properties, with defaults:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<jmeterTestPlan version="1.2" properties="5.0" jmeter="5.6.3">
  <hashTree>
    <TestPlan guiclass="TestPlanGui" testclass="TestPlan" testname="API Load Test">
      <elementProp name="TestPlan.user_defined_variables" elementType="Arguments">
        <collectionProp name="Arguments.arguments"/>
      </elementProp>
    </TestPlan>
    <hashTree>
      <ConfigTestElement guiclass="HttpDefaultsGui" testclass="ConfigTestElement" testname="HTTP Request Defaults">
        <elementProp name="HTTPsampler.Arguments" elementType="Arguments">
          <collectionProp name="Arguments.arguments"/>
        </elementProp>
        <stringProp name="HTTPSampler.protocol">${__P(protocol,https)}</stringProp>
        <stringProp name="HTTPSampler.domain">${__P(host,api.example.com)}</stringProp>
        <stringProp name="HTTPSampler.port">${__P(port,443)}</stringProp>
      </ConfigTestElement>
      <hashTree/>
      <HeaderManager guiclass="HeaderPanel" testclass="HeaderManager" testname="Headers">
        <collectionProp name="HeaderManager.headers">
          <elementProp name="" elementType="Header">
            <stringProp name="Header.name">Content-Type</stringProp>
            <stringProp name="Header.value">application/json</stringProp>
          </elementProp>
        </collectionProp>
      </HeaderManager>
      <hashTree/>
      <ThreadGroup guiclass="ThreadGroupGui" testclass="ThreadGroup" testname="Users">
        <stringProp name="ThreadGroup.on_sample_error">continue</stringProp>
        <elementProp name="ThreadGroup.main_controller" elementType="LoopController">
          <boolProp name="LoopController.continue_forever">false</boolProp>
          <intProp name="LoopController.loops">-1</intProp>
        </elementProp>
        <stringProp name="ThreadGroup.num_threads">${__P(users,10)}</stringProp>
        <stringProp name="ThreadGroup.ramp_time">${__P(rampup,10)}</stringProp>
        <boolProp name="ThreadGroup.scheduler">true</boolProp>
        <stringProp name="ThreadGroup.duration">${__P(duration,60)}</stringProp>
      </ThreadGroup>
      <hashTree>
        <HTTPSamplerProxy guiclass="HttpTestSampleGui" testclass="HTTPSamplerProxy" testname="GET /users">
          <elementProp name="HTTPsampler.Arguments" elementType="Arguments">
            <collectionProp name="Arguments.arguments"/>
          </elementProp>
          <stringProp name="HTTPSampler.path">/users</stringProp>
          <stringProp name="HTTPSampler.method">GET</stringProp>
        </HTTPSamplerProxy>
        <hashTree>
          <ResponseAssertion guiclass="AssertionGui" testclass="ResponseAssertion" testname="Status 200">
            <collectionProp name="Asserion.test_strings">
              <stringProp name="49586">200</stringProp>
            </collectionProp>
            <stringProp name="Assertion.test_field">Assertion.response_code</stringProp>
            <intProp name="Assertion.test_type">8</intProp>
          </ResponseAssertion>
          <hashTree/>
        </hashTree>
        <HTTPSamplerProxy guiclass="HttpTestSampleGui" testclass="HTTPSamplerProxy" testname="POST /users">
          <boolProp name="HTTPSampler.postBodyRaw">true</boolProp>
          <elementProp name="HTTPsampler.Arguments" elementType="Arguments">
            <collectionProp name="Arguments.arguments">
              <elementProp name="" elementType="HTTPArgument">
                <boolProp name="HTTPArgument.always_encode">false</boolProp>
                <stringProp name="Argument.value">{"name":"test-${__threadNum}","email":"test${__Random(1,999999)}@example.com"}</stringProp>
                <stringProp name="Argument.metadata">=</stringProp>
              </elementProp>
            </collectionProp>
          </elementProp>
          <stringProp name="HTTPSampler.path">/users</stringProp>
          <stringProp name="HTTPSampler.method">POST</stringProp>
        </HTTPSamplerProxy>
        <hashTree/>
        <ConstantTimer guiclass="ConstantTimerGui" testclass="ConstantTimer" testname="Think time">
          <stringProp name="ConstantTimer.delay">1000</stringProp>
        </ConstantTimer>
        <hashTree/>
      </hashTree>
    </hashTree>
  </hashTree>
</jmeterTestPlan>
```

> `Asserion.test_strings` is JMeter's own (misspelled) property name — keep it
> as is.

Run it against staging with 100 users for 5 minutes:

```bash
jmeter -n -t test-plan.jmx \
  -Jhost=staging.example.com -Jusers=100 -Jrampup=60 -Jduration=300 \
  -l results.jtl -e -o ./report
```

> ⚠️ `-o` must point to an empty or non-existent folder. Remove `./report`
> before re-running.

### Distributed Setup

On each load generator (`server1`, `server2`, …):

```bash
# Simplest setup for a private network (disables RMI SSL)
jmeter-server -Jserver.rmi.ssl.disable=true
```

On the controller, pass the same flag:

```bash
jmeter -n -t test-plan.jmx -R server1,server2 -Jserver.rmi.ssl.disable=true \
  -Gusers=100 -l results.jtl
```

> Use `-G` (not `-J`) for properties that the remote servers must see. Each
> remote server runs the **full** thread count, so 2 servers × 100 users =
> 200 users.

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

### Full Example: Environment, Login and Multiple Endpoints (`api-test.js`)

Reads the target from `BASE_URL`, logs in once in `setup()`, then shares the
token with every virtual user:

```javascript
import http from 'k6/http';
import { check, group, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'https://staging.example.com';

export const options = {
  stages: [
    { duration: '1m', target: 20 },
    { duration: '3m', target: 20 },
    { duration: '1m', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'],
    'http_req_duration{name:list-users}': ['p(95)<300'],
    http_req_failed: ['rate<0.01'],
    checks: ['rate>0.99'],
  },
};

export function setup() {
  const res = http.post(
    `${BASE_URL}/login`,
    JSON.stringify({ username: __ENV.USERNAME, password: __ENV.PASSWORD }),
    { headers: { 'Content-Type': 'application/json' } },
  );
  check(res, { 'login ok': (r) => r.status === 200 });
  return { token: res.json('token') };
}

export default function (data) {
  const params = {
    headers: {
      Authorization: `Bearer ${data.token}`,
      'Content-Type': 'application/json',
    },
  };

  group('read', () => {
    const res = http.get(`${BASE_URL}/users`, { ...params, tags: { name: 'list-users' } });
    check(res, { 'list 200': (r) => r.status === 200 });
  });

  group('write', () => {
    const body = JSON.stringify({ name: `vu-${__VU}`, email: `vu${__VU}-${__ITER}@example.com` });
    const res = http.post(`${BASE_URL}/users`, body, { ...params, tags: { name: 'create-user' } });
    check(res, { 'create 201': (r) => r.status === 201 });
  });

  sleep(Math.random() * 2 + 1); // 1–3 s think time
}
```

```bash
k6 run -e BASE_URL=https://staging.example.com -e USERNAME=loadtest -e PASSWORD='secret' api-test.js
```

> If any threshold fails, k6 exits with a non-zero code — this is what makes
> it fail a CI job.

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

A scenario block only replaces `options` — the file still needs a `default`
function. Complete runnable file (`arrival-rate.js`):

```javascript
import http from 'k6/http';
import { check } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'https://staging.example.com';

export const options = {
  scenarios: {
    constant_request_rate: {
      executor: 'constant-arrival-rate',
      rate: 200,            // 200 iterations (requests) per second
      timeUnit: '1s',
      duration: '5m',
      preAllocatedVUs: 50,
      maxVUs: 300,
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.01'],
    dropped_iterations: ['count<100'], // VUs ran out → raise maxVUs or the server is saturated
  },
};

export default function () {
  const res = http.get(`${BASE_URL}/users`);
  check(res, { 'status 200': (r) => r.status === 200 });
}
```

> Use **arrival-rate** executors when you want a fixed RPS regardless of how
> slow the server gets; use **stages / VUs** when you want a fixed number of
> concurrent users.

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

### Full Example: Auth Token, Tags and Response Validation

Matches the `--tags` / `--exclude-tags` commands below:

```python
import os
import random
from locust import HttpUser, task, between, tag


class ApiUser(HttpUser):
    wait_time = between(1, 3)
    host = os.getenv("TARGET_HOST", "https://staging.example.com")

    def on_start(self):
        res = self.client.post(
            "/login",
            json={"username": os.getenv("LT_USER", "loadtest"),
                  "password": os.getenv("LT_PASS", "secret")},
            name="POST /login",
        )
        token = res.json().get("token")
        self.client.headers.update({"Authorization": f"Bearer {token}"})

    @tag("smoke")
    @task(5)
    def list_users(self):
        with self.client.get("/users", name="GET /users", catch_response=True) as res:
            if res.status_code != 200:
                res.failure(f"status {res.status_code}")
            elif not res.json():
                res.failure("empty body")

    @tag("smoke")
    @task(3)
    def get_user(self):
        user_id = random.randint(1, 1000)
        # name= groups /users/1, /users/2 … into one stats row
        self.client.get(f"/users/{user_id}", name="GET /users/[id]")

    @tag("heavy")
    @task(1)
    def create_user(self):
        n = random.randint(1, 1_000_000)
        self.client.post("/users", json={"name": f"lt-{n}", "email": f"lt-{n}@example.com"},
                         name="POST /users")
```

```bash
TARGET_HOST=https://staging.example.com \
  locust -f locustfile.py --headless -u 200 -r 20 -t 10m --tags smoke --html report.html
```

### Config File (`locust.conf`)

Instead of long command lines:

```ini
locustfile = locustfile.py
host = https://staging.example.com
headless = true
users = 200
spawn-rate = 20
run-time = 10m
html = report.html
csv = results
```

```bash
locust --config locust.conf
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

### Full Example: Environments, Login and Captured Values (`api-flow.yml`)

```yaml
config:
  target: "https://staging.example.com"
  environments:
    staging:
      target: "https://staging.example.com"
    local:
      target: "http://localhost:8000"
  phases:
    - duration: 60
      arrivalRate: 5
      rampTo: 50
      name: "Ramp up"
    - duration: 300
      arrivalRate: 50
      name: "Sustained"
  ensure:
    thresholds:
      - http.response_time.p95: 500
      - http.response_time.p99: 1000
    conditions:
      - expression: vusers.failed / vusers.created < 0.01
  defaults:
    headers:
      Content-Type: "application/json"

scenarios:
  - name: "Login, browse, create"
    flow:
      - post:
          url: "/login"
          json:
            username: "{{ $processEnvironment.LT_USER }}"
            password: "{{ $processEnvironment.LT_PASS }}"
          capture:
            - json: "$.token"
              as: "token"
      - get:
          url: "/users"
          headers:
            Authorization: "Bearer {{ token }}"
          expect:
            - statusCode: 200
      - think: 2
      - post:
          url: "/users"
          headers:
            Authorization: "Bearer {{ token }}"
          json:
            name: "lt-{{ $randomNumber(1, 1000000) }}"
            email: "lt-{{ $randomNumber(1, 1000000) }}@example.com"
```

> `expect:` assertions need the plugin: `npm install -g artillery-plugin-expect`
> and `plugins: { expect: {} }` under `config`. The `ensure` block makes
> `artillery run` exit non-zero when thresholds fail.

```bash
LT_USER=loadtest LT_PASS=secret artillery run -e staging api-flow.yml
```

### Commands

```bash
# Run test
artillery run load-test.yml

# Override target without editing the file
artillery run --target https://staging.example.com load-test.yml

# Pick an environment from config.environments
artillery run -e staging api-flow.yml

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

# Linux (Debian/Ubuntu package)
sudo apt install wrk

# Linux (build from source)
sudo apt install -y build-essential libssl-dev git zlib1g-dev
git clone https://github.com/wg/wrk.git
cd wrk && make && sudo cp wrk /usr/local/bin/

# wrk2 on Linux (binary is also called wrk — install it as wrk2)
git clone https://github.com/giltene/wrk2.git
cd wrk2 && make && sudo cp wrk /usr/local/bin/wrk2
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

### Custom Script (`script.lua`)

Rotates through several endpoints, adds an auth header, and counts non-2xx
responses:

```lua
local token = os.getenv("TOKEN") or ""
local paths = { "/users", "/users/1", "/products", "/health" }
local i = 0
local errors = 0

request = function()
  i = (i % #paths) + 1
  return wrk.format("GET", paths[i], {
    ["Authorization"] = "Bearer " .. token,
    ["Accept"] = "application/json",
  })
end

response = function(status, headers, body)
  if status < 200 or status >= 300 then
    errors = errors + 1
  end
end

done = function(summary, latency, requests)
  io.write(string.format("non-2xx (last thread): %d\n", errors))
  io.write(string.format("p50 %.2f ms | p90 %.2f ms | p99 %.2f ms\n",
    latency:percentile(50) / 1000,
    latency:percentile(90) / 1000,
    latency:percentile(99) / 1000))
end
```

```bash
TOKEN=xxxxx wrk -t4 -c100 -d60s --latency -s script.lua https://staging.example.com
```

> The `response()` counter runs per thread, so the error count printed by
> `done()` is from one thread only. Use wrk's built-in `Non-2xx or 3xx
> responses` line for the total.

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
| `-t` | Time limit (seconds) |
| `-s` | Per-request timeout (seconds, default 30) |

### POST Body File (`data.json`)

```json
{
  "name": "test",
  "email": "test@example.com"
}
```

### Run for a Fixed Time

`-t` stops after N seconds; set `-n` high so the time limit is reached first:

```bash
ab -t 60 -n 10000000 -c 100 -k https://staging.example.com/
```

> ⚠️ `ab` speaks HTTP/1.0 and uses a single thread, so it can become the
> bottleneck above a few thousand RPS. Use `wrk`, `hey` or `k6` for higher
> load.

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

Requests are separated by a blank line; headers go directly under the request
line. A fuller target file:

```text
GET https://staging.example.com/users
Authorization: Bearer xxxxx

GET https://staging.example.com/products?page=2
Authorization: Bearer xxxxx

POST https://staging.example.com/users
Authorization: Bearer xxxxx
Content-Type: application/json
@body.json
```

### Body File (`body.json`)

```json
{
  "name": "test",
  "email": "test@example.com"
}
```

### Reports

```bash
# Text summary (latency mean/50/90/95/99/max, success ratio, status codes)
vegeta report results.bin

# Latency histogram with custom buckets
vegeta report -type='hist[0,50ms,100ms,250ms,500ms,1s]' results.bin

# Live report every 5 s while a test is running
vegeta attack -targets=targets.txt -rate=200 -duration=5m | tee results.bin | vegeta report -every=5s
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

# POST body from a file
hey -n 1000 -c 50 -m POST -T "application/json" -D body.json http://api.example.com/users

# Rate limit: 20 requests/sec per worker (× -c workers = total RPS)
hey -z 2m -c 10 -q 20 http://example.com/

# Export every request as CSV
hey -n 1000 -c 50 -o csv http://example.com/ > hey-results.csv
```

### Flags

| Flag | Description                                   |
| ---- | --------------------------------------------- |
| `-n` | Total requests                                |
| `-c` | Concurrent workers                            |
| `-z` | Duration (overrides `-n`), e.g. `30s`, `5m`   |
| `-q` | Rate limit per worker (requests/sec)          |
| `-m` | HTTP method                                   |
| `-H` | Header (repeatable)                           |
| `-d` | Request body                                  |
| `-D` | Request body from file                        |
| `-T` | Content-Type                                  |
| `-t` | Timeout per request in seconds (default 20)   |
| `-o` | Output type (`csv`)                           |

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

### Config File (`~/.siege/siege.conf`)

Generate the default with `siege.config`, then adjust the key settings:

```ini
# Keep connections open between requests
connection = keep-alive
# Seconds to wait for a response
timeout = 30
# Random delay (0..N seconds) between requests per user
delay = 1
# Don't download page assets (images, css, js)
parser = false
# Pick URLs from urls.txt at random
internet = true
# Default headers
header = Accept: application/json
logging = true
logfile = /var/log/siege.log
```

### More Commands

```bash
# With headers
siege -c 50 -t 2m -H "Authorization: Bearer token" -H "Accept: application/json" http://example.com/api/users

# Random URLs from file (internet mode), 1 s max delay per user
siege -c 100 -t 5m -i -d 1 -f urls.txt
```

### Flags

| Flag | Description                                   |
| ---- | --------------------------------------------- |
| `-c` | Concurrent users                              |
| `-t` | Time (`30S`, `5M`, `1H`)                      |
| `-r` | Repetitions per user                          |
| `-b` | Benchmark mode (no delay between requests)    |
| `-d` | Max random delay between requests (seconds)   |
| `-f` | URL file                                      |
| `-i` | Internet mode (random URLs from file)         |
| `-H` | Header                                        |
| `-R` | Alternate config file                         |

---

## Gatling

### Installation

```bash
# Download
wget https://repo1.maven.org/maven2/io/gatling/highcharts/gatling-charts-highcharts-bundle/3.10.3/gatling-charts-highcharts-bundle-3.10.3-bundle.zip
unzip gatling-charts-highcharts-bundle-3.10.3-bundle.zip
export PATH=$PATH:$(pwd)/gatling-charts-highcharts-bundle-3.10.3/bin

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

Save it as
`gatling-charts-highcharts-bundle-3.10.3/user-files/simulations/BasicSimulation.scala`
so the bundle can find it.

### Full Example: Login, Feeder and Assertions (Java DSL)

`users.csv` (in `user-files/resources/`):

```text
username,password
loadtest1,secret1
loadtest2,secret2
```

`ApiSimulation.java` (in `user-files/simulations/`):

```java
import static io.gatling.javaapi.core.CoreDsl.*;
import static io.gatling.javaapi.http.HttpDsl.*;

import io.gatling.javaapi.core.*;
import io.gatling.javaapi.http.*;
import java.time.Duration;

public class ApiSimulation extends Simulation {

  String baseUrl = System.getProperty("baseUrl", "https://staging.example.com");

  HttpProtocolBuilder httpProtocol = http
      .baseUrl(baseUrl)
      .acceptHeader("application/json")
      .contentTypeHeader("application/json");

  FeederBuilder<String> users = csv("users.csv").circular();

  ScenarioBuilder scn = scenario("API flow")
      .feed(users)
      .exec(http("login")
          .post("/login")
          .body(StringBody("{\"username\":\"#{username}\",\"password\":\"#{password}\"}"))
          .check(status().is(200), jsonPath("$.token").saveAs("token")))
      .pause(1)
      .repeat(5).on(
          exec(http("list users")
              .get("/users")
              .header("Authorization", "Bearer #{token}")
              .check(status().is(200)))
          .pause(Duration.ofMillis(500), Duration.ofSeconds(2)))
      .exec(http("create user")
          .post("/users")
          .header("Authorization", "Bearer #{token}")
          .body(StringBody("{\"name\":\"lt-#{username}\",\"email\":\"#{username}@example.com\"}"))
          .check(status().in(200, 201)));

  {
    setUp(
        scn.injectOpen(
            rampUsersPerSec(1).to(50).during(Duration.ofMinutes(2)),
            constantUsersPerSec(50).during(Duration.ofMinutes(5))))
        .protocols(httpProtocol)
        .assertions(
            global().responseTime().percentile(95.0).lt(500),
            global().responseTime().percentile(99.0).lt(1000),
            global().failedRequests().percent().lt(1.0));
  }
}
```

```bash
JAVA_OPTS="-DbaseUrl=https://staging.example.com" gatling.sh -s ApiSimulation
```

> Failed assertions make Gatling exit non-zero, so the same simulation works
> as a CI gate. For new projects, Gatling recommends the Maven/Gradle plugin
> (`mvn gatling:test -Dgatling.simulationClass=ApiSimulation`) over the
> standalone bundle.

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

> `perfReport` needs the Jenkins **Performance** plugin.

### Full Jenkins Pipeline — k6 with Parameters and Archived Report

```groovy
pipeline {
  agent any
  parameters {
    string(name: 'BASE_URL', defaultValue: 'https://staging.example.com', description: 'Target URL')
    string(name: 'VUS', defaultValue: '50', description: 'Virtual users')
    string(name: 'DURATION', defaultValue: '5m', description: 'Test duration')
  }
  stages {
    stage('Load Test') {
      steps {
        sh '''
          docker run --rm -v "$PWD:/scripts" -w /scripts grafana/k6 run \
            -e BASE_URL="$BASE_URL" --vus "$VUS" --duration "$DURATION" \
            --summary-export=summary.json load-test.js
        '''
      }
    }
  }
  post {
    always {
      archiveArtifacts artifacts: 'summary.json', allowEmptyArchive: true
    }
  }
}
```

Because k6 exits non-zero when a threshold fails, the stage (and build) fails
automatically when p95 latency or the error rate exceeds the limits in the
script.

### Full GitHub Actions Workflow — Manual Trigger with Inputs

```yaml
name: Load Test
on:
  workflow_dispatch:
    inputs:
      base_url:
        description: "Target URL"
        default: "https://staging.example.com"
      vus:
        description: "Virtual users"
        default: "50"
      duration:
        description: "Duration"
        default: "5m"

jobs:
  k6:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: grafana/setup-k6-action@v1
      - name: Run k6
        env:
          BASE_URL: ${{ inputs.base_url }}
          USERNAME: ${{ secrets.LT_USER }}
          PASSWORD: ${{ secrets.LT_PASS }}
        run: |
          k6 run -e BASE_URL="$BASE_URL" -e USERNAME="$USERNAME" -e PASSWORD="$PASSWORD" \
            --vus ${{ inputs.vus }} --duration ${{ inputs.duration }} \
            --summary-export=summary.json api-test.js
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: k6-summary
          path: summary.json
```

> Running load tests on every `push` is usually too expensive and noisy. Use
> `workflow_dispatch`, a schedule, or run only on merges to the release
> branch.

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
