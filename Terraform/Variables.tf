# variables.tf

# Location for all resources
variable "location" {
  description = "Azure region to deploy resources into"
  type        = string
  default     = "East US"
}

# Admin username for all VMs
variable "admin_username" {
  description = "Admin username for virtual machines"
  type        = string
}

# Admin password for all VMs
variable "admin_password" {
  description = "Admin password for virtual machines"
  type        = string
  sensitive   = true
}

# Tags for resources
variable "resource_tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {
    environment = "production"
    project     = "costco-logistics-fulfillment"
  }
}
