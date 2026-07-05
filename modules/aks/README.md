# aks

Secure-by-default private AKS cluster.

## Security features

| Control | Default |
|---|---|
| Private API server | **Enabled** |
| Entra ID auth + Azure RBAC | Enabled, local accounts **disabled** |
| Workload identity + OIDC issuer | Enabled (no pod-level secrets) |
| Network policy | Cilium (Azure CNI overlay) |
| Encryption at host | Enabled on node pool |
| Microsoft Defender for Containers | Enabled |
| Control-plane audit logs | Shipped to Log Analytics |
| Key Vault CSI secret rotation | Enabled |
| Auto-upgrade | Patch channel + weekly maintenance window |

## Usage

```hcl
module "aks" {
  source = "github.com/vamseenathreddy/terraform-azure-modules//modules/aks"

  name                       = "aks-prod-01"
  resource_group_name        = azurerm_resource_group.aks.name
  location                   = "centralindia"
  subnet_id                  = module.vnet.subnet_ids["snet-aks"]
  admin_group_object_ids     = ["<entra-admin-group-object-id>"]
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
}
```
