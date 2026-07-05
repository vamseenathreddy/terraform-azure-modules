# ------------------------------------------------------------------------------
# COMPLETE EXAMPLE — full secure platform stack
#   Copyright (c) 2026 G Vamseenath Reddy. Licensed under the MIT License.
#
# What gets built (in dependency order):
#   1. Resource group + Log Analytics workspace   -> central audit sink
#   2. VNet with 3 subnets + deny-by-default NSG  -> network foundation
#   3. Private DNS zones                          -> name resolution for private endpoints
#   4. Key Vault  (private endpoint, RBAC-only)   -> secrets
#   5. Storage    (private endpoint, no keys)     -> data
#   6. AKS        (private cluster, workload id)  -> compute
#   7. ACR        (AcrPull to AKS kubelet)        -> images, no pull secrets
#   8. App Service (locked to Front Door)         -> web tier
# ------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0, < 5.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Who am I? Used for tenant_id when creating the Key Vault.
data "azurerm_client_config" "current" {}

locals {
  location = "centralindia"
  tags = {
    env        = "prod"
    owner      = "platform-team"
    managed_by = "terraform"
  }
}

# --- 1. Foundation --------------------------------------------------------------

resource "azurerm_resource_group" "this" {
  name     = "rg-platform-prod"
  location = local.location
  tags     = local.tags
}

# Central log sink; every module below ships its audit logs here.
module "log_analytics" {
  source = "../../modules/log-analytics"

  name                = "log-platform-prod"
  resource_group_name = azurerm_resource_group.this.name
  location            = local.location
  tags                = local.tags
}

# --- 2. Network -------------------------------------------------------------------

module "vnet" {
  source = "../../modules/vnet"

  name                = "vnet-prod-centralindia"
  resource_group_name = azurerm_resource_group.this.name
  location            = local.location
  address_space       = ["10.20.0.0/16"]

  subnets = {
    # AKS nodes live here
    snet-aks = { address_prefixes = ["10.20.1.0/24"] }

    # All private endpoints (Key Vault, Storage, ACR) land in this subnet
    snet-pep = { address_prefixes = ["10.20.2.0/26"] }

    # App Service regional VNet integration requires a delegated subnet
    snet-appsvc = {
      address_prefixes = ["10.20.3.0/26"]
      delegation = {
        name    = "appsvc"
        service = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
  }

  # Only the Azure load balancer may initiate inbound 443; everything else
  # inbound is denied by the module's default NSG rule.
  allowed_inbound_rules = [{
    name                    = "allow-https-from-lb"
    priority                = 100
    protocol                = "Tcp"
    source_address_prefix   = "AzureLoadBalancer"
    destination_port_ranges = ["443"]
  }]

  tags = local.tags
}

# --- 3. Private DNS zones ----------------------------------------------------------
# One zone per service so private endpoints resolve to private IPs.

resource "azurerm_private_dns_zone" "kv" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

# Link each zone to the VNet so resources inside it use the private records.
resource "azurerm_private_dns_zone_virtual_network_link" "links" {
  for_each = {
    kv   = azurerm_private_dns_zone.kv.name
    blob = azurerm_private_dns_zone.blob.name
    acr  = azurerm_private_dns_zone.acr.name
  }

  name                  = "${each.key}-dns-link"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = each.value
  virtual_network_id    = module.vnet.vnet_id
}

# --- 4. Secrets ----------------------------------------------------------------------

module "key_vault" {
  source = "../../modules/key-vault"

  name                       = "kv-prod-platform01"
  resource_group_name        = azurerm_resource_group.this.name
  location                   = local.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  private_endpoint_subnet_id = module.vnet.subnet_ids["snet-pep"]
  private_dns_zone_id        = azurerm_private_dns_zone.kv.id
  log_analytics_workspace_id = module.log_analytics.workspace_id
  tags                       = local.tags
}

# --- 5. Data ---------------------------------------------------------------------------

module "storage" {
  source = "../../modules/storage-account"

  name                       = "stprodplatform01"
  resource_group_name        = azurerm_resource_group.this.name
  location                   = local.location
  containers                 = ["app-data", "backups"]
  private_endpoint_subnet_id = module.vnet.subnet_ids["snet-pep"]
  private_dns_zone_id        = azurerm_private_dns_zone.blob.id
  log_analytics_workspace_id = module.log_analytics.workspace_id
  tags                       = local.tags
}

# --- 6. Compute ---------------------------------------------------------------------------

module "aks" {
  source = "../../modules/aks"

  name                       = "aks-prod-01"
  resource_group_name        = azurerm_resource_group.this.name
  location                   = local.location
  subnet_id                  = module.vnet.subnet_ids["snet-aks"]
  admin_group_object_ids     = [] # TODO: add your Entra admin group object IDs
  log_analytics_workspace_id = module.log_analytics.workspace_id
  tags                       = local.tags
}

# --- 7. Images -------------------------------------------------------------------------------
# ACR grants AcrPull to the AKS kubelet identity: pods pull images with no
# imagePullSecrets and no stored registry credentials anywhere.

module "acr" {
  source = "../../modules/acr"

  name                           = "acrprodplatform01"
  resource_group_name            = azurerm_resource_group.this.name
  location                       = local.location
  aks_kubelet_identity_object_id = module.aks.kubelet_identity_object_id
  private_endpoint_subnet_id     = module.vnet.subnet_ids["snet-pep"]
  private_dns_zone_id            = azurerm_private_dns_zone.acr.id
  log_analytics_workspace_id     = module.log_analytics.workspace_id
  tags                           = local.tags
}

# --- 8. Web tier -------------------------------------------------------------------------------

module "app_service" {
  source = "../../modules/app-service"

  name                       = "app-orders-prod-01"
  resource_group_name        = azurerm_resource_group.this.name
  location                   = local.location
  vnet_integration_subnet_id = module.vnet.subnet_ids["snet-appsvc"]
  key_vault_id               = module.key_vault.key_vault_id
  log_analytics_workspace_id = module.log_analytics.workspace_id

  # Public traffic only via Azure Front Door; direct hits are denied.
  allowed_service_tags = [{
    name     = "allow-frontdoor"
    priority = 100
    tag      = "AzureFrontDoor.Backend"
  }]

  # Secrets come from Key Vault by reference — never plaintext in app settings.
  app_settings = {
    DB_PASSWORD = "@Microsoft.KeyVault(SecretUri=https://kv-prod-platform01.vault.azure.net/secrets/db-password/)"
  }

  tags = local.tags
}
