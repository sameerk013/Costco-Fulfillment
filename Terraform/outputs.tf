# Output the Ansible Inventory for copy-pasting or reference
output "ansible_inventory" {
  value = <<EOF
[frontend]
${azurerm_network_interface.nic[0].ip_configuration.0.private_ip_address} ansible_user=${var.admin_username} ansible_password=${var.admin_password}
${azurerm_network_interface.nic[1].ip_configuration.0.private_ip_address} ansible_user=${var.admin_username} ansible_password=${var.admin_password}
${azurerm_network_interface.nic[2].ip_configuration.0.private_ip_address} ansible_user=${var.admin_username} ansible_password=${var.admin_password}

[loadbalancer]
${azurerm_network_interface.nic[3].ip_configuration.0.private_ip_address} ansible_user=${var.admin_username} ansible_password=${var.admin_password}

[database]
${azurerm_network_interface.nic[4].ip_configuration.0.private_ip_address} ansible_user=${var.admin_username} ansible_password=${var.admin_password}
EOF

  description = "Ansible inventory formatted as a Terraform output"
}