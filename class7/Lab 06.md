

# Lab: Create & Publish an Azure VNet Module on Terraform Registry

---

##  Prerequisites

Same as before (Terraform, Azure CLI, GitHub, Terraform Registry account).

---

## **Step 1: Create GitHub Repo**

* Repo name: **`terraform-azurerm-vnet`**
* Public repo, initialized with `README.md`
* Description: *Terraform module to create Azure Virtual Networks (VNet) and Subnets*

---

## **Step 2: Clone Repo Locally**

```bash
git clone https://github.com/<your-username>/terraform-azurerm-vnet.git
cd terraform-azurerm-vnet
```

---

## **Step 3: Create Module Files**

### `main.tf`

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Create Virtual Network
resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Create Subnets (for each item in subnet list)
resource "azurerm_subnet" "this" {
  for_each             = { for s in var.subnets : s.name => s }
  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value.address_prefix]
}
```

---

### `variables.tf`

```hcl
variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
}

variable "address_space" {
  description = "The address space for the VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "location" {
  description = "Azure location for VNet"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Resource Group where VNet will be created"
  type        = string
}

variable "subnets" {
  description = "List of subnets to create"
  type = list(object({
    name           = string
    address_prefix = string
  }))
  default = []
}

variable "tags" {
  description = "Tags for VNet"
  type        = map(string)
  default     = {}
}
```

---

### `outputs.tf`

```hcl
output "vnet_id" {
  description = "The ID of the Virtual Network"
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "The name of the Virtual Network"
  value       = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  description = "IDs of all subnets created"
  value       = { for k, s in azurerm_subnet.this : k => s.id }
}
```

---

### `README.md`

````markdown
# Azure VNet Terraform Module

This module creates an Azure Virtual Network and optional subnets.

## Usage

```hcl
module "vnet" {
  source  = "github.com/<your-username>/terraform-azurerm-vnet"
  vnet_name           = "my-vnet"
  resource_group_name = "demo-rg"
  location            = "eastus"
  address_space       = ["10.0.0.0/16"]

  subnets = [
    {
      name           = "subnet1"
      address_prefix = "10.0.1.0/24"
    },
    {
      name           = "subnet2"
      address_prefix = "10.0.2.0/24"
    }
  ]

  tags = {
    environment = "dev"
  }
}
````

## Outputs

* `vnet_id`
* `vnet_name`
* `subnet_ids`

````

---

## **Step 4: Commit & Push Code**
```bash
git add .
git commit -m "Initial commit: Azure VNet module"
git push origin main
````

---

## **Step 5: Tag a Release**

```bash
git tag v1.0.0
git push origin v1.0.0
```

---

## **Step 6: Publish on Terraform Registry**

1. Go to [Terraform Registry](https://registry.terraform.io/namespaces)
2. Click **Publish Module**
3. Select `terraform-azurerm-vnet`
4. Registry detects version `v1.0.0`
5. Module is published at:

   ```
   https://registry.terraform.io/modules/<your-username>/vnet/azurerm
   ```

---

## **Step 7: Consume the Module**

### `main.tf` (another project)

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "rg" {
  source  = "<your-username>/resource-group/azurerm"
  version = "1.0.0"

  resource_group_name = "demo-rg"
  location            = "eastus"
}

module "vnet" {
  source  = "<your-username>/vnet/azurerm"
  version = "1.0.0"

  vnet_name           = "demo-vnet"
  resource_group_name = module.rg.resource_group_name
  location            = "eastus"
  address_space       = ["10.0.0.0/16"]

  subnets = [
    {
      name           = "frontend"
      address_prefix = "10.0.1.0/24"
    },
    {
      name           = "backend"
      address_prefix = "10.0.2.0/24"
    }
  ]
}
```

### Run:

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

You’ll get:

* A **VNet**
* Two **Subnets**
* Outputs showing VNet ID, Name, and Subnet IDs

---

## **Step 8: Update & Republish**

* Add NSG, DNS servers, etc. to the module
* Commit & push changes
* Tag new version (`v1.1.0`)
* Push to GitHub → Registry auto-updates

---

# Final Outcome

* You created a **Terraform module for Azure VNet**
* Published it to the **Terraform Registry**
* Consumed it with **Resource Group module** in another project

---

