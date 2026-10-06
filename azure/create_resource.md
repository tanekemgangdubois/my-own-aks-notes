# When creating infrastructure with Terraform, first decide whether the resource exists and who should manage it.
| Situation | What to use | Example in your project |
|---|---|---|
| Resource does not exist; Terraform should create it | `resource` | Create a storage account |
| Resource exists; Terraform should only read it | `data` | Test reads dev’s VNet |
| Resource exists outside Terraform; Terraform should manage it | `import` plus a matching `resource` | Adopt an existing resource group |
| Resource is already managed by this Terraform state | Keep its resource configuration | Update tags on your storage account |
| Resource is managed by another environment’s state | Read it with `data` or published outputs | Test uses dev’s ACR |
| You want reusable configuration | `module` | Reuse a network definition in dev, pre, and prod |
| Resource is optional | `count` or `for_each` | Create an ACR everywhere except test |
| You need several similar resources | `for_each` | Create multiple subnets |
| You reorganize already managed resources | `moved` | Move a resource group into a module |
