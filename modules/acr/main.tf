# ------------------------------------------------------------------------------
# Azure Container Registry — secure-by-default
#   Copyright (c) 2026 G Vamseenath Reddy. Licensed under the MIT License.
#
# WHAT THIS MODULE GIVES YOU:
#   - A registry AKS can pull from with NO stored credentials:
#       * Admin account (username/password) DISABLED
#       * Anonymous pull DISABLED
#       * AcrPull granted to the AKS kubelet managed identity
#       * Private endpoint + public access off (Premium)
#       * Untagged-manifest retention policy to control image sprawl
#       * Audit logs (who pushed/pulled what) to Log Analytics
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

resource "azurerm_container_registry" "this" {
  # checkov:skip=CKV_AZURE_139:public access is disabled automatically whenever a private endpoint subnet is supplied (conditional not resolvable by checkov)
  # checkov:skip=CKV_AZURE_233:zone_redundancy_enabled is on for Premium SKU (conditional not resolvable by checkov)
  # checkov:skip=CKV_AZURE_164:trust_policy_enabled is on for Premium SKU (conditional not resolvable by checkov)
  # checkov:skip=CKV_AZURE_165:geo-replication is exposed via var.georeplication_locations for multi-region deployments
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  tags                = var.tags

  # The admin account is a single shared username/password — the exact kind of
  # credential that ends up in a CI variable and leaks. Keep it off; use
  # managed identities and RBAC instead.
  admin_enabled = false

  # Nobody should be able to pull images without authenticating.
  anonymous_pull_enabled = false

  # Close the public endpoint whenever a private endpoint is in use.
  public_network_access_enabled = var.private_endpoint_subnet_id == null

  # Premium-only hardening below. Each of these requires the Premium SKU and
  # is switched off automatically on lower SKUs.

  # Clean up untagged manifests automatically to control image sprawl.
  retention_policy_in_days = var.sku == "Premium" ? var.retention_days : null

  # Only signed (content-trusted) images can be pushed/pulled.
  trust_policy_enabled = var.sku == "Premium"

  # New images land in quarantine until scanned & marked verified.
  quarantine_policy_enabled = var.sku == "Premium"

  # Dedicated data endpoints allow precise firewall rules for data-plane traffic.
  data_endpoint_enabled = var.sku == "Premium"

  # Zone redundancy for regional resilience.
  zone_redundancy_enabled = var.sku == "Premium"

  # Optional geo-replication for multi-region image pulls (Premium).
  dynamic "georeplications" {
    for_each = var.sku == "Premium" ? var.georeplication_locations : []
    content {
      location                = georeplications.value
      zone_redundancy_enabled = true
    }
  }
}

# --- Let AKS nodes pull images with their managed identity ---------------------
# This single role assignment replaces imagePullSecrets entirely: the kubelet
# identity authenticates to ACR via Entra ID, so no secret ever exists.
resource "azurerm_role_assignment" "aks_acrpull" {
  count = var.aks_kubelet_identity_object_id != null ? 1 : 0

  scope                            = azurerm_container_registry.this.id
  role_definition_name             = "AcrPull"
  principal_id                     = var.aks_kubelet_identity_object_id
  skip_service_principal_aad_check = true
}

# --- Private endpoint (Premium) -------------------------------------------------
resource "azurerm_private_endpoint" "this" {
  count = var.private_endpoint_subnet_id != null ? 1 : 0

  name                = "${var.name}-pep"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = azurerm_container_registry.this.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }
}

# --- Audit logging ---------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.name}-audit"
  target_resource_id         = azurerm_container_registry.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "ContainerRegistryLoginEvents" }      # who authenticated
  enabled_log { category = "ContainerRegistryRepositoryEvents" } # push/pull/delete

  metric { category = "AllMetrics" }
}
