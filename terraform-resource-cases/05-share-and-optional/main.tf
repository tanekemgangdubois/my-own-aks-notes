resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Dev/preprod/prod own an ACR. Test reads dev's ACR.
resource "azurerm_container_registry" "this" {
  count = var.environment == "test" ? 0 : 1

  name                = var.acr_name
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = false
  tags                = var.tags
}

data "azurerm_container_registry" "dev_shared" {
  count = var.environment == "test" ? 1 : 0

  name                = var.dev_acr_name
  resource_group_name = var.dev_resource_group_name
}
