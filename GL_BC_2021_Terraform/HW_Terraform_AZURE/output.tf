# Show load balancer public ip 
output "public_ip_address" {
   description = "The actual ip address allocated for the resource."
   value       = "${azurerm_public_ip.lb.*.ip_address}"
}

# Show VM1 public ip
output "azurerm_public_ip_vm1" {
  description = "ip addresses of the vm nics"
  value = "${azurerm_public_ip.vm1.*.ip_address}"
}  

# Show VM2 public ip  
output "azurerm_public_ip_vm2" {
  value = "${azurerm_public_ip.vm2.*.ip_address}"
}
