output "vnet_id" {
  description = "ID of the virtual network."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Name of the virtual network."
  value       = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  description = "Map of subnet name to subnet ID."
  value       = { for k, s in azurerm_subnet.this : k => s.id }
}

output "default_nsg_id" {
  description = "ID of the deny-by-default NSG (null if disabled)."
  value       = try(azurerm_network_security_group.default[0].id, null)
}
