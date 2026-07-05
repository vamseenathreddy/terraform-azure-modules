variable "name" {
  description = "Name of the virtual network."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group in which to create the VNet."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "address_space" {
  description = "CIDR ranges for the virtual network."
  type        = list(string)
}

variable "dns_servers" {
  description = "Optional custom DNS servers."
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = <<-EOT
    Map of subnets to create. Key is the subnet name.
    service_endpoints and delegation are optional.
    private_endpoint_network_policies defaults to Enabled for security.
  EOT
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])
    delegation = optional(object({
      name    = string
      service = string
      actions = list(string)
    }))
  }))
}

variable "create_default_nsg" {
  description = "Create and associate a deny-by-default NSG on every subnet."
  type        = bool
  default     = true
}

variable "allowed_inbound_rules" {
  description = "Explicit inbound allow rules applied to the default NSG. Everything else is denied."
  type = list(object({
    name                       = string
    priority                   = number
    protocol                   = string
    source_address_prefix      = string
    destination_port_ranges    = list(string)
    destination_address_prefix = optional(string, "*")
  }))
  default = []
}

variable "enable_ddos_protection" {
  description = "Associate a DDoS protection plan with the VNet."
  type        = bool
  default     = false
}

variable "ddos_protection_plan_id" {
  description = "Existing DDoS protection plan ID (required if enable_ddos_protection = true)."
  type        = string
  default     = null
}

variable "flow_log_storage_account_id" {
  description = "Storage account ID for NSG flow logs. Set to enable flow logging."
  type        = string
  default     = null
}

variable "network_watcher_name" {
  description = "Network Watcher name (required when flow logs are enabled)."
  type        = string
  default     = null
}

variable "network_watcher_resource_group_name" {
  description = "Network Watcher resource group (required when flow logs are enabled)."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
