resource "azurerm_mssql_server" "main" {
  name                         = "sql-server-${var.env}-priv-${var.env_suffix}"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = "sqladminuser"
  administrator_login_password = "ChangeThisPassword123!"
  public_network_access_enabled = false
}

resource "azurerm_mssql_database" "db" {
  name           = "sqldb-${var.env}-${var.env_suffix}"
  server_id      = azurerm_mssql_server.main.id
  sku_name       = "S0"
}
