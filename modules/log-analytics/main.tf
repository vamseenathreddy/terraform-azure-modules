# ------------------------------------------------------------------------------
# Log Analytics Workspace — the audit & observability sink
#   Copyright (c) 2026 G Vamseenath Reddy. Licensed under the MIT License.
#
# Every other module in this repo accepts a log_analytics_workspace_id and
# ships its diagnostic/audit logs here. Centralizing logs means:
#   - one place to query during an incident (KQL across all resources)
#   - retention is enforced consistently
#   - a daily quota caps surprise ingestion bills
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

resource "azurerm_log_analytics_workspace" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  sku               = "PerGB2018"          # standard pay-as-you-go pricing tier
  retention_in_days = var.retention_in_days

  # Cost guardrail: cap daily ingestion so a misconfigured debug logger
  # cannot generate an unbounded bill.
  daily_quota_gb = var.daily_quota_gb

  # Require Entra ID auth for workspace queries (no workspace shared keys).
  local_authentication_enabled = false

  # Access to logs is governed by RBAC on the resources that sent them,
  # not just workspace-level permissions.
  allow_resource_only_permissions = true
}
