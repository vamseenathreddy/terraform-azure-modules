# key-vault

Secure-by-default Azure Key Vault.

## Security features

- **RBAC authorization only** — legacy access policies are not supported by
  this module.
- **Purge protection and 90-day soft delete are hard-coded on** — they are
  deliberately not variables, so no consumer can weaken them.
- **Network ACLs default to Deny**; access is via private endpoint, allowed
  subnets, or explicitly listed CIDRs.
- Public network access is automatically disabled when a private endpoint is
  configured.
- AuditEvent logs shipped to Log Analytics.

## Usage

```hcl
module "kv" {
  source = "github.com/vamseenathreddy/terraform-azure-modules//modules/key-vault"

  name                       = "kv-prod-app01"
  resource_group_name        = azurerm_resource_group.sec.name
  location                   = "centralindia"
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  private_endpoint_subnet_id = module.vnet.subnet_ids["snet-pep"]
  private_dns_zone_id        = azurerm_private_dns_zone.kv.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
}
```
