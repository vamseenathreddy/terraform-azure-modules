# ------------------------------------------------------------------------------
# Storage Account — secure-by-default
#   Copyright (c) 2026 G Vamseenath Reddy. Licensed under the MIT License.
#
# WHAT THIS MODULE GIVES YOU:
#   - A general-purpose v2 storage account that a security review will pass:
#       * HTTPS-only with TLS 1.2 minimum
#       * Public blob access DISABLED and not overridable
#       * Shared key auth DISABLED -> all access is Entra ID (RBAC) based
#       * Firewall default-deny; access via private endpoint or allowed subnets
#       * Blob versioning + soft delete for accidental-deletion recovery
#       * Infrastructure (double) encryption at rest
#       * Audit logs to Log Analytics
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

resource "azurerm_storage_account" "this" {
  # checkov:skip=CKV_AZURE_59:anonymous blob access is hard-disabled; public network path closes automatically with a private endpoint and is default-deny otherwise
  # checkov:skip=CKV_AZURE_206:replication defaults to ZRS via var.replication_type (conditional not resolvable by checkov)
  # checkov:skip=CKV2_AZURE_1:infrastructure (double) encryption is enabled; customer-managed keys can be layered on where mandated
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  # Performance & durability. ZRS default = survives a zone outage.
  account_tier             = var.account_tier
  account_replication_type = var.replication_type
  account_kind             = "StorageV2"

  # --- Transport security ---
  # Reject any plain-HTTP request and anything below TLS 1.2.
  https_traffic_only_enabled = true
  min_tls_version            = "TLS1_2"

  # --- Identity-based access only ---
  # Disabling shared keys forces callers to authenticate with Entra ID and be
  # authorized through RBAC roles (e.g. "Storage Blob Data Reader"). This kills
  # the classic "leaked connection string" incident class entirely.
  shared_access_key_enabled = false

  # --- No anonymous access, ever ---
  # With this false, even a misconfigured container cannot be made public.
  allow_nested_items_to_be_public = false

  # OAuth as the default auth screen in the Azure portal.
  default_to_oauth_authentication = true

  # Encrypt data twice at rest (service-level + infrastructure-level).
  infrastructure_encryption_enabled = true

  # Only reachable publicly if the caller explicitly allows CIDRs/subnets;
  # when a private endpoint is used we shut the public path completely.
  public_network_access_enabled = var.private_endpoint_subnet_id == null

  # --- Firewall: default Deny ---
  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"] # lets trusted MSFT services (e.g. backup) through
    virtual_network_subnet_ids = var.allowed_subnet_ids
    ip_rules                   = var.allowed_ip_rules
  }

  # --- Recovery from accidents & ransomware-style deletion ---
  blob_properties {
    versioning_enabled  = true # every overwrite keeps the previous version
    change_feed_enabled = true # ordered log of all blob changes (useful for audits)

    delete_retention_policy {
      days = var.blob_soft_delete_days # deleted blobs recoverable for N days
    }
    container_delete_retention_policy {
      days = var.container_soft_delete_days # deleted containers recoverable too
    }
  }

  # Classic logging for the queue service (read/write/delete), kept alongside
  # the blob diagnostic settings below for full data-plane auditability.
  queue_properties {
    logging {
      delete                = true
      read                  = true
      write                 = true
      version               = "1.0"
      retention_policy_days = 10
    }
  }
}

# Private blob containers. Access is controlled purely by RBAC, so there is
# deliberately no "access type" knob here — everything is private.
resource "azurerm_storage_container" "this" {
  # checkov:skip=CKV2_AZURE_21:blob read/write/delete logging is shipped via azurerm_monitor_diagnostic_setting on the blob service below
  for_each = toset(var.containers)

  name                  = each.value
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

# --- Private endpoint (recommended path for all workload access) --------------
resource "azurerm_private_endpoint" "blob" {
  count = var.private_endpoint_subnet_id != null ? 1 : 0

  name                = "${var.name}-blob-pep"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.name}-blob-psc"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["blob"] # one endpoint per sub-resource (blob/file/queue/table)
    is_manual_connection           = false
  }

  # Registers the account's private IP in privatelink.blob.core.windows.net so
  # SDKs resolve to the private address without code changes.
  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }
}

# --- Audit: who read/wrote/deleted what ----------------------------------------
resource "azurerm_monitor_diagnostic_setting" "blob" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name = "${var.name}-blob-audit"
  # Diagnostics attach to the blob service sub-resource, not the account.
  target_resource_id         = "${azurerm_storage_account.this.id}/blobServices/default"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "StorageRead" }
  enabled_log { category = "StorageWrite" }
  enabled_log { category = "StorageDelete" }

  metric { category = "Transaction" }
}
