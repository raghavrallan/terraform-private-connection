resource "azurerm_storage_account" "main" {
  name                     = "st${var.env}privinfra${var.env_suffix}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Allow public access but restrict with network rules
  public_network_access_enabled = true

  # Configure network rules to allow Azure services
  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }
}

