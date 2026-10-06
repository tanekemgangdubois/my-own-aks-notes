output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "resource_group_id" {
  value = azurerm_resource_group.this.id
}

output "shared_resource_group_id" {
  value = data.azurerm_resource_group.shared.id
}
