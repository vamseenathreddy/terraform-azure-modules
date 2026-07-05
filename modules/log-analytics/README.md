# log-analytics

Central Log Analytics workspace — the audit and observability sink for every
other module in this repository.

## Security & cost features

- Workspace shared-key auth disabled (`local_authentication_enabled = false`);
  queries authenticate via Entra ID.
- Resource-context RBAC (`allow_resource_only_permissions = true`).
- 90-day default retention for security investigations.
- Daily ingestion quota as a cost guardrail.

## Usage

```hcl
module "log_analytics" {
  source = "github.com/vamseenathreddy/terraform-azure-modules//modules/log-analytics"

  name                = "log-platform-prod"
  resource_group_name = azurerm_resource_group.this.name
  location            = "centralindia"
}
```
