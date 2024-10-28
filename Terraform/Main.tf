# Terraform Block
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.0" 
    }
    random = {
      source = "hashicorp/random"
      version = ">= 3.0"
    }
    null = {
      source = "hashicorp/null"
      version = ">= 3.0"
    }    
  }
}

# Provider Block
provider "azurerm" {
  subscription_id = "27bc640c-c9a8-4e69-829d-a9814bec414f"
 features {}          
}



# Resource Group
resource "azurerm_resource_group" "costco-fulfillment_rg" {
  name     = "costco-fulfillment-resource-group"
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "costco-fulfillment-vnet"
  resource_group_name = azurerm_resource_group.costco-fulfillment_rg.name
  location            = azurerm_resource_group.costco-fulfillment_rg.location
  address_space       = ["10.0.0.0/16"]
}

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "costco-fulfillment-subnet"
  resource_group_name  = azurerm_resource_group.costco-fulfillment_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

# Network Security Group (Optional - Allow SSH and HTTP)
resource "azurerm_network_security_group" "nsg" {
  name                = "costco-fulfillment-nsg"
  location            = azurerm_resource_group.costco-fulfillment_rg.location
  resource_group_name = azurerm_resource_group.costco-fulfillment_rg.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Network Interfaces for VMs with Dynamically Generated Static Private IPs
resource "azurerm_network_interface" "nic" {
  count               = 5
  name                = "costco-fulfillment-nic-${count.index + 1}"
  location            = azurerm_resource_group.costco-fulfillment_rg.location
  resource_group_name = azurerm_resource_group.costco-fulfillment_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address            = cidrsubnet(azurerm_subnet.subnet.address_prefixes[0], 8, count.index + 5) # Generates IPs like 10.0.0.5, 10.0.0.6, etc.
    private_ip_address_allocation = "Static"
  }
}

# Virtual Machines
resource "azurerm_linux_virtual_machine" "vm" {
  count               = 5
  name                = "costco-fulfillment-vm-${count.index + 1}"
  location            = azurerm_resource_group.costco-fulfillment_rg.location
  resource_group_name = azurerm_resource_group.costco-fulfillment_rg.name
  size                = "Standard_B1s"

  admin_username      = var.admin_username
  admin_password      = var.admin_password
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.nic[count.index].id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

# Output for VM Private IPs
output "vm_private_ips" {
  value       = [for nic in azurerm_network_interface.nic : nic.ip_configuration.0.private_ip_address]
  description = "List of private IPs for the VMs"
}

# Generate Ansible Inventory File
resource "null_resource" "ansible_inventory" {
  provisioner "local-exec" {
    command = <<EOT
      echo "[frontend]" > ../ansible/ansible_inventory
      echo "${azurerm_network_interface.nic[0].ip_configuration.0.private_ip_address} ansible_user=${var.admin_username} ansible_password=${var.admin_password}" >> ../ansible/inventory
      echo "${azurerm_network_interface.nic[1].ip_configuration.0.private_ip_address} ansible_user=${var.admin_username} ansible_password=${var.admin_password}" >> ../ansible/inventory
      echo "${azurerm_network_interface.nic[2].ip_configuration.0.private_ip_address} ansible_user=${var.admin_username} ansible_password=${var.admin_password}" >> ../ansible/inventory
      
      echo "[loadbalancer]" >> ../ansible/inventory
      echo "${azurerm_network_interface.nic[3].ip_configuration.0.private_ip_address} ansible_user=${var.admin_username} ansible_password=${var.admin_password}" >> ../ansible/inventory

      echo "[database]" >> ../ansible/inventory
      echo "${azurerm_network_interface.nic[4].ip_configuration.0.private_ip_address} ansible_user=${var.admin_username} ansible_password=${var.admin_password}" >> ../ansible/inventory
    EOT
  }

  depends_on = [azurerm_linux_virtual_machine.vm]
}
