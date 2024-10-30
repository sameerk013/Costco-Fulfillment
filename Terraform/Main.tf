# Terraform Block
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
    null = {
      source  = "hashicorp/null"
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
resource "azurerm_resource_group" "costco_fulfillment_rg" {
  name     = "costco-fulfillment-resource-group"
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "costco-fulfillment-vnet"
  resource_group_name = azurerm_resource_group.costco_fulfillment_rg.name
  location            = azurerm_resource_group.costco_fulfillment_rg.location
  address_space       = ["10.0.0.0/16"]
}

# Network Security Group (Allow SSH and HTTP)
resource "azurerm_network_security_group" "nsg" {
  name                = "costco-fulfillment-nsg"
  location            = azurerm_resource_group.costco_fulfillment_rg.location
  resource_group_name = azurerm_resource_group.costco_fulfillment_rg.name

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

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "costco-fulfillment-subnet"
  resource_group_name  = azurerm_resource_group.costco_fulfillment_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

# NSG Association with Subnet
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Public IPs for each VM
resource "azurerm_public_ip" "public_ip" {
  count               = 5
  name                = "costco-fulfillment-public-ip-${count.index + 1}"
  location            = azurerm_resource_group.costco_fulfillment_rg.location
  resource_group_name = azurerm_resource_group.costco_fulfillment_rg.name
  allocation_method   = "Static"
}

# Network Interfaces with Public IPs for each VM
resource "azurerm_network_interface" "nic" {
  count               = 5
  name                = "costco-fulfillment-nic-${count.index + 1}"
  location            = azurerm_resource_group.costco_fulfillment_rg.location
  resource_group_name = azurerm_resource_group.costco_fulfillment_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip[count.index].id  # Attach public IP
  }
}

# Virtual Machines with Python Installation
resource "azurerm_linux_virtual_machine" "vm" {
  count               = 5
  name                = "costco-fulfillment-vm-${count.index + 1}"
  location            = azurerm_resource_group.costco_fulfillment_rg.location
  resource_group_name = azurerm_resource_group.costco_fulfillment_rg.name
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

  # Provisioner to install Python 3.10 on each VM
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y software-properties-common",
      "sudo add-apt-repository -y ppa:deadsnakes/ppa",
      "sudo apt-get update -y",
      "sudo apt-get install -y python3.10",
      "sudo ln -sf /usr/bin/python3.10 /usr/bin/python3"
    ]

    connection {
      type        = "ssh"
      user        = var.admin_username
      password    = var.admin_password
      host        = azurerm_public_ip.public_ip[count.index].ip_address
    }
  }
}

# Output for VM Public IPs
output "vm_public_ips" {
  value       = [for pip in azurerm_public_ip.public_ip : pip.ip_address]
  description = "List of public IPs for the VMs"
}

# Generate Ansible Inventory File
resource "null_resource" "ansible_inventory" {
  provisioner "local-exec" {
    command = <<EOT
      echo "[frontend]" > ../ansible/ansible_inventory
      echo "${azurerm_public_ip.public_ip[0].ip_address} ansible_user=${var.admin_username} ansible_password=${var.admin_password}" >> ../ansible/ansible_inventory
      echo "${azurerm_public_ip.public_ip[1].ip_address} ansible_user=${var.admin_username} ansible_password=${var.admin_password}" >> ../ansible/ansible_inventory
      echo "${azurerm_public_ip.public_ip[2].ip_address} ansible_user=${var.admin_username} ansible_password=${var.admin_password}" >> ../ansible/ansible_inventory

      echo "[loadbalancer]" >> ../ansible/ansible_inventory
      echo "${azurerm_public_ip.public_ip[3].ip_address} ansible_user=${var.admin_username} ansible_password=${var.admin_password}" >> ../ansible/ansible_inventory

      echo "[database]" >> ../ansible/ansible_inventory
      echo "${azurerm_public_ip.public_ip[4].ip_address} ansible_user=${var.admin_username} ansible_password=${var.admin_password}" >> ../ansible/ansible_inventory
    EOT
  }

  depends_on = [azurerm_linux_virtual_machine.vm]
}
