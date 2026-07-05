variable "name" {
  description = "Name of the AKS cluster."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for the cluster."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version. Leave null for latest supported default."
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "Subnet ID for the default node pool (from the vnet module)."
  type        = string
}

variable "private_cluster_enabled" {
  description = "Run the API server behind a private endpoint. Strongly recommended."
  type        = bool
  default     = true
}

variable "admin_group_object_ids" {
  description = "Entra ID (Azure AD) group object IDs granted cluster-admin via Azure RBAC."
  type        = list(string)
  default     = []
}

variable "authorized_ip_ranges" {
  description = "CIDRs allowed to reach the API server when the cluster is NOT private."
  type        = list(string)
  default     = []
}

variable "default_node_pool" {
  description = "Default (system) node pool settings."
  type = object({
    vm_size   = optional(string, "Standard_D4ds_v5")
    min_count = optional(number, 2)
    max_count = optional(number, 5)
    os_sku    = optional(string, "AzureLinux")
    max_pods  = optional(number, 50)
    zones     = optional(list(string), ["1", "2", "3"])
  })
  default = {}
}

variable "disk_encryption_set_id" {
  description = "Optional Disk Encryption Set ID for customer-managed key encryption of node disks."
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace for control-plane diagnostics and Defender."
  type        = string
  default     = null
}

variable "enable_defender" {
  description = "Enable Microsoft Defender for Containers."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
