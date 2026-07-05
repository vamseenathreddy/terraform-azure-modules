output "app_id" {
  description = "Web app resource ID."
  value       = azurerm_linux_web_app.this.id
}

output "default_hostname" {
  description = "Default *.azurewebsites.net hostname."
  value       = azurerm_linux_web_app.this.default_hostname
}

output "principal_id" {
  description = "Object ID of the system-assigned managed identity."
  value       = azurerm_linux_web_app.this.identity[0].principal_id
}
