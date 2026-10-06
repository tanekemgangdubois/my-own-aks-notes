output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "acr_id" {
  value = var.environment == "test" ? data.azurerm_container_registry.dev_shared[0].id : azurerm_container_registry.this[0].id
}

output "acr_login_server" {
  value = var.environment == "test" ? data.azurerm_container_registry.dev_shared[0].login_server : azurerm_container_registry.this[0].login_server
}
