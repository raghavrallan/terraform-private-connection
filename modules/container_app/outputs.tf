output "container_app_id" {
  value = azurerm_container_app.app.id
}

output "container_app_identity_principal_id" {
  value = azurerm_container_app.app.identity[0].principal_id
}
