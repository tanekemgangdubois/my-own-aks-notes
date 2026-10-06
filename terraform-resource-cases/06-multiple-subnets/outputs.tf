output "subnet_ids" {
  value = { for name, subnet in azurerm_subnet.this : name => subnet.id }
}

output "app_subnet_id" {
  value = azurerm_subnet.this["snet-app"].id
}
