output "vnet_id" {
  value = azurerm_virtual_network.main.id
}

output "subnet_aca_id" {
  value = azurerm_subnet.aca.id
}

output "subnet_functions_id" {
  value = azurerm_subnet.functions.id
}

output "subnet_privatelink_id" {
  value = azurerm_subnet.privatelink.id
}
