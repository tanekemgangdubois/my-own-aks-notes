# 1. Decide which environments create it and which reuse it.
  Example for an ACR:
<img width="741" height="239" alt="image" src="https://github.com/user-attachments/assets/76c143f1-3ba4-4c4e-95ff-2e0bfe6b743c" />

# 2. Write the resource block for environments that create it.
  resource "azurerm_container_registry" "environment" {
    count = contains(["test", "preprod"], var.environment) ? 0 : 1
  
    # Resource configuration...
  }
  Meaning: test and pre create zero; dev and prod create one.

# 3. Write the data block for environments that reuse it.
  data "azurerm_container_registry" "shared" {
    count = contains(["test", "preprod"], var.environment) ? 1 : 0
  
    name                = var.shared_acr_name
    resource_group_name = var.shared_resource_group_name
  }
  Meaning: test and pre look up the existing ACR using its name and resource group.

# 4. Select the correct resource ID for outputs or other resources.
  locals {
    acr_id = contains(["test", "preprod"], var.environment) ? data.azurerm_container_registry.shared[0].id : azurerm_container_registry.environment[0].id
  }
  Then use local.acr_id wherever the ACR ID is needed.

# 5. Deploy the owner first, then the environments that reuse it.
  In this example, deploy dev before test or pre. Give the consuming applications the permissions they need to use the shared resource.
  
# 6. Check the plan before applying.
  - An environment creating the resource should show it being created.
  - An environment reusing it should show no duplicate creation.
  - Changing an existing resource from “creates” to “reuses” can plan deletion of its previous resource.
  If a resource is never shared, use a normal resource block without count or a shared data block:
  resource "azurerm_storage_account" "environment" {
  ### Each selected environment creates its own Storage Account.
  }
