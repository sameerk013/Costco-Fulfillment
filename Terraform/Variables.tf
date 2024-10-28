variable "location" {
  description = "Azure region for resource deployment"
  type        = string
  default     = "East US"
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Admin password for VMs"
  type        = string
}
