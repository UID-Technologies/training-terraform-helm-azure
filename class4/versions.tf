terraform {
  required_version = ">= 1.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "7f12001e-fded-41fd-b58b-f041b465dbed"
  tenant_id       = "de52d802-5286-4ced-88f2-a6fee88d2b34"
  # uses azure CLI auth by default (az login)

}