# acr

Secure-by-default Azure Container Registry, designed to pair with the `aks` module.

## Security features

- Admin account **disabled**, anonymous pull **disabled** — access is Entra ID
  + RBAC only.
- `AcrPull` automatically granted to the AKS kubelet managed identity, so
  clusters pull images with **zero stored credentials** (no imagePullSecrets).
- Private endpoint with `privatelink.azurecr.io` DNS; public endpoint closed
  when the private endpoint is enabled.
- Untagged-manifest retention policy and zone redundancy (Premium).
- Login and repository (push/pull/delete) audit events to Log Analytics.

## Usage

```hcl
module "acr" {
  source = "github.com/vamseenathreddy/terraform-azure-modules//modules/acr"

  name                           = "acrprodplatform01"
  resource_group_name            = azurerm_resource_group.this.name
  location                       = "centralindia"
  aks_kubelet_identity_object_id = module.aks.kubelet_identity_object_id
  private_endpoint_subnet_id     = module.vnet.subnet_ids["snet-pep"]
  private_dns_zone_id            = azurerm_private_dns_zone.acr.id
  log_analytics_workspace_id     = module.log_analytics.workspace_id
}
```
