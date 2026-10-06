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
