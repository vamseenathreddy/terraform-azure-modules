# ------------------------------------------------------------------------------
# INPUT VARIABLES — storage-account module
# Every variable has a description; secure options are defaulted ON and the
# truly dangerous ones (public blob access, shared keys) are not exposed at all.
# ------------------------------------------------------------------------------

variable "name" {
  description = "Storage account name (3-24 chars, lowercase letters and numbers only, globally unique)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "Storage account name must be 3-24 lowercase alphanumeric characters."
  }
}

variable "resource_group_name" {
  description = "Resource group in which to create the storage account."
  type        = string
}

variable "location" {
  description = "Azure region, e.g. centralindia."
  type        = string
}

variable "account_tier" {
  description = "Performance tier: Standard (HDD-backed) or Premium (SSD-backed)."
  type        = string
  default     = "Standard"
}

variable "replication_type" {
  description = "Replication: LRS (single zone), ZRS (zonal), GRS/GZRS (geo). Use ZRS+ for production."
  type        = string
  default     = "ZRS"
}

variable "containers" {
  description = "Blob containers to create. All containers are private; public access is impossible in this module."
  type        = list(string)
  default     = []
}

variable "allowed_subnet_ids" {
  description = "Subnet IDs allowed through the storage firewall (via service endpoints)."
  type        = list(string)
  default     = []
}

variable "allowed_ip_rules" {
  description = "Public CIDRs allowed through the firewall. Keep empty for private-only access."
  type        = list(string)
  default     = []
}

variable "private_endpoint_subnet_id" {
  description = "Subnet in which to create a blob private endpoint. Null disables it."
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "ID of the privatelink.blob.core.windows.net DNS zone, required for private endpoint name resolution."
  type        = string
  default     = null
}

variable "blob_soft_delete_days" {
  description = "How long deleted blobs are recoverable. 1-365 days."
  type        = number
  default     = 30
}

variable "container_soft_delete_days" {
  description = "How long deleted containers are recoverable. 1-365 days."
  type        = number
  default     = 30
}

variable "log_analytics_workspace_id" {
  description = "Workspace to receive read/write/delete audit logs. Null disables diagnostics."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
