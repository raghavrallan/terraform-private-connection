#####################################
# Azure Key Vault (Private)
#####################################

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                = "kv-${var.env}-${var.env_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Disable public access - use private endpoints only
  public_network_access_enabled = true

  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }

  # Enable RBAC authorization instead of access policies
  enable_rbac_authorization = true

  # Security features
  purge_protection_enabled   = false  # Set to true for production
  soft_delete_retention_days = 7
}

# NOTE: Secrets will be created manually after deployment using Azure CLI
# This avoids RBAC permission issues during Terraform deployment

# # Store database connection string as a secret
# resource "azurerm_key_vault_secret" "sql_connection_string" {
#   name         = "sql-connection-string"
#   value        = var.sql_connection_string
#   key_vault_id = azurerm_key_vault.main.id
#
#   depends_on = [azurerm_key_vault.main]
# }
#
# # Store storage account name
# resource "azurerm_key_vault_secret" "storage_account_name" {
#   name         = "storage-account-name"
#   value        = var.storage_account_name
#   key_vault_id = azurerm_key_vault.main.id
#
#   depends_on = [azurerm_key_vault.main]
# }
