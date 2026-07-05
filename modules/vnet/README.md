# vnet

Secure-by-default Azure Virtual Network module.

## Security features

- Deny-by-default NSG automatically associated with every subnet; inbound
  traffic must be explicitly allowed via `allowed_inbound_rules`.
- `private_endpoint_network_policies = Enabled` on all subnets so NSG and
  route enforcement applies to private endpoints.
- Optional DDoS protection plan association.
- Optional NSG flow logs (v2, 90-day retention).

## Usage

```hcl
module "vnet" {
  source = "github.com/vamseenathreddy/terraform-azure-modules//modules/vnet"

  name                = "vnet-prod-centralindia"
  resource_group_name = azurerm_resource_group.net.name
  location            = "centralindia"
  address_space       = ["10.20.0.0/16"]

  subnets = {
    snet-aks = { address_prefixes = ["10.20.1.0/24"] }
    snet-pep = { address_prefixes = ["10.20.2.0/26"] }
  }

  allowed_inbound_rules = [{
    name                    = "allow-https-from-lb"
    priority                = 100
    protocol                = "Tcp"
    source_address_prefix   = "AzureLoadBalancer"
    destination_port_ranges = ["443"]
  }]

  tags = { env = "prod", owner = "platform" }
}
```
