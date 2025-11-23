#####################################
# Resource Groups (separated by domain)
#####################################

resource "azurerm_resource_group" "network" {
  name     = "rg-network-${var.env}-${var.env_suffix}"
  location = var.location
}

resource "azurerm_resource_group" "database" {
  name     = "rg-database-${var.env}-${var.env_suffix}"
  location = var.location
}

resource "azurerm_resource_group" "storage" {
  name     = "rg-storage-${var.env}-${var.env_suffix}"
  location = var.location
}

resource "azurerm_resource_group" "backend" {
  name     = "rg-backend-${var.env}-${var.env_suffix}"
  location = var.location
}

#####################################
# Network module (VNet + Subnets)
#####################################

module "network" {
  source = "./modules/network"

  resource_group_name = azurerm_resource_group.network.name
  location            = azurerm_resource_group.network.location
  env                 = var.env
  env_suffix          = var.env_suffix
}

#####################################
# Storage module (Private-only Storage)
#####################################

module "storage" {
  source = "./modules/storage"

  resource_group_name = azurerm_resource_group.storage.name
  location            = azurerm_resource_group.storage.location
  env                 = var.env
  env_suffix          = var.env_suffix
}

#####################################
# SQL module (DB + server, separate RG)
#####################################

module "sql" {
  source = "./modules/sql"

  resource_group_name = azurerm_resource_group.database.name
  location            = azurerm_resource_group.database.location
  env                 = var.env
  env_suffix          = var.env_suffix
}

#####################################
# Azure Container Registry (Private)
#####################################

module "acr" {
  source = "./modules/acr"

  resource_group_name = azurerm_resource_group.backend.name
  location            = azurerm_resource_group.backend.location
  env                 = var.env
  env_suffix          = var.env_suffix
}

#####################################
# Key Vault (Private with secrets)
#####################################

module "keyvault" {
  source = "./modules/keyvault"

  resource_group_name = azurerm_resource_group.backend.name
  location            = azurerm_resource_group.backend.location
  env                 = var.env
  env_suffix          = var.env_suffix

  sql_connection_string = "Server=tcp:${module.sql.sql_server_fqdn},1433;Database=${module.sql.sql_db_name};Authentication=Active Directory Default;"
  storage_account_name  = module.storage.storage_account_name
}

#####################################
# Static Web App
#####################################

module "static_web_app" {
  source = "./modules/static_web_app"

  resource_group_name = azurerm_resource_group.backend.name
  location            = "West US 2"  # Static Web Apps have limited regions
  env                 = var.env
  env_suffix          = var.env_suffix
}

#####################################
# Private Endpoints + Private DNS (network RG)
#####################################

module "private_endpoints" {
  source = "./modules/private_endpoints"

  resource_group_name    = azurerm_resource_group.network.name
  location               = azurerm_resource_group.network.location
  env                    = var.env
  env_suffix             = var.env_suffix

  vnet_id               = module.network.vnet_id
  subnet_id_privatelink = module.network.subnet_privatelink_id

  storage_account_id = module.storage.storage_account_id
  sql_server_id      = module.sql.sql_server_id
  acr_id             = module.acr.acr_id
  key_vault_id       = module.keyvault.key_vault_id
}

#####################################
# Function App (backend RG, VNet integrated)
#####################################

module "function_app" {
  source = "./modules/function_app"

  resource_group_name = azurerm_resource_group.backend.name
  location            = azurerm_resource_group.backend.location
  env                 = var.env
  env_suffix          = var.env_suffix

  subnet_id = module.network.subnet_functions_id

  storage_account_name        = module.storage.storage_account_name
  storage_resource_group_name = azurerm_resource_group.storage.name

  name_prefix = "fn"
}

#####################################
# Container App (public, backend RG)
#####################################

module "container_app" {
  source = "./modules/container_app"

  resource_group_name  = azurerm_resource_group.backend.name
  location             = azurerm_resource_group.backend.location
  env                  = var.env
  env_suffix           = var.env_suffix

  subnet_id            = module.network.subnet_aca_id
  storage_account_name = module.storage.storage_account_name
  sql_server_fqdn      = module.sql.sql_server_fqdn
  sql_db_name          = module.sql.sql_db_name
}

#####################################
# RBAC: Managed Identities -> Storage (Blob Data)
#####################################

# Container App MI can read/write blobs
resource "azurerm_role_assignment" "container_storage_data_contributor" {
  scope                = module.storage.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.container_app.container_app_identity_principal_id
}

# Function App MI can read/write blobs
resource "azurerm_role_assignment" "function_storage_data_contributor" {
  scope                = module.storage.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.function_app.function_app_identity_principal_id
}

# Function App MI needs additional access for Queue, Table, and File storage
resource "azurerm_role_assignment" "function_storage_account_contributor" {
  scope                = module.storage.storage_account_id
  role_definition_name = "Storage Account Contributor"
  principal_id         = module.function_app.function_app_identity_principal_id
}

#####################################
# RBAC: Managed Identities -> ACR (Pull Images)
#####################################

# Container App MI can pull images from ACR
resource "azurerm_role_assignment" "container_acr_pull" {
  scope                = module.acr.acr_id
  role_definition_name = "AcrPull"
  principal_id         = module.container_app.container_app_identity_principal_id
}

#####################################
# RBAC: Managed Identities -> Key Vault (Secrets)
#####################################

# Container App MI can read secrets from Key Vault
resource "azurerm_role_assignment" "container_keyvault_secrets" {
  scope                = module.keyvault.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.container_app.container_app_identity_principal_id
}

# Function App MI can read secrets from Key Vault
resource "azurerm_role_assignment" "function_keyvault_secrets" {
  scope                = module.keyvault.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.function_app.function_app_identity_principal_id
}
