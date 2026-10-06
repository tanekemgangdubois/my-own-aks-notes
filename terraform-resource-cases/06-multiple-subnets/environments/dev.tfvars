subscription_id = "abdb38d1-d80a-40c6-a158-f152d3dfb285"
location = "eastus"
resource_group_name = "rg-example-06"
tags = {"environment": "dev", "managed_by": "terraform"}
vnet_name = "VNET-EXAMPLE-06"
vnet_address_space = ["10.60.0.0/16"]
subnets = {"snet-app": ["10.60.1.0/24"], "snet-vm": ["10.60.2.0/24"]}
