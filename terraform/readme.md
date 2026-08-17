# Terraform

Terraform lets the team define cloud infrastructure in version-controlled
configuration. Treat a Terraform change like application code: review its
plan, apply it through an approved workflow, and keep the state file out of
Git.

## Before you start

- Install a supported Terraform version and confirm it with `terraform version`.
- Authenticate with the cloud provider using a short-lived role or a locally
  stored credential profile. Do not put API tokens in `.tf`, `.tfvars`, or
  committed shell history.
- Decide who owns the state backend and who may apply changes to each
  environment.
- Create a separate state location for every environment, such as `staging`
  and `production`.

## Recommended layout

Keep reusable code separate from environment-specific values:

```text
infrastructure/
├── modules/
│   └── web-service/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── environments/
    ├── staging/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── staging.tfvars.example
    │   └── backend.hcl.example
    └── production/
        ├── main.tf
        ├── variables.tf
        ├── production.tfvars.example
        └── backend.hcl.example
```

Use modules for repeated resources. Keep account IDs, regions, domains, and
environment sizing in environment directories. Commit only `*.example` values;
store real sensitive values in the team secret manager or the CI credential
store.

## Minimal provider configuration

This example pins the provider source and accepts the access token from the
`DIGITALOCEAN_TOKEN` environment variable. The same pattern applies to AWS
profiles or assumed roles.

```hcl
terraform {
  required_version = ">= 1.6"

  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
    }
  }
}

provider "digitalocean" {}

variable "environment" {
  type        = string
  description = "Deployment environment, for example staging or production."
}

resource "digitalocean_tag" "environment" {
  name = "environment:${var.environment}"
}

output "environment_tag" {
  value = digitalocean_tag.environment.name
}
```

Run it without exposing the token in a command:

```bash
export DIGITALOCEAN_TOKEN="<read-from-secret-manager>"
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out=tfplan -var='environment=staging'
terraform apply tfplan
```

The `.tfplan` file can contain sensitive values. Do not commit it, upload it to
untrusted storage, or reuse it after the configuration or real infrastructure
has changed.

## State management

Terraform state maps configuration to real infrastructure and may contain
resource IDs, endpoints, and secret values. It must be protected accordingly.

- Use a remote backend with encryption, access control, version history, and
  state locking supported by the selected backend and Terraform version.
- Bootstrap that backend separately and document its owner; avoid managing the
  backend from the same state that depends on it.
- Pass backend settings from an uncommitted `backend.hcl` file or CI variables.
- Restrict production state reads and writes. Read access can reveal sensitive
  configuration.
- Never manually edit a remote state file. Use `terraform state` commands only
  after taking a versioned backup and documenting why.

Example initialization with an uncommitted backend configuration:

```bash
terraform init -backend-config=backend.hcl
```

Add these entries to `.gitignore` in a Terraform repository:

```gitignore
.terraform/
*.tfstate
*.tfstate.*
*.tfplan
*.tfvars
!*.tfvars.example
backend.hcl
```

> Commit `.terraform.lock.hcl` so the team shares verified provider checksums.

## Safe change workflow

1. Create a small, reviewed pull request for the configuration change.
2. Run `terraform fmt -check -recursive` and `terraform validate`.
3. Generate a plan against the intended environment and attach its sanitized
   output to the pull request.
4. Confirm the workspace/backend and cloud account before applying.
5. Apply from CI or a controlled administrator session; record the change and
   resulting Terraform version.
6. Verify the deployed service, monitoring, backups, and tags after the
   apply.

Useful read-only commands:

```bash
terraform workspace show
terraform state list
terraform plan -refresh-only
terraform output
```

`terraform destroy` is a production-impacting action. Require an explicit
change request, a recent backup/restore check, a reviewed destroy plan, and
approval from the system owner before using it.

## CI/CD checklist

- Authenticate CI with workload identity, an assumed role, or another
  short-lived mechanism—not a broadly shared static key.
- Use separate CI identities and state access for staging and production.
- Make `fmt`, `validate`, and a non-applying plan required pull-request checks.
- Limit applies to protected branches and use a manual approval for production.
- Redact plan output and do not print provider tokens or `terraform output`
  values marked sensitive.

## Related

- [AWS](../aws/readme.md) — cloud service guides and IAM patterns.
- [DigitalOcean](../digitalocean/readme.md) — Droplets, Kubernetes, and Spaces.
- [Jenkins Secrets](../jenkins/secrets.md) — handling credentials in pipelines.
- [Operations](../operations/readme.md) — backup, recovery, monitoring, and
  alerting expectations.
