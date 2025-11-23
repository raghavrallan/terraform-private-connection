#####################################
# Private DNS Zones
#####################################

# Blob Private DNS Zone
resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob_link" {
  name                  = "pdnsz-blob-vnet-link-${var.env}-${var.env_suffix}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}

# SQL Private DNS Zone
resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql_link" {
  name                  = "pdnsz-sql-vnet-link-${var.env}-${var.env_suffix}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}

#####################################
# Storage Private Endpoint
#####################################

resource "azurerm_private_endpoint" "storage_blob" {
  name                = "pe-storage-blob-${var.env}-${var.env_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id_privatelink

  private_service_connection {
    name                           = "psc-storage-blob-${var.env}-${var.env_suffix}"
    private_connection_resource_id = var.storage_account_id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  # Attach Private DNS zone to PE so A record is auto-created
  private_dns_zone_group {
    name                 = "blob-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }
}

#####################################
# SQL Private Endpoint
#####################################

resource "azurerm_private_endpoint" "sql" {
  name                = "pe-sql-${var.env}-${var.env_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id_privatelink

  private_service_connection {
    name                           = "psc-sql-${var.env}-${var.env_suffix}"
    private_connection_resource_id = var.sql_server_id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "sql-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }
}

#####################################
# ACR Private DNS Zone & Endpoint
#####################################

resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr_link" {
  name                  = "pdnsz-acr-vnet-link-${var.env}-${var.env_suffix}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}

resource "azurerm_private_endpoint" "acr" {
  name                = "pe-acr-${var.env}-${var.env_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id_privatelink

  private_service_connection {
    name                           = "psc-acr-${var.env}-${var.env_suffix}"
    private_connection_resource_id = var.acr_id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "acr-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr.id]
  }
}

#####################################
# Key Vault Private DNS Zone & Endpoint
#####################################

resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault_link" {
  name                  = "pdnsz-kv-vnet-link-${var.env}-${var.env_suffix}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}

resource "azurerm_private_endpoint" "keyvault" {
  name                = "pe-kv-${var.env}-${var.env_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id_privatelink

  private_service_connection {
    name                           = "psc-kv-${var.env}-${var.env_suffix}"
    private_connection_resource_id = var.key_vault_id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "kv-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.keyvault.id]
  }
}
