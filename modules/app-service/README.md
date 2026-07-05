# app-service

Secure-by-default Linux App Service.

## Security features

- HTTPS-only with TLS 1.2 minimum; FTP/FTPS disabled entirely.
- Basic-auth publishing credentials disabled for both SCM and WebDeploy.
- IP restrictions **default to Deny** — traffic must be explicitly allowed by
  CIDR or Azure service tag (e.g. `AzureFrontDoor.Backend`).
- SCM (Kudu) site inherits the same restrictions.
- System-assigned managed identity, with optional automatic
  `Key Vault Secrets User` role assignment so app settings can use
  `@Microsoft.KeyVault(SecretUri=...)` references instead of plaintext secrets.
- Outbound VNet integration with `vnet_route_all_enabled`.
- HTTP, audit, and IPSec audit logs shipped to Log Analytics.

## Usage

```hcl
module "web" {
  source = "github.com/vamseenathreddy/terraform-azure-modules//modules/app-service"

  name                       = "app-orders-prod"
  resource_group_name        = azurerm_resource_group.app.name
  location                   = "centralindia"
  vnet_integration_subnet_id = module.vnet.subnet_ids["snet-appsvc"]
  key_vault_id               = module.kv.key_vault_id

  allowed_service_tags = [{
    name     = "allow-frontdoor"
    priority = 100
    tag      = "AzureFrontDoor.Backend"
  }]

  app_settings = {
    DB_PASSWORD = "@Microsoft.KeyVault(SecretUri=https://kv-prod-app01.vault.azure.net/secrets/db-password/)"
  }
}
```
