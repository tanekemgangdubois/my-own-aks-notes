# let say container registry is used by test and dev 
    data "azurerm_container_registry" "dev_shared" {
      count               = var.environment == "test" ? 1 : 0
      name                = "${var.project}dev${var.name_suffix}"
      resource_group_name = var.dev_resource_group_name
    }

# you need to reference the ACR found by that data block wherever it will be used. An output is useful for showing its details or passing them to your application pipeline.
    output "acr_login_server" {
      value = var.environment == "test" ? data.azurerm_container_registry.dev_shared[0].login_server : azurerm_container_registry.environment[0].login_server
    }
    
    output "acr_id" {
      value = var.environment == "test" ? data.azurerm_container_registry.dev_shared[0].id : azurerm_container_registry.environment[0].id
    }

    
<img width="906" height="446" alt="image" src="https://github.com/user-attachments/assets/f60a26ee-1bd6-4d9a-821a-4d26d6d70a19" />
