# Main VNet
resource "azurerm_virtual_network" "main" {
  name                = "vnet-app-${var.env}-${var.env_suffix}"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
}

# Subnet for Container Apps (requires at least /23)
resource "azurerm_subnet" "aca" {
  name                 = "snet-aca-${var.env}-${var.env_suffix}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.0/23"]

  # later you can add delegation for Container Apps here if needed
  # delegation {
  #   name = "aca-delegation"
  #   service_delegation {
  #     name = "Microsoft.App/environments"
  #     actions = [
  #       "Microsoft.Network/virtualNetworks/subnets/join/action",
  #     ]
  #   }
  # }
}

# Subnet for Function App integration
resource "azurerm_subnet" "functions" {
  name                 = "snet-functions-${var.env}-${var.env_suffix}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Subnet for Private Endpoints (Storage, SQL, etc.)
resource "azurerm_subnet" "privatelink" {
  name                 = "snet-privatelink-${var.env}-${var.env_suffix}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.3.0/24"]

  # REQUIRED for Private Endpoints: disable network policies
  private_endpoint_network_policies = "Disabled"
  # (If you ever use an older provider, the legacy field is:
  #  private_endpoint_network_policies_enabled = false)
}
