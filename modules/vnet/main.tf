# ------------------------------------------------------------------------------
# Virtual Network — secure-by-default
#   Copyright (c) 2026 G Vamseenath Reddy. Licensed under the MIT License.
#
#   - Deny-by-default NSG associated to every subnet (opt-out via variable)
#   - Private endpoint network policies enabled on all subnets
#   - Optional DDoS protection plan association
#   - Optional NSG flow logs with traffic analytics
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

resource "azurerm_virtual_network" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  dns_servers         = var.dns_servers
  tags                = var.tags

  dynamic "ddos_protection_plan" {
    for_each = var.enable_ddos_protection ? [1] : []
    content {
      id     = var.ddos_protection_plan_id
      enable = true
    }
  }
}

resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints

  # Keep NSG/UDR enforcement active on private endpoint subnets
  private_endpoint_network_policies = "Enabled"

  dynamic "delegation" {
    for_each = each.value.delegation != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service
        actions = delegation.value.actions
      }
    }
  }
}

# --- Deny-by-default NSG -------------------------------------------------------

resource "azurerm_network_security_group" "default" {
  count = var.create_default_nsg ? 1 : 0

  name                = "${var.name}-nsg-default"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # Explicit allow rules supplied by the caller
  dynamic "security_rule" {
    for_each = { for r in var.allowed_inbound_rules : r.name => r }
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = security_rule.value.protocol
      source_port_range          = "*"
      destination_port_ranges    = security_rule.value.destination_port_ranges
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }

  # Deny everything else inbound, below Azure default rules
  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = var.create_default_nsg ? azurerm_subnet.this : {}

  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.default[0].id
}

# --- NSG flow logs (optional) --------------------------------------------------

resource "azurerm_network_watcher_flow_log" "default" {
  count = var.create_default_nsg && var.flow_log_storage_account_id != null ? 1 : 0

  name                 = "${var.name}-nsg-flowlog"
  network_watcher_name = var.network_watcher_name
  resource_group_name  = var.network_watcher_resource_group_name
  target_resource_id   = azurerm_network_security_group.default[0].id
  storage_account_id   = var.flow_log_storage_account_id
  enabled              = true
  version              = 2

  retention_policy {
    enabled = true
    days    = 90
  }

  tags = var.tags
}
