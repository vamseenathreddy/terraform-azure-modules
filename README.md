# terraform-azure-modules

Reusable, **secure-by-default** Terraform modules for Microsoft Azure —
VNet, AKS, Key Vault, App Service, Storage, Container Registry, and Log Analytics — with CI validation and security
scanning on every pull request.

> Copyright (c) 2026 G Vamseenath Reddy · [MIT License](LICENSE)

[![terraform-ci](https://github.com/vamseenathreddy/terraform-azure-modules/actions/workflows/ci.yml/badge.svg)](https://github.com/vamseenathreddy/terraform-azure-modules/actions/workflows/ci.yml)

## Why this repo

Most Terraform examples get you something that *works*; these modules get you
something you could put in front of a security review. Every module ships with
hardened defaults, and the dangerous knobs either don't exist or default to
the safe side:

- **Network**: deny-by-default NSGs, private endpoints, no accidental public
  exposure.
- **Identity**: Entra ID + Azure RBAC everywhere, managed identities instead
  of credentials, local/basic auth disabled.
- **Encryption**: TLS 1.2+, HTTPS-only, encryption at host.
- **Deletion safety**: Key Vault purge protection and soft delete are
  hard-coded on — not variables.
- **Audit**: diagnostic settings to Log Analytics on every module.

## Modules

| Module | What it creates | Highlights |
|---|---|---|
| [`vnet`](modules/vnet) | Virtual network + subnets | Deny-by-default NSG on every subnet, optional DDoS plan and flow logs |
| [`aks`](modules/aks) | AKS cluster | Private API server, Azure RBAC, workload identity, Cilium network policy, Defender |
| [`key-vault`](modules/key-vault) | Key Vault | RBAC-only, purge protection, private endpoint, default-deny firewall |
| [`app-service`](modules/app-service) | Linux App Service + plan | HTTPS/TLS1.2, deny-all IP restrictions, Key Vault references, VNet integration |
| [`storage-account`](modules/storage-account) | StorageV2 account + containers | Shared keys disabled (RBAC-only), no public blobs, versioning + soft delete, private endpoint |
| [`acr`](modules/acr) | Container Registry | Admin account disabled, AcrPull to AKS kubelet identity (no pull secrets), private endpoint |
| [`log-analytics`](modules/log-analytics) | Log Analytics workspace | Central audit sink, Entra-only auth, retention + daily cost quota |

## Quick start

See [`examples/complete`](examples/complete) for a full stack wiring all four
modules together: a VNet with three subnets and deny-by-default NSGs, private DNS zones, a Key
Vault, Storage account and Container Registry all behind private endpoints, a
private AKS cluster pulling images with its managed identity, and an App
Service locked to Azure Front Door — with every audit log flowing into one
Log Analytics workspace.

```bash
cd examples/complete
terraform init
terraform plan
```

## CI pipeline

Every PR runs, per module:

1. `terraform fmt -check` — formatting
2. `terraform validate` — schema validity
3. `tflint` with the azurerm ruleset — provider-aware linting
4. `checkov` — policy-as-code misconfiguration scanning (hard fail)
5. `gitleaks` — secret detection across full git history

## Local development

```bash
pip install pre-commit && pre-commit install
pre-commit run --all-files
```

## Versioning

Modules are consumed by git tag:

```hcl
source = "github.com/vamseenathreddy/terraform-azure-modules//modules/aks?ref=v1.0.0"
```

## License

MIT — see [LICENSE](LICENSE).
