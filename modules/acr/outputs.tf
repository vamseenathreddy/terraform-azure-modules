output "acr_id" {
  description = "Registry resource ID (use as RBAC scope)."
  value       = azurerm_container_registry.this.id
}

output "login_server" {
  description = "Registry login server, e.g. myregistry.azurecr.io — use in image references."
  value       = azurerm_container_registry.this.login_server
}
