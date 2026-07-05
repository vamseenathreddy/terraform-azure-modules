# ------------------------------------------------------------------------------
# INPUT VARIABLES — acr (Azure Container Registry) module
# ------------------------------------------------------------------------------

variable "name" {
  description = "Registry name (5-50 alphanumeric, globally unique)."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{5,50}$", var.name))
    error_message = "ACR name must be 5-50 alphanumeric characters."
  }
}

variable "resource_group_name" {
  description = "Resource group for the registry."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "sku" {
  description = "Registry SKU. Premium is required for private endpoints, network rules, and geo-replication."
  type        = string
  default     = "Premium"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be Basic, Standard, or Premium."
  }
}

variable "private_endpoint_subnet_id" {
  description = "Subnet for the registry private endpoint (Premium only). Null disables it."
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "privatelink.azurecr.io DNS zone ID for the private endpoint."
  type        = string
  default     = null
}

variable "aks_kubelet_identity_object_id" {
  description = "Kubelet identity object ID from the aks module; gets AcrPull so nodes can pull images without credentials."
  type        = string
  default     = null
}

variable "retention_days" {
  description = "Days to retain untagged manifests before automatic cleanup (Premium only)."
  type        = number
  default     = 14
}

variable "georeplication_locations" {
  description = "Additional Azure regions to replicate the registry to (Premium only)."
  type        = list(string)
  default     = []
}

variable "log_analytics_workspace_id" {
  description = "Workspace for login/pull/push audit events. Null disables diagnostics."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
