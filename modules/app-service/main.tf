# ------------------------------------------------------------------------------
# App Service (Linux) — secure-by-default
#   Copyright (c) 2026 G Vamseenath Reddy. Licensed under the MIT License.
#
#   - HTTPS-only, TLS 1.2 minimum, HTTP/2, FTP fully disabled
#   - System-assigned managed identity; secrets pulled via Key Vault references
#   - IP restrictions default to deny-all unless explicitly allowed
#   - Outbound VNet integration with all traffic routed through the VNet
#   - Basic-auth publishing credentials disabled (SCM and FTP)
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

resource "azurerm_service_plan" "this" {
  name                = "${var.name}-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.service_plan_sku
  tags                = var.tags

  # Survive a zone outage: spread instances across availability zones and
  # keep enough workers that losing one zone doesn't take the app down.
  zone_balancing_enabled = var.zone_balancing_enabled
  worker_count           = var.worker_count
}

resource "azurerm_linux_web_app" "this" {
  # checkov:skip=CKV_AZURE_222:public path is required for Azure Front Door (Standard); access is governed by deny-all IP restrictions + service tag allow-list
  # checkov:skip=CKV_AZURE_17:client certificates (mTLS) terminate at Front Door/App Gateway in this design
  # checkov:skip=CKV_AZURE_13:app-level authentication (auth_settings_v2 / Entra) is application-specific and configured per app
  # checkov:skip=CKV_AZURE_88:code/container deployments do not require an Azure Files mount
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.this.id
  tags                = var.tags

  # Transport security
  https_only                    = true
  client_certificate_enabled    = false
  public_network_access_enabled = true # governed by ip_restriction deny-all below

  # Disable basic-auth deployment credentials
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false

  identity {
    type = "SystemAssigned"
  }

  # Outbound traffic through the VNet when integrated
  virtual_network_subnet_id = var.vnet_integration_subnet_id
  vnet_route_all_enabled    = var.vnet_integration_subnet_id != null

  site_config {
    minimum_tls_version = "1.2"
    http2_enabled       = true
    ftps_state          = "Disabled"
    always_on           = true

    # Platform probes this path; unhealthy instances are pulled from rotation.
    health_check_path                 = var.health_check_path
    health_check_eviction_time_in_min = 5

    # Explicit allow-list; unmatched traffic is denied
    ip_restriction_default_action = "Deny"

    dynamic "ip_restriction" {
      for_each = { for r in var.allowed_ip_rules : r.name => r }
      content {
        name       = ip_restriction.value.name
        priority   = ip_restriction.value.priority
        action     = "Allow"
        ip_address = ip_restriction.value.cidr
      }
    }

    dynamic "ip_restriction" {
      for_each = { for r in var.allowed_service_tags : r.name => r }
      content {
        name        = ip_restriction.value.name
        priority    = ip_restriction.value.priority
        action      = "Allow"
        service_tag = ip_restriction.value.tag
      }
    }

    scm_ip_restriction_default_action = "Deny"
    scm_use_main_ip_restriction       = true

    application_stack {
      python_version = var.runtime.stack == "python" ? var.runtime.version : null
      node_version   = var.runtime.stack == "node" ? var.runtime.version : null
      dotnet_version = var.runtime.stack == "dotnet" ? var.runtime.version : null
      java_version   = var.runtime.stack == "java" ? var.runtime.version : null
    }
  }

  app_settings = var.app_settings

  logs {
    detailed_error_messages = true
    failed_request_tracing  = true
    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
  }

  lifecycle {
    ignore_changes = [app_settings["WEBSITE_RUN_FROM_PACKAGE"]]
  }
}

# Grant the app's identity read access to Key Vault secrets (RBAC model)
resource "azurerm_role_assignment" "kv_secrets_user" {
  count = var.key_vault_id != null ? 1 : 0

  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.this.identity[0].principal_id
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.name}-diag"
  target_resource_id         = azurerm_linux_web_app.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "AppServiceHTTPLogs" }
  enabled_log { category = "AppServiceAuditLogs" }
  enabled_log { category = "AppServiceIPSecAuditLogs" }

  metric { category = "AllMetrics" }
}
