#Main Configuration file for Webapp


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
resource "azurerm_resource_group" "costco_logistics_fulfillment_rg" {
  name     = "costco-logistics-fulfillment-resource-group"
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "costco-logistics-fulfillment-vnet"
  resource_group_name = azurerm_resource_group.costco_logistics_fulfillment_rg.name
  location            = azurerm_resource_group.costco_logistics_fulfillment_rg.location
  address_space       = ["10.0.0.0/16"]
}

# Subnets
resource "azurerm_subnet" "public_subnet" {
  name                 = "costco-logistics-fulfillment-public-subnet"
  resource_group_name  = azurerm_resource_group.costco_logistics_fulfillment_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "frontend_subnet" {
  name                 = "costco-logistics-fulfillment-frontend-subnet"
  resource_group_name  = azurerm_resource_group.costco_logistics_fulfillment_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "database_subnet" {
  name                 = "costco-logistics-fulfillment-database-subnet"
  resource_group_name  = azurerm_resource_group.costco_logistics_fulfillment_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Public NSG
resource "azurerm_network_security_group" "public_nsg" {
  name                = "costco-logistics-fulfillment-public-nsg"
  location            = azurerm_resource_group.costco_logistics_fulfillment_rg.location
  resource_group_name = azurerm_resource_group.costco_logistics_fulfillment_rg.name

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # SSH Rule to test Ansible (NP and DEV Only, Not Best Practice)
  security_rule {
    name                       = "AllowSSHForAnsible"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"  
    destination_address_prefix = "*"
  }
}

# Frontend NSG
resource "azurerm_network_security_group" "frontend_nsg" {
  name                = "costco-logistics-fulfillment-frontend-nsg"
  location            = azurerm_resource_group.costco_logistics_fulfillment_rg.location
  resource_group_name = azurerm_resource_group.costco_logistics_fulfillment_rg.name

  security_rule {
    name                       = "AllowLoadBalancer"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "10.0.1.0/24"  
    destination_address_prefix = "*"
  }

  # SSH Rule for Ansible (NP and DEV Only, Not Best Practice)
  security_rule {
    name                       = "AllowSSHForAnsible"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"  
    destination_address_prefix = "*"
  }
}

# Database NSG
resource "azurerm_network_security_group" "database_nsg" {
  name                = "costco-logistics-fulfillment-database-nsg"
  location            = azurerm_resource_group.costco_logistics_fulfillment_rg.location
  resource_group_name = azurerm_resource_group.costco_logistics_fulfillment_rg.name

  security_rule {
    name                       = "AllowFrontend"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "10.0.2.0/24"  
    destination_address_prefix = "*"
  }

  # SSH Rule for Ansible (NP and DEV Only, Not Best Practice)
  security_rule {
    name                       = "AllowSSHForAnsible"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"  
    destination_address_prefix = "*"
  }
}


# NSG Associations with Subnets
resource "azurerm_subnet_network_security_group_association" "public_nsg_assoc" {
  subnet_id                 = azurerm_subnet.public_subnet.id
  network_security_group_id = azurerm_network_security_group.public_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "frontend_nsg_assoc" {
  subnet_id                 = azurerm_subnet.frontend_subnet.id
  network_security_group_id = azurerm_network_security_group.frontend_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "database_nsg_assoc" {
  subnet_id                 = azurerm_subnet.database_subnet.id
  network_security_group_id = azurerm_network_security_group.database_nsg.id
}

# Public IPs
resource "azurerm_public_ip" "loadbalancer_public_ip" {
  name                = "costco-logistics-fulfillment-lb-public-ip"
  location            = azurerm_resource_group.costco_logistics_fulfillment_rg.location
  resource_group_name = azurerm_resource_group.costco_logistics_fulfillment_rg.name
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "frontend_public_ip" {
  count               = 3
  name                = "costco-logistics-fulfillment-frontend-public-ip-${count.index + 1}"
  location            = azurerm_resource_group.costco_logistics_fulfillment_rg.location
  resource_group_name = azurerm_resource_group.costco_logistics_fulfillment_rg.name
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "database_public_ip" {
  name                = "costco-logistics-fulfillment-db-public-ip"
  location            = azurerm_resource_group.costco_logistics_fulfillment_rg.location
  resource_group_name = azurerm_resource_group.costco_logistics_fulfillment_rg.name
  allocation_method   = "Static"
}

# Network Interfaces
resource "azurerm_network_interface" "loadbalancer_nic" {
  name                = "costco-logistics-fulfillment-lb-nic"
  location            = azurerm_resource_group.costco_logistics_fulfillment_rg.location
  resource_group_name = azurerm_resource_group.costco_logistics_fulfillment_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.loadbalancer_public_ip.id
  }
}

resource "azurerm_network_interface" "frontend_nic" {
  count               = 3
  name                = "costco-logistics-fulfillment-frontend-nic-${count.index + 1}"
  location            = azurerm_resource_group.costco_logistics_fulfillment_rg.location
  resource_group_name = azurerm_resource_group.costco_logistics_fulfillment_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.frontend_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.frontend_public_ip[count.index].id
  }
}

resource "azurerm_network_interface" "database_nic" {
  name                = "costco-logistics-fulfillment-db-nic"
  location            = azurerm_resource_group.costco_logistics_fulfillment_rg.location
  resource_group_name = azurerm_resource_group.costco_logistics_fulfillment_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.database_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.database_public_ip.id
  }
}

# Virtual Machines
resource "azurerm_linux_virtual_machine" "loadbalancer_vm" {
  name                = "costco-logistics-fulfillment-lb-vm"
  location            = azurerm_resource_group.costco_logistics_fulfillment_rg.location
  resource_group_name = azurerm_resource_group.costco_logistics_fulfillment_rg.name
  size                = "Standard_B1s"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.loadbalancer_nic.id]

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

resource "azurerm_linux_virtual_machine" "frontend_vm" {
  count               = 3
  name                = "costco-logistics-fulfillment-frontend-vm-${count.index + 1}"
  location            = azurerm_resource_group.costco_logistics_fulfillment_rg.location
  resource_group_name = azurerm_resource_group.costco_logistics_fulfillment_rg.name
  size                = "Standard_B1s"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.frontend_nic[count.index].id]

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

resource "azurerm_linux_virtual_machine" "database_vm" {
  name                = "costco-logistics-fulfillment-db-vm"
  location            = azurerm_resource_group.costco_logistics_fulfillment_rg.location
  resource_group_name = azurerm_resource_group.costco_logistics_fulfillment_rg.name
  size                = "Standard_B1s"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.database_nic.id]

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

# Generate Ansible Inventory File
resource "null_resource" "ansible_inventory" {
  provisioner "local-exec" {
    command = <<EOT
      echo "[frontend]" > ../ansible/ansible_inventory
      echo "${azurerm_linux_virtual_machine.frontend_vm[0].name} ansible_host=${azurerm_public_ip.frontend_public_ip[0].ip_address} ansible_user=${var.admin_username} ansible_password=${var.admin_password}" >> ../ansible/ansible_inventory
      echo "${azurerm_linux_virtual_machine.frontend_vm[1].name} ansible_host=${azurerm_public_ip.frontend_public_ip[1].ip_address} ansible_user=${var.admin_username} ansible_password=${var.admin_password}" >> ../ansible/ansible_inventory
      echo "${azurerm_linux_virtual_machine.frontend_vm[2].name} ansible_host=${azurerm_public_ip.frontend_public_ip[2].ip_address} ansible_user=${var.admin_username} ansible_password=${var.admin_password}" >> ../ansible/ansible_inventory

      echo "[loadbalancer]" >> ../ansible/ansible_inventory
      echo "${azurerm_linux_virtual_machine.loadbalancer_vm.name} ansible_host=${azurerm_public_ip.loadbalancer_public_ip.ip_address} ansible_user=${var.admin_username} ansible_password=${var.admin_password}" >> ../ansible/ansible_inventory

      echo "[database]" >> ../ansible/ansible_inventory
      echo "${azurerm_linux_virtual_machine.database_vm.name} ansible_host=${azurerm_public_ip.database_public_ip.ip_address} ansible_user=${var.admin_username} ansible_password=${var.admin_password}" >> ../ansible/ansible_inventory
    EOT
  }

  depends_on = [
    azurerm_linux_virtual_machine.loadbalancer_vm,
    azurerm_linux_virtual_machine.frontend_vm,
    azurerm_linux_virtual_machine.database_vm
  ]
}
