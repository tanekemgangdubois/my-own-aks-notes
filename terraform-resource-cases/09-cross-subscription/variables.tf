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
