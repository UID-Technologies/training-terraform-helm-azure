# Exercise 1: create resource group in azure using terraform

- Azure Subscription - free trial account
- Azure CLI - https://learn.microsoft.com/en-us/cli/azure/install-azure-cli


> az --version

> az login  or  az login --tenant <tenant id>

> az account show


create tf file

# add provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}



> terraform init      //download the azure provider plugin and prepare the working directory

> terraform validate	// ensures syntax and configuration are correct

> terraform fmt		// format the code

> terraform plan	// show what terraform will create, you should see "rg-terraform-lab" will be created 

> terraform apply	// type yes when promoted, terraform will create the resource group

> terraform apply --auto-approve

> terraform destroy --auto-approve


provider "azurerm" {
  features {}
}

# create resource group
resource "azurerm_resource_group" "rg" {
  name = "rg-terraform-lab"
  location = "East US"
}



# exercise 2: create virtual network (VNet)

- resource group
- virtual network
- subnets


main.tf - main terraform config
variables.tf - variable for customization
terraform.tfvars - values for variables


# exercise 3: working with files

output "printblock" {
  #value = "${ path.module }/data.txt"
  value = file("${ path.module }/data.txt")
}



# exercise 4: create a virtual machine 

- resource group
- vnet
- subnet
- virtual machine


# exercise 5: add NSG to secure VM in azure





