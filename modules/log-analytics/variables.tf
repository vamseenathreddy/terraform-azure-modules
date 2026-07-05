# ------------------------------------------------------------------------------
# INPUT VARIABLES — log-analytics module
# The observability foundation every other module ships its logs to.
# ------------------------------------------------------------------------------

variable "name" {
  description = "Log Analytics workspace name."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for the workspace."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "retention_in_days" {
  description = "How long to keep logs (30-730). 90+ recommended for security investigations."
  type        = number
  default     = 90
}

variable "daily_quota_gb" {
  description = "Daily ingestion cap in GB to protect against runaway cost. -1 = unlimited."
  type        = number
  default     = 10
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
