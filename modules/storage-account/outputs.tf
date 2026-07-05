output "storage_account_id" {
  description = "Resource ID of the storage account (use as RBAC scope)."
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Name of the storage account."
  value       = azurerm_storage_account.this.name
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint URL."
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "container_names" {
  description = "Names of the containers created."
  value       = [for c in azurerm_storage_container.this : c.name]
}
