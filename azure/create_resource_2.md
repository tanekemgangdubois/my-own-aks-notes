| Folder | Situation | What it demonstrates |
|---|---|---|
| `01-new-resource` | Resource doesn’t exist | Create a resource group with `resource` |
| `02-read-existing` | Resource exists; you only need to read it | Find a resource group with `data` |
| `03-import-existing` | Resource was created manually | Adopt it using `resource` and `import` |
| `04-reusable-module` | You want reusable configuration | Create a resource group through a module |
| `05-share-and-optional` | Dev owns a resource; test shares it | Conditional ACR creation and lookup |
| `06-multiple-subnets` | You need several similar resources | Create a VNet and subnets with `for_each` |
| `07-update-managed` | Terraform already manages the resource | Update tags using the same state |
| `08-refactor-managed` | An existing resource moves into a module | Preserve ownership using `moved` |
| `09-cross-subscription` | Resources are in different subscriptions | Use a provider alias |

# Every example includes these files:
| File | What belongs there |
|---|---|
| `versions.tf` | Terraform requirements and Azure provider configuration |
| `backend.tf` | State backend configuration |
| `variables.tf` | Input variable declarations |
| `main.tf` | Resources, data sources, or module calls |
| `outputs.tf` | Values returned by the configuration |
| `environments/dev.tfvars` | Actual environment values |
