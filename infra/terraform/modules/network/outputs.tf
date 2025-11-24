output "vnet_id" {
  value       = azurerm_virtual_network.this.id
  description = "Virtual network resource ID."
}

output "subnet_ids" {
  value = {
    for subnet_key, subnet in azurerm_subnet.this :
    subnet_key => subnet.id
  }
  description = "Map of subnet keys to subnet IDs."
}
