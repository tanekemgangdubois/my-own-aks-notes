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
