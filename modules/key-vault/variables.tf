variable "name" {
  description = "Key Vault name (globally unique, 3-24 alphanumeric)."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,24}$", var.name))
    error_message = "Key Vault name must be 3-24 characters, alphanumeric and hyphens."
  }
}

variable "resource_group_name" {
  description = "Resource group for the vault."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "tenant_id" {
  description = "Entra ID tenant ID."
  type        = string
}

variable "sku_name" {
  description = "Vault SKU: standard or premium (premium = HSM-backed keys)."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "sku_name must be standard or premium."
  }
}

variable "allowed_subnet_ids" {
  description = "Subnet IDs allowed through the vault firewall."
  type        = list(string)
  default     = []
}

variable "allowed_ip_rules" {
  description = "Public CIDRs allowed through the vault firewall (keep empty for private-only)."
  type        = list(string)
  default     = []
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID in which to create a private endpoint. Null disables it."
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "privatelink.vaultcore.azure.net DNS zone ID for the private endpoint."
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  description = "Workspace for audit logging. Null disables diagnostics."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
