output "storage_account_id" {
  value = azurerm_storage_account.main.id
}

output "storage_account_name" {
  value = azurerm_storage_account.main.name
}

output "storage_account_primary_access_key" {
  sensitive = true
  value     = azurerm_storage_account.main.primary_access_key
}
