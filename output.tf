#####################################
# Outputs - All Key Infrastructure Values
#####################################

# Resource Groups
output "resource_group_network_name" {
  value = azurerm_resource_group.network.name
}

output "resource_group_storage_name" {
  value = azurerm_resource_group.storage.name
}

output "resource_group_database_name" {
  value = azurerm_resource_group.database.name
}

output "resource_group_backend_name" {
  value = azurerm_resource_group.backend.name
}

# Network
output "vnet_id" {
  value = module.network.vnet_id
}

# Storage
output "storage_account_name" {
  value = module.storage.storage_account_name
}

output "storage_account_id" {
  value = module.storage.storage_account_id
}

# SQL Database
output "sql_server_name" {
  value = module.sql.sql_server_name
}

output "sql_server_fqdn" {
  value = module.sql.sql_server_fqdn
}

output "sql_db_name" {
  value = module.sql.sql_db_name
}

output "sql_server_id" {
  value = module.sql.sql_server_id
}

# Azure Container Registry
output "acr_name" {
  value = module.acr.acr_name
}

output "acr_login_server" {
  value = module.acr.acr_login_server
}

output "acr_id" {
  value = module.acr.acr_id
}

# Key Vault
output "key_vault_name" {
  value = module.keyvault.key_vault_name
}

output "key_vault_uri" {
  value = module.keyvault.key_vault_uri
}

output "key_vault_id" {
  value = module.keyvault.key_vault_id
}

# Static Web App
output "static_web_app_name" {
  value = module.static_web_app.static_web_app_name
}

output "static_web_app_default_host_name" {
  value = module.static_web_app.default_host_name
}

output "static_web_app_api_key" {
  value     = module.static_web_app.api_key
  sensitive = true
}

# Container App
output "container_app_name" {
  value = module.container_app.container_app_name
}

output "container_app_url" {
  value = module.container_app.container_app_id
}

output "container_app_fqdn" {
  value = module.container_app.container_app_fqdn
}

# Function App
output "function_app_name" {
  value = module.function_app.function_app_name
}

output "function_app_default_hostname" {
  value = module.function_app.function_app_default_hostname
}
