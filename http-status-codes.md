---
pagination_label: HTTP Status Codes
---

# HTTP Status Codes

HTTP status codes describe the result of a request. The first digit identifies
the response class: `1xx` informational, `2xx` success, `3xx` redirection,
`4xx` client error, and `5xx` server error. This page focuses on the codes
developers and operators encounter most often.

> Code names and assignments follow the [IANA HTTP Status Code
> Registry](https://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml).

## Status-code classes

| Range | Meaning | Typical action |
| --- | --- | --- |
| `1xx` | Request received; processing continues | Usually handled by the client, proxy, or protocol layer |
| `2xx` | The request succeeded | Confirm the response body and side effect match the contract |
| `3xx` | Further action or a different URI is needed | Follow or correct the redirect and its target |
| `4xx` | The request cannot be fulfilled as sent | Correct authentication, authorization, input, or rate of requests |
| `5xx` | A server or upstream dependency failed | Investigate server logs, recent changes, and upstream health |

## Informational and success responses

| Code | Name | Meaning / common use |
| --- | --- | --- |
| `100` | Continue | Server is willing to receive the request body. |
| `101` | Switching Protocols | Connection changes protocol, commonly for WebSockets. |
| `103` | Early Hints | Server sends preload hints before the final response. |
| `200` | OK | Request completed successfully; usually returns a response body. |
| `201` | Created | A new resource was created; include its URI when available. |
| `202` | Accepted | Request was accepted for asynchronous processing, not necessarily completed. |
| `204` | No Content | Request succeeded with no response body, often after an update or delete. |
| `206` | Partial Content | Server fulfilled a range request, commonly for resumable downloads or media. |

## Redirect responses

| Code | Name | Meaning / common use |
| --- | --- | --- |
| `301` | Moved Permanently | Resource has a permanent new URI; use for stable canonical redirects. |
| `302` | Found | Temporary redirect with historical client behavior; avoid it when method preservation matters. |
| `303` | See Other | Directs the client to retrieve another resource with `GET`, often after a form submission. |
| `304` | Not Modified | Cached representation is still valid; the response has no body. |
| `307` | Temporary Redirect | Temporary redirect that preserves the request method and body. |
| `308` | Permanent Redirect | Permanent redirect that preserves the request method and body. |

Use `307` or `308` for redirects of non-`GET` requests when clients must
preserve the method and request body. Confirm that the redirect target is
HTTPS, uses the intended host, and does not create a loop.

## Client-error responses

| Code | Name | Meaning | First thing to check |
| --- | --- | --- | --- |
| `400` | Bad Request | Request syntax or content is invalid. | Required fields, JSON validity, headers, and query parameters. |
| `401` | Unauthorized | Authentication is missing, invalid, or expired. | `Authorization` header, token expiry, and authentication challenge. |
| `403` | Forbidden | Identity is known but lacks permission, or access is deliberately denied. | Roles, resource policy, IP rules, and CSRF protection. |
| `404` | Not Found | Resource or route does not exist. | URI, HTTP method, deployment version, and reverse-proxy routing. |
| `405` | Method Not Allowed | Resource exists but does not accept this HTTP method. | Method and the `Allow` response header. |
| `408` | Request Timeout | Server timed out waiting for the request. | Client/network delay, request size, and server timeout settings. |
| `409` | Conflict | Request conflicts with the current resource state. | Versioning, duplicate creation, and concurrent updates. |
| `410` | Gone | Resource is intentionally unavailable and not expected to return. | Client migration path and documentation. |
| `413` | Content Too Large | Request content exceeds an accepted size. | Upload/body-size limits in the app, proxy, and ingress. |
| `415` | Unsupported Media Type | Server does not support the submitted content type. | `Content-Type`, encoding, and API contract. |
| `422` | Unprocessable Content | Syntax is valid but the content fails semantic validation. | Field-level validation errors and business rules. |
| `423` | Locked | Resource is locked, usually by a WebDAV workflow. | Lock owner, expiry, and retry strategy. |
| `429` | Too Many Requests | Client exceeded a rate limit. | `Retry-After`, quota, backoff, and request concurrency. |
| `431` | Request Header Fields Too Large | Headers exceed the server limit. | Cookie size, token size, and proxy header limits. |

### `401` versus `403`

- `401` means the request has not successfully authenticated. A response can
  include `WWW-Authenticate` to describe the required scheme.
- `403` means authentication will not by itself grant access to the requested
  resource. Do not expose sensitive authorization details in the response.

## Server-error responses

| Code | Name | Meaning | First thing to check |
| --- | --- | --- | --- |
| `500` | Internal Server Error | Application encountered an unexpected failure. | Application error logs, exception traces, and recent deployment/config changes. |
| `501` | Not Implemented | Server does not support the required request feature or method. | Endpoint capability and proxy/server configuration. |
| `502` | Bad Gateway | Proxy/gateway received an invalid response from an upstream. | Upstream process, service endpoints, DNS, and proxy logs. |
| `503` | Service Unavailable | Service is temporarily unable to handle requests. | Capacity, maintenance mode, health checks, and autoscaling. |
| `504` | Gateway Timeout | Proxy/gateway did not receive an upstream response in time. | Upstream latency, connection health, and aligned timeouts. |
| `505` | HTTP Version Not Supported | Server does not support the HTTP version used. | Client/proxy protocol settings. |
| `507` | Insufficient Storage | Server cannot store the representation needed to complete the request. | Disk, persistent volume, object storage, and quota capacity. |
| `511` | Network Authentication Required | Client must authenticate to gain network access. | Captive portal or network access policy. |

### `502`, `503`, and `504`

- `502` usually means the upstream sent a bad or unusable response.
- `503` means the service intentionally or temporarily cannot serve the
  request; it may provide `Retry-After`.
- `504` means the upstream did not answer within the gateway timeout.

For all three, inspect the proxy/ingress and application logs over the same
time range, then check upstream health, DNS, network policy, capacity, and the
most recent deployment.

## Check a response with curl

Print only the final status code:

```bash
curl -sS -o /dev/null -w '%{http_code}\n' https://example.com/health
```

Show response headers and follow redirects:

```bash
curl -sS -I -L https://example.com
```

Inspect a failed API response without hiding its body:

```bash
curl -i \
  -H 'Accept: application/json' \
  https://api.example.com/v1/resource
```

For a request that may fail, `curl --fail-with-body` returns a non-zero exit
status for `4xx` and `5xx` responses while retaining the response body for
diagnosis:

```bash
curl --fail-with-body -sS https://example.com/health
```

## API and operations guidance

- Return the most specific standard status code that matches the outcome.
- Return a consistent, non-sensitive error body with a stable error code,
  readable message, and request/trace ID.
- Include `Location` for a newly created resource or redirect where applicable.
- Include `Retry-After` for `429` and temporary `503` responses when clients
  can safely retry.
- Make retry behavior explicit. Retrying `GET` is often safe; automatically
  retrying a non-idempotent write can duplicate work unless the API supports an
  idempotency key.
- Alert on sustained user-facing `5xx` error rate and unexpected availability
  failures, not on a single isolated response.

## Related

- [Basic Linux Commands](./linux-commands.md#http-requests-with-curl) — common
  `curl` requests.
- [DNS and Domain Commands](./domain-dns-commands.md) — diagnose DNS, TLS, and
  HTTP responses.
- [NGINX](./web-servers/nginx.md) and [Apache](./web-servers/apache.md) —
  reverse-proxy and server configuration.
- [Monitoring and Alerting](./operations/monitoring-alerting.md) — observe and
  respond to HTTP failures.
