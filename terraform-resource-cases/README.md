# Terraform resource situations: complete Azure Public examples

These are independent teaching configurations, not replacements for your current ADO project. All examples use Azure Public/AzureCloud and eastus. They use local state to make ownership and each environment's isolation visible. Your real project keeps its Azure Storage backend and deploy-infra pipeline. This package creates no Azure resources until you run apply.

This covers the common creation/ownership patterns, not every provider-specific feature. Every root folder contains versions.tf (provider), backend.tf (state), variables.tf (root inputs), main.tf (behavior), outputs.tf (results), and environments/dev.tfvars (values). Extra files are shown in each case. .tf files in a root directory are loaded together; .tfvars assigns values but does not declare variables. Child module variables must be declared separately. Data lookup outputs can be read after applying a data-only configuration, but outputs are not required merely to perform a lookup.

## Before running examples

Install Terraform 1.9+ and Azure CLI. Sign in as a user for these local examples: `az cloud set --name AzureCloud`, `az login`, and `az account set --subscription abdb38d1-d80a-40c6-a158-f152d3dfb285`. Your identity needs deployment permissions in the selected subscription; cross-subscription examples also need read permission in the other subscription. Pipeline authentication continues to use your service connection and explicit ARM credentials; do not add interactive az login to the pipeline.

Select ONE case, cd into it, and run the commands below. The configured local state path is relative to that case's working directory. Do not reuse a state file between unrelated cases. Do not copy multiple case main.tf files into the same root. Keep .terraform.lock.hcl in source control; keep state files and plans private. For pipelines, replace the local backend with your existing Azure backend and initialize the correct environment state before plan/apply.

Standard commands, inside the selected case folder:

```bash
mkdir -p state
terraform init -reconfigure -backend-config="path=state/dev.tfstate"
terraform validate
terraform plan -var-file=environments/dev.tfvars -out=dev.tfplan
# Review the plan first.
terraform apply dev.tfplan
terraform output
```

`terraform validate` checks configuration structure; plan evaluates tfvars and reads Azure. Files have been reviewed and root references checked, but Terraform CLI/provider/Azure execution has not been tested in this environment.

## Choose the case

| Case | Existing object? | Terraform owner? | Approach |
|---|---|---|---|
| 01 | No | This state | resource |
| 02 | Yes | Someone else/another state | data |
| 03 | Yes | No existing Terraform owner | resource plus import |
| 04 | Either, with appropriate adoption | This state | module wrapping resource |
| 05 | Dev creates; test consumes | Dev owns shared ACR | conditional resource plus data |
| 06 | New multiple objects | This state | for_each |
| 07 | Already created by this state | Same state | update configuration |
| 08 | Already created by this state | Same state; new code address | moved |
| 09 | Other subscription contains existing RG | Reader only for shared RG | provider alias plus data |

One Azure resource should have one Terraform owner. A data source does not create or manage the object's lifecycle. A module is code organization and reuse; it does not create its own state automatically. Using an ID does not automatically grant permissions or attach a workload to a network. Resource references create dependency relationships automatically.

## 01-new-resource: Create a new resource

Use when rg-example-01 does not exist. Standard commands create one RG. This same RG is the read-only target for cases 02 and 09; it remains owned by case 01.

Run commands from `01-new-resource/`. Create these files exactly at the paths shown.

### `01-new-resource/backend.tf`

```hcl
# Teaching examples use local state. Keep this separate from your ADO remote backend.
terraform {
  backend "local" {}
}
```

### `01-new-resource/environments/dev.tfvars`

```hcl
subscription_id = "abdb38d1-d80a-40c6-a158-f152d3dfb285"
location = "eastus"
resource_group_name = "rg-example-01"
tags = {"environment": "dev", "managed_by": "terraform"}
```

### `01-new-resource/main.tf`

```hcl
resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}
```

### `01-new-resource/outputs.tf`

```hcl
output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "resource_group_id" {
  value = azurerm_resource_group.this.id
}
```

### `01-new-resource/variables.tf`

```hcl
variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
```

### `01-new-resource/versions.tf`

```hcl
terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.9.0, < 5.0.0"
    }
  }
}

provider "azurerm" {
  environment     = "public"
  subscription_id = var.subscription_id
  features {}
}
```

## 02-read-existing: Read an existing resource

Run after case 01 exists, or change resource_group_name to a known existing RG. Standard commands read that RG and save its output; no RG is created. Destroying case 02 does not destroy the RG. A missing RG causes the lookup to fail.

Run commands from `02-read-existing/`. Create these files exactly at the paths shown.

### `02-read-existing/backend.tf`

```hcl
# Teaching examples use local state. Keep this separate from your ADO remote backend.
terraform {
  backend "local" {}
}
```

### `02-read-existing/environments/dev.tfvars`

```hcl
subscription_id = "abdb38d1-d80a-40c6-a158-f152d3dfb285"
location = "eastus"
resource_group_name = "rg-example-01"
tags = {"environment": "dev", "managed_by": "terraform"}
```

### `02-read-existing/main.tf`

```hcl
data "azurerm_resource_group" "existing" {
  name = var.resource_group_name
}
```

### `02-read-existing/outputs.tf`

```hcl
output "resource_group_id" {
  value = data.azurerm_resource_group.existing.id
}
```

### `02-read-existing/variables.tf`

```hcl
variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
```

### `02-read-existing/versions.tf`

```hcl
terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.9.0, < 5.0.0"
    }
  }
}

provider "azurerm" {
  environment     = "public"
  subscription_id = var.subscription_id
  features {}
}
```

## 03-import-existing: Adopt a manually created resource

Create the demo object outside Terraform first:

```bash
az group create --name rg-example-import --location eastus --subscription abdb38d1-d80a-40c6-a158-f152d3dfb285 --tags environment=dev managed_by=terraform
```

Then run the standard Terraform commands. The import block uses the Azure ID from tfvars. Review any changes in plan; importing does not guarantee the configuration matches Azure. Never import an object already owned by case 01 or another state. After import, this case owns the RG. Existing objects destined for a module use an import target such as module.resource_group.azurerm_resource_group.this.

Run commands from `03-import-existing/`. Create these files exactly at the paths shown.

### `03-import-existing/backend.tf`

```hcl
# Teaching examples use local state. Keep this separate from your ADO remote backend.
terraform {
  backend "local" {}
}
```

### `03-import-existing/environments/dev.tfvars`

```hcl
subscription_id = "abdb38d1-d80a-40c6-a158-f152d3dfb285"
location = "eastus"
resource_group_name = "rg-example-import"
tags = {"environment": "dev", "managed_by": "terraform"}
existing_resource_group_id = "/subscriptions/abdb38d1-d80a-40c6-a158-f152d3dfb285/resourceGroups/rg-example-import"
```

### `03-import-existing/imports.tf`

```hcl
import {
  to = azurerm_resource_group.this
  id = var.existing_resource_group_id
}
```

### `03-import-existing/main.tf`

```hcl
resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}
```

### `03-import-existing/outputs.tf`

```hcl
output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "resource_group_id" {
  value = azurerm_resource_group.this.id
}
```

### `03-import-existing/variables.tf`

```hcl
variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
variable "existing_resource_group_id" {
  type = string
}
```

### `03-import-existing/versions.tf`

```hcl
terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.9.0, < 5.0.0"
    }
  }
}

provider "azurerm" {
  environment     = "public"
  subscription_id = var.subscription_id
  features {}
}
```

## 04-reusable-module: Create through reusable code

Standard commands create one RG through a child module. The root passes name/location/tags; the child declares them, creates a resource, and returns name/id. Its provider is inherited from the root. A second environment can reuse this module with another tfvars file and separate state. Do not keep the old direct RG resource block alongside the module call for the same Azure object.

Run commands from `04-reusable-module/`. Create these files exactly at the paths shown.

### `04-reusable-module/backend.tf`

```hcl
# Teaching examples use local state. Keep this separate from your ADO remote backend.
terraform {
  backend "local" {}
}
```

### `04-reusable-module/environments/dev.tfvars`

```hcl
subscription_id = "abdb38d1-d80a-40c6-a158-f152d3dfb285"
location = "eastus"
resource_group_name = "rg-example-04"
tags = {"environment": "dev", "managed_by": "terraform"}
```

### `04-reusable-module/main.tf`

```hcl
module "resource_group" {
  source = "./modules/resource-group"

  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}
```

### `04-reusable-module/modules/resource-group/main.tf`

```hcl
resource "azurerm_resource_group" "this" {
  name     = var.name
  location = var.location
  tags     = var.tags
}
```

### `04-reusable-module/modules/resource-group/outputs.tf`

```hcl
output "name" {
  value = azurerm_resource_group.this.name
}

output "id" {
  value = azurerm_resource_group.this.id
}
```

### `04-reusable-module/modules/resource-group/variables.tf`

```hcl
variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
```

### `04-reusable-module/modules/resource-group/versions.tf`

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.9.0"
    }
  }
}
```

### `04-reusable-module/outputs.tf`

```hcl
output "resource_group_name" {
  value = module.resource_group.name
}

output "resource_group_id" {
  value = module.resource_group.id
}
```

### `04-reusable-module/variables.tf`

```hcl
variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
```

### `04-reusable-module/versions.tf`

```hcl
terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.9.0, < 5.0.0"
    }
  }
}

provider "azurerm" {
  environment     = "public"
  subscription_id = var.subscription_id
  features {}
}
```

## 05-share-and-optional: Dev owns a shared resource; test reads it

Choose globally unique valid ACR names in all tfvars and keep dev_acr_name consistent. All configurations here assume the same subscription for dev/test. Run the standard dev commands first (two resources: RG and ACR). Then switch local state and inputs for test:

```bash
terraform init -reconfigure -backend-config="path=state/test.tfstate"
terraform plan -var-file=environments/test.tfvars -out=test.tfplan
terraform apply test.tfplan
```

Test creates its RG and reads dev ACR. Preprod/prod input files create their own ACR/RG using their own state paths. count=0 skips creation; count=1 creates one instance. An optional resource uses the same pattern: `count = var.enable_feature ? 1 : 0` with a declared bool input. Turning that bool off for an already managed object plans its deletion. Test destroy leaves dev ACR. Dev destroy affects its consumers. Deploy dev before test. Reading the ACR does not grant AcrPull; grant permissions separately to the identity of the application/VM/cluster. The same ownership pattern applies to your shared VNet/subnet.

Run commands from `05-share-and-optional/`. Create these files exactly at the paths shown.

### `05-share-and-optional/backend.tf`

```hcl
# Teaching examples use local state. Keep this separate from your ADO remote backend.
terraform {
  backend "local" {}
}
```

### `05-share-and-optional/environments/dev.tfvars`

```hcl
subscription_id = "abdb38d1-d80a-40c6-a158-f152d3dfb285"
location = "eastus"
resource_group_name = "rg-example-shared-dev"
tags = {"environment": "dev", "managed_by": "terraform"}
environment = "dev"
acr_name = "tdmrexampledev987654"
dev_acr_name = "tdmrexampledev987654"
dev_resource_group_name = "rg-example-shared-dev"
```

### `05-share-and-optional/environments/preprod.tfvars`

```hcl
subscription_id = "abdb38d1-d80a-40c6-a158-f152d3dfb285"
location = "eastus"
resource_group_name = "rg-example-shared-preprod"
tags = {"environment": "preprod", "managed_by": "terraform"}
environment = "preprod"
acr_name = "tdmrexamplepreprod987654"
dev_acr_name = "tdmrexampledev987654"
dev_resource_group_name = "rg-example-shared-dev"
```

### `05-share-and-optional/environments/prod.tfvars`

```hcl
subscription_id = "abdb38d1-d80a-40c6-a158-f152d3dfb285"
location = "eastus"
resource_group_name = "rg-example-shared-prod"
tags = {"environment": "prod", "managed_by": "terraform"}
environment = "prod"
acr_name = "tdmrexampleprod987654"
dev_acr_name = "tdmrexampledev987654"
dev_resource_group_name = "rg-example-shared-dev"
```

### `05-share-and-optional/environments/test.tfvars`

```hcl
subscription_id = "abdb38d1-d80a-40c6-a158-f152d3dfb285"
location = "eastus"
resource_group_name = "rg-example-shared-test"
tags = {"environment": "test", "managed_by": "terraform"}
environment = "test"
acr_name = "tdmrexampletest987654"
dev_acr_name = "tdmrexampledev987654"
dev_resource_group_name = "rg-example-shared-dev"
```

### `05-share-and-optional/main.tf`

```hcl
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
```

### `05-share-and-optional/outputs.tf`

```hcl
output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "acr_id" {
  value = var.environment == "test" ? data.azurerm_container_registry.dev_shared[0].id : azurerm_container_registry.this[0].id
}

output "acr_login_server" {
  value = var.environment == "test" ? data.azurerm_container_registry.dev_shared[0].login_server : azurerm_container_registry.this[0].login_server
}
```

### `05-share-and-optional/variables.tf`

```hcl
variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
variable "environment" {
  type = string
}

variable "acr_name" {
  type = string
}

variable "dev_acr_name" {
  type = string
}

variable "dev_resource_group_name" {
  type = string
}
```

### `05-share-and-optional/versions.tf`

```hcl
terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.9.0, < 5.0.0"
    }
  }
}

provider "azurerm" {
  environment     = "public"
  subscription_id = var.subscription_id
  features {}
}
```

## 06-multiple-subnets: Create several resources with for_each

Standard commands create one RG, one VNet, and two subnets. Change the subnets map to add/remove subnets. Map keys identify resource instances, so renaming a key can imply replacement unless mapped with moved. Subnet ranges must be within the VNet and must not overlap. The example uses an app and VM subnet; choose subnet types/counts for the actual services. Output app_subnet_id is referenced by azurerm_subnet.this["snet-app"].id.

Run commands from `06-multiple-subnets/`. Create these files exactly at the paths shown.

### `06-multiple-subnets/backend.tf`

```hcl
# Teaching examples use local state. Keep this separate from your ADO remote backend.
terraform {
  backend "local" {}
}
```

### `06-multiple-subnets/environments/dev.tfvars`

```hcl
subscription_id = "abdb38d1-d80a-40c6-a158-f152d3dfb285"
location = "eastus"
resource_group_name = "rg-example-06"
tags = {"environment": "dev", "managed_by": "terraform"}
vnet_name = "VNET-EXAMPLE-06"
vnet_address_space = ["10.60.0.0/16"]
subnets = {"snet-app": ["10.60.1.0/24"], "snet-vm": ["10.60.2.0/24"]}
```

### `06-multiple-subnets/main.tf`

```hcl
resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  address_space       = var.vnet_address_space
  tags                = var.tags
}

resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value
}
```

### `06-multiple-subnets/outputs.tf`

```hcl
output "subnet_ids" {
  value = { for name, subnet in azurerm_subnet.this : name => subnet.id }
}

output "app_subnet_id" {
  value = azurerm_subnet.this["snet-app"].id
}
```

### `06-multiple-subnets/variables.tf`

```hcl
variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
variable "vnet_name" {
  type = string
}

variable "vnet_address_space" {
  type = list(string)
}

variable "subnets" {
  type = map(list(string))
}
```

### `06-multiple-subnets/versions.tf`

```hcl
terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.9.0, < 5.0.0"
    }
  }
}

provider "azurerm" {
  environment     = "public"
  subscription_id = var.subscription_id
  features {}
}
```

## 07-update-managed: Update a resource already in this state

First run the standard dev commands. Then use the same initialized state to change tags:

```bash
terraform plan -var-file=environments/updated.tfvars -out=update.tfplan
terraform apply update.tfplan
```

No new resource block or import is needed. Refresh can also detect external changes; decide whether configuration should restore the old value or represent the desired new value. Name/location/type changes may replace resources; examine the plan. To delete the managed example intentionally, keep its definition and use:

```bash
terraform plan -destroy -var-file=environments/updated.tfvars -out=destroy.tfplan
terraform apply destroy.tfplan
```

Removing a resource block also plans deletion in its state. This is different from a data source and different from removing only a state record.

Run commands from `07-update-managed/`. Create these files exactly at the paths shown.

### `07-update-managed/backend.tf`

```hcl
# Teaching examples use local state. Keep this separate from your ADO remote backend.
terraform {
  backend "local" {}
}
```

### `07-update-managed/environments/dev.tfvars`

```hcl
subscription_id = "abdb38d1-d80a-40c6-a158-f152d3dfb285"
location = "eastus"
resource_group_name = "rg-example-07"
tags = {"environment": "dev", "managed_by": "terraform"}
```

### `07-update-managed/environments/updated.tfvars`

```hcl
subscription_id = "abdb38d1-d80a-40c6-a158-f152d3dfb285"
location = "eastus"
resource_group_name = "rg-example-07"
tags = {"environment": "dev", "managed_by": "terraform", "owner": "platform-team"}
```

### `07-update-managed/main.tf`

```hcl
resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}
```

### `07-update-managed/outputs.tf`

```hcl
output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "resource_group_id" {
  value = azurerm_resource_group.this.id
}
```

### `07-update-managed/variables.tf`

```hcl
variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
```

### `07-update-managed/versions.tf`

```hcl
terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.9.0, < 5.0.0"
    }
  }
}

provider "azurerm" {
  environment     = "public"
  subscription_id = var.subscription_id
  features {}
}
```

## 08-refactor-managed: Move an already deployed resource into a module

This exercise intentionally creates a resource first so you can see a moved address. Run standard dev commands with the original main.tf. Then replace the active root files:

```bash
cp refactor/main.tf.txt main.tf
cp refactor/outputs.tf.txt outputs.tf
terraform init -reconfigure -backend-config="path=state/dev.tfstate"
terraform plan -var-file=environments/dev.tfvars -out=refactor.tfplan
terraform apply refactor.tfplan
```

The .txt files are templates and are not loaded by Terraform before copying. Same state, RG name, region and tags: the expected result is an address move, not replacement solely due to refactoring. If nothing has been deployed, start with the module immediately; no moved block is needed. All callers and outputs must reference module.resource_group.name after the move.

Run commands from `08-refactor-managed/`. Create these files exactly at the paths shown.

### `08-refactor-managed/backend.tf`

```hcl
# Teaching examples use local state. Keep this separate from your ADO remote backend.
terraform {
  backend "local" {}
}
```

### `08-refactor-managed/environments/dev.tfvars`

```hcl
subscription_id = "abdb38d1-d80a-40c6-a158-f152d3dfb285"
location = "eastus"
resource_group_name = "rg-example-08"
tags = {"environment": "dev", "managed_by": "terraform"}
```

### `08-refactor-managed/main.tf`

```hcl
resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}
```

### `08-refactor-managed/modules/resource-group/main.tf`

```hcl
resource "azurerm_resource_group" "this" {
  name     = var.name
  location = var.location
  tags     = var.tags
}
```

### `08-refactor-managed/modules/resource-group/outputs.tf`

```hcl
output "name" {
  value = azurerm_resource_group.this.name
}

output "id" {
  value = azurerm_resource_group.this.id
}
```

### `08-refactor-managed/modules/resource-group/variables.tf`

```hcl
variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
```

### `08-refactor-managed/modules/resource-group/versions.tf`

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.9.0"
    }
  }
}
```

### `08-refactor-managed/outputs.tf`

```hcl
output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "resource_group_id" {
  value = azurerm_resource_group.this.id
}
```

### `08-refactor-managed/refactor/main.tf.txt`

```hcl
module "resource_group" {
  source = "./modules/resource-group"

  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

moved {
  from = azurerm_resource_group.this
  to   = module.resource_group.azurerm_resource_group.this
}
```

### `08-refactor-managed/refactor/outputs.tf.txt`

```hcl
output "resource_group_name" {
  value = module.resource_group.name
}

output "resource_group_id" {
  value = module.resource_group.id
}
```

### `08-refactor-managed/variables.tf`

```hcl
variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
```

### `08-refactor-managed/versions.tf`

```hcl
terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.9.0, < 5.0.0"
    }
  }
}

provider "azurerm" {
  environment     = "public"
  subscription_id = var.subscription_id
  features {}
}
```

## 09-cross-subscription: Read in one subscription and create in another

Run case 01 first or set shared_resource_group_name to an existing RG in the original subscription. This case creates rg-example-pre-09 in the pre subscription and reads the original RG through azurerm.shared. The identity must have access to both subscriptions in the same tenant for this simple example. Different tenants need additional provider credentials/authentication configuration. A module needing the shared provider can receive `providers = { azurerm = azurerm.shared }`. Reading a VNet ID in another subscription does not itself attach a workload to it; service-specific cross-subscription network support must be checked. The pre state here owns only the new pre RG, not the read-only shared RG.

Run commands from `09-cross-subscription/`. Create these files exactly at the paths shown.

### `09-cross-subscription/backend.tf`

```hcl
# Teaching examples use local state. Keep this separate from your ADO remote backend.
terraform {
  backend "local" {}
}
```

### `09-cross-subscription/environments/dev.tfvars`

```hcl
subscription_id = "5a0c990d-7c4f-4842-92eb-9d9b01eab4c3"
location = "eastus"
resource_group_name = "rg-example-pre-09"
tags = {"environment": "dev", "managed_by": "terraform"}
shared_subscription_id = "abdb38d1-d80a-40c6-a158-f152d3dfb285"
shared_resource_group_name = "rg-example-01"
```

### `09-cross-subscription/main.tf`

```hcl
resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Reads an existing resource from the original subscription.
data "azurerm_resource_group" "shared" {
  provider = azurerm.shared
  name     = var.shared_resource_group_name
}
```

### `09-cross-subscription/outputs.tf`

```hcl
output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "resource_group_id" {
  value = azurerm_resource_group.this.id
}

output "shared_resource_group_id" {
  value = data.azurerm_resource_group.shared.id
}
```

### `09-cross-subscription/variables.tf`

```hcl
variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
variable "shared_subscription_id" {
  type = string
}

variable "shared_resource_group_name" {
  type = string
}
```

### `09-cross-subscription/versions.tf`

```hcl
terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.9.0, < 5.0.0"
    }
  }
}

provider "azurerm" {
  environment     = "public"
  subscription_id = var.subscription_id
  features {}
}

provider "azurerm" {
  alias           = "shared"
  environment     = "public"
  subscription_id = var.shared_subscription_id
  features {}
}
```

## Applying these cases to your real project

Your infrastructure root remains terraform/: main.tf calls modules or defines resources/data; variables.tf declares root inputs; outputs.tf exposes results; versions.tf configures the Azure provider; backend.tf configures the backend type; environments/dev.tfvars, test.tfvars, pre.tfvars, prod.tfvars assign values. Child code belongs under terraform/modules/<module-name>/. Bootstrap remains a separate root for state storage.

Dev and test share the dev VNet and subnet, and dev owns them. Preprod has its own subscription/backend/network and resource group. Every environment owns its own infrastructure RG. The network module and resource group module can coexist; the network module receives resource_group_name = module.resource_group.name. Do not invent another resource group resource when the module already owns it. For pipeline runs select infrastructure, environment, plan first; then apply. Do not paste the teaching local backend over your working remote backend.

After adding a module rerun init. If resource addresses are not deployed yet, no moved blocks are needed. Objects that exist manually need import to become owned. If a lookup fails, verify the name, RG, provider subscription, and deployment order. An undeclared variable must be declared in the root even if a child already declares a similarly named variable. An old root resource reference must be replaced with the module output after refactoring.

Sources: https://developer.hashicorp.com/terraform/language/block/module ; https://developer.hashicorp.com/terraform/language/block/import ; https://developer.hashicorp.com/terraform/language/modules/develop/refactoring ; https://developer.hashicorp.com/terraform/language/modules/develop/providers .
