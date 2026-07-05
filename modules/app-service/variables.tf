variable "name" {
  description = "Web app name (globally unique)."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for the app."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "service_plan_sku" {
  description = "App Service plan SKU (e.g. P1v3). Premium v3 recommended for VNet integration + zone redundancy."
  type        = string
  default     = "P1v3"
}

variable "runtime" {
  description = "Application runtime stack."
  type = object({
    stack   = string # one of: python | node | dotnet | java
    version = string # e.g. "3.12", "20-lts", "8.0", "17"
  })
  default = {
    stack   = "python"
    version = "3.12"
  }
}

variable "worker_count" {
  description = "Number of plan instances. Keep >= 2 (3 recommended with zone balancing) for failover."
  type        = number
  default     = 3
}

variable "zone_balancing_enabled" {
  description = "Spread plan instances across availability zones (requires Premium v2/v3 and worker_count >= number of zones)."
  type        = bool
  default     = true
}

variable "health_check_path" {
  description = "HTTP path the platform probes to decide instance health."
  type        = string
  default     = "/healthz"
}

variable "vnet_integration_subnet_id" {
  description = "Delegated subnet for outbound VNet integration. Null disables it."
  type        = string
  default     = null
}

variable "allowed_ip_rules" {
  description = "CIDRs allowed to reach the app. Empty list = deny all public (use with private endpoint or Front Door)."
  type = list(object({
    name     = string
    priority = number
    cidr     = string
  }))
  default = []
}

variable "allowed_service_tags" {
  description = "Azure service tags allowed to reach the app (e.g. AzureFrontDoor.Backend)."
  type = list(object({
    name     = string
    priority = number
    tag      = string
  }))
  default = []
}

variable "app_settings" {
  description = "Application settings. Use Key Vault references for secrets: @Microsoft.KeyVault(SecretUri=...)."
  type        = map(string)
  default     = {}
}

variable "key_vault_id" {
  description = "Key Vault ID to grant the app's managed identity Secrets User on. Null skips."
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  description = "Workspace for HTTP/audit logs. Null disables diagnostics."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
