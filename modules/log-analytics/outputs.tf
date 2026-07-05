output "workspace_id" {
  description = "Workspace resource ID — pass to every other module's log_analytics_workspace_id."
  value       = azurerm_log_analytics_workspace.this.id
}

output "workspace_customer_id" {
  description = "Workspace (customer) GUID used by agents."
  value       = azurerm_log_analytics_workspace.this.workspace_id
}
