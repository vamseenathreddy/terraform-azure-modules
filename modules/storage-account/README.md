# storage-account

Secure-by-default Azure Storage Account (StorageV2).

## Security features

- HTTPS-only, TLS 1.2 minimum.
- **Shared access keys disabled** — Entra ID + RBAC is the only auth path
  (assign roles like `Storage Blob Data Contributor` to identities).
- **Anonymous/public blob access impossible** (`allow_nested_items_to_be_public = false`,
  all containers forced private).
- Firewall default-deny; private endpoint with private DNS integration.
- Infrastructure (double) encryption, blob versioning, change feed, and
  soft delete for blobs and containers.
- Read/Write/Delete audit logs to Log Analytics.

## Usage

```hcl
module "storage" {
  source = "github.com/vamseenathreddy/terraform-azure-modules//modules/storage-account"

  name                       = "stprodapp01data"
  resource_group_name        = azurerm_resource_group.data.name
  location                   = "centralindia"
  containers                 = ["raw", "curated"]
  private_endpoint_subnet_id = module.vnet.subnet_ids["snet-pep"]
  private_dns_zone_id        = azurerm_private_dns_zone.blob.id
  log_analytics_workspace_id = module.log_analytics.workspace_id
}
```
