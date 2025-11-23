#####################################
# App Service Plan for Function App (Consumption)
#####################################

resource "azurerm_service_plan" "functions_plan" {
  name                = "${var.name_prefix}-plan-${var.env}-${var.env_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  os_type  = "Linux"
  sku_name = "Y1"  # Consumption plan
}

#####################################
# Function App (Linux)
#####################################

resource "azurerm_linux_function_app" "this" {
  name                = "${var.name_prefix}-app-${var.env}-${var.env_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  service_plan_id              = azurerm_service_plan.functions_plan.id
  storage_account_name         = var.storage_account_name
  storage_uses_managed_identity = true

  https_only = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      node_version = "18"
    }

    # Note: always_on is not supported on Consumption plan
    # Note: VNet integration and IP restrictions are limited on Consumption plan
  }

  app_settings = {
    FUNCTIONS_EXTENSION_VERSION = "~4"
    FUNCTIONS_WORKER_RUNTIME    = "node"

    STORAGE_ACCOUNT_NAME = var.storage_account_name
  }
}

# Note: VNet Integration is not available on Consumption plan
# Upgrade to Premium plan (EP1) if VNet integration is required

