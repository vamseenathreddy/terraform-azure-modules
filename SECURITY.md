# Security Policy

## Design Principles

All modules in this repository are built **secure by default**:

- **No public exposure by default** — private clusters, private endpoints, and
  network ACLs that default to `Deny`.
- **Encryption everywhere** — TLS 1.2+ enforced, HTTPS-only, encryption at rest
  and at host where the service supports it.
- **Identity over secrets** — system/user-assigned managed identities and
  Azure RBAC instead of access policies, keys, or embedded credentials.
- **No secrets in code or state where avoidable** — modules never accept
  plaintext credentials as inputs; sensitive outputs are marked `sensitive`.
- **Auditability** — diagnostic settings hooks on every module.

## Static Analysis

Every pull request runs:

| Check | Tool |
|---|---|
| Formatting | `terraform fmt -check` |
| Validity | `terraform validate` |
| Lint | `tflint` (azurerm ruleset) |
| Policy / misconfiguration scan | `checkov` |
| Secret scan | `gitleaks` |

## Reporting a Vulnerability

Please open a private security advisory on GitHub or email the maintainer.
Do not open public issues for security findings.
