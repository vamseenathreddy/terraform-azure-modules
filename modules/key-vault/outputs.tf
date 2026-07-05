output "key_vault_id" {
  description = "Key Vault resource ID."
  value       = azurerm_key_vault.this.id
}

output "key_vault_uri" {
  description = "Vault URI for SDK/CSI access."
  value       = azurerm_key_vault.this.vault_uri
}

output "private_endpoint_ip" {
  description = "Private endpoint IP address (null if not created)."
  value       = try(azurerm_private_endpoint.this[0].private_service_connection[0].private_ip_address, null)
}
