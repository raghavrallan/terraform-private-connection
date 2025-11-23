output "pe_storage_id" {
  value = azurerm_private_endpoint.storage_blob.id
}

output "pe_sql_id" {
  value = azurerm_private_endpoint.sql.id
}
