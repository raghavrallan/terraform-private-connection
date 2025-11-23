#####################################
# Azure Container Registry (Private)
#####################################

resource "azurerm_container_registry" "main" {
  name                = "acr${var.env}${var.env_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Premium"  # Premium required for private endpoints
  admin_enabled       = false      # Use managed identity instead

  public_network_access_enabled = true
  network_rule_bypass_option    = "AzureServices"

  network_rule_set {
    default_action = "Deny"
  }
}
