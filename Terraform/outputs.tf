

# Output for Public IP addresses of each VM
output "frontend_vm_public_ips" {
  value = [for vm in azurerm_linux_virtual_machine.frontend_vm : vm.public_ip_address]
  description = "Public IPs of the frontend VMs"
}

output "loadbalancer_vm_public_ip" {
  value       = azurerm_linux_virtual_machine.loadbalancer_vm.public_ip_address
  description = "Public IP of the load balancer VM"
}

output "database_vm_public_ip" {
  value       = azurerm_linux_virtual_machine.database_vm.public_ip_address
  description = "Public IP of the database VM"
}

# Output for VM names
output "frontend_vm_names" {
  value       = [for vm in azurerm_linux_virtual_machine.frontend_vm : vm.name]
  description = "Names of the frontend VMs"
}

output "loadbalancer_vm_name" {
  value       = azurerm_linux_virtual_machine.loadbalancer_vm.name
  description = "Name of the load balancer VM"
}

output "database_vm_name" {
  value       = azurerm_linux_virtual_machine.database_vm.name
  description = "Name of the database VM"
}
