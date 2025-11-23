# Container Apps Environment (VNet integrated)
resource "azurerm_container_app_environment" "env" {
  name                = "aca-env-${var.env}-${var.env_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  infrastructure_subnet_id = var.subnet_id
}

# Container App with public ingress and managed identity
resource "azurerm_container_app" "app" {
  name                         = "aca-public-app-${var.env}-${var.env_suffix}"
  resource_group_name          = var.resource_group_name
  container_app_environment_id = azurerm_container_app_environment.env.id

  revision_mode = "Single"

  identity {
    type = "SystemAssigned"
  }

  template {
    container {
      name   = "app"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "STORAGE_ACCOUNT_NAME"
        value = var.storage_account_name
      }

      env {
        name  = "SQL_SERVER_FQDN"
        value = var.sql_server_fqdn
      }

      env {
        name  = "SQL_DB_NAME"
        value = var.sql_db_name
      }
    }
  }

  ingress {
    external_enabled = true  # public
    target_port      = 80
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}
