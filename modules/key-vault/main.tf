# ------------------------------------------------------------------------------
# Key Vault — secure-by-default
#   Copyright (c) 2026 G Vamseenath Reddy. Licensed under the MIT License.
#
#   - RBAC authorization (no legacy access policies)
#   - Purge protection + 90-day soft delete (non-negotiable defaults)
#   - Network ACLs: default Deny; access via private endpoint / allowed subnets
#   - Public network access disabled when a private endpoint is used
#   - Full audit logging to Log Analytics
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

resource "azurerm_key_vault" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  sku_name            = var.sku_name
  tags                = var.tags

  # Identity-based access only
  enable_rbac_authorization = true

  # Deletion safety — deliberately not exposed as variables
  purge_protection_enabled   = true
  soft_delete_retention_days = 90

  # Platform integrations
  enabled_for_deployment          = false
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = false

  # Private-only when a private endpoint is configured
  public_network_access_enabled = var.private_endpoint_subnet_id == null

  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = var.allowed_subnet_ids
    ip_rules                   = var.allowed_ip_rules
  }
}

# --- Private endpoint (recommended) --------------------------------------------

resource "azurerm_private_endpoint" "this" {
  count = var.private_endpoint_subnet_id != null ? 1 : 0

  name                = "${var.name}-pep"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
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

# --- Audit logging --------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "audit" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.name}-audit"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "AuditEvent" }
  enabled_log { category = "AzurePolicyEvaluationDetails" }

  metric { category = "AllMetrics" }
}
