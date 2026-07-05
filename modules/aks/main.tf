# ------------------------------------------------------------------------------
# AKS — secure-by-default private cluster
#   Copyright (c) 2026 G Vamseenath Reddy. Licensed under the MIT License.
#
#   - Private API server (default) or authorized IP ranges only
#   - Entra ID authentication + Azure RBAC, local accounts disabled
#   - Workload identity + OIDC issuer enabled (no node-level secrets)
#   - Azure CNI overlay + Cilium network policy
#   - Encryption at host, ephemeral OS disks, Azure Key Vault KMS ready
#   - Microsoft Defender for Containers + control-plane diagnostics
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

resource "azurerm_user_assigned_identity" "cluster" {
  name                = "${var.name}-identity"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_kubernetes_cluster" "this" {
  # checkov:skip=CKV_AZURE_117:disk_encryption_set_id is exposed as an optional input; platform-managed keys are acceptable here
  # checkov:skip=CKV_AZURE_168:max_pods defaults to 50 via var.default_node_pool (checkov cannot resolve optional() defaults)
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.name
  kubernetes_version  = var.kubernetes_version

  # Standard tier = financially-backed uptime SLA for the API server.
  sku_tier = "Standard"
  tags     = var.tags

  # --- API server exposure ---
  private_cluster_enabled = var.private_cluster_enabled

  dynamic "api_server_access_profile" {
    for_each = var.private_cluster_enabled ? [] : [1]
    content {
      authorized_ip_ranges = var.authorized_ip_ranges
    }
  }

  # --- Identity & auth: Entra ID + Azure RBAC, no local accounts ---
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.cluster.id]
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true
    admin_group_object_ids = var.admin_group_object_ids
  }

  local_account_disabled            = true
  role_based_access_control_enabled = true

  # Enforce org guardrails (e.g. "no privileged pods") at admission time.
  azure_policy_enabled = true

  # Optional customer-managed key encryption for node OS/data disks.
  disk_encryption_set_id = var.disk_encryption_set_id

  # --- Workload identity: pods authenticate via federated credentials ---
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # --- Networking: CNI overlay with Cilium dataplane & network policy ---
  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "cilium"
    network_data_plane  = "cilium"
    outbound_type       = "loadBalancer"
  }

  default_node_pool {
    name                 = "system"
    vm_size              = var.default_node_pool.vm_size
    vnet_subnet_id       = var.subnet_id
    auto_scaling_enabled = true
    min_count            = var.default_node_pool.min_count
    max_count            = var.default_node_pool.max_count
    max_pods             = var.default_node_pool.max_pods
    os_sku               = var.default_node_pool.os_sku
    zones                = var.default_node_pool.zones

    # Ephemeral OS disks live on the VM's local storage: faster, and node OS
    # data never persists to remote storage (requires a VM size with a local
    # disk, hence the D4ds_v5 default).
    os_disk_type = "Ephemeral"

    # Hardening
    host_encryption_enabled      = true
    only_critical_addons_enabled = true

    upgrade_settings {
      max_surge = "33%"
    }
  }

  # --- Threat protection & observability ---
  dynamic "microsoft_defender" {
    for_each = var.enable_defender && var.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "01:00"
    utc_offset  = "+05:30"
  }

  automatic_upgrade_channel = "patch"
  node_os_upgrade_channel   = "NodeImage"

  lifecycle {
    ignore_changes = [kubernetes_version]
  }
}

# Control-plane audit & diagnostic logs
resource "azurerm_monitor_diagnostic_setting" "control_plane" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.name}-diag"
  target_resource_id         = azurerm_kubernetes_cluster.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "kube-audit-admin" }
  enabled_log { category = "kube-apiserver" }
  enabled_log { category = "kube-controller-manager" }
  enabled_log { category = "guard" }

  metric { category = "AllMetrics" }
}
