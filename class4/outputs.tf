output "vm_public_ips" {
  description = "Public IPs of VMs in order"
  value       = azurerm_public_ip.pip[*].ip_address
}

output "vm_names" {
  description = "VM names in order"
  value       = azurerm_linux_virtual_machine.vm[*].name
}

output "load_balancer_public_ip" {
  description = "Public IP of the Load Balancer"
  value       = azurerm_public_ip.lb_pip.ip_address
}