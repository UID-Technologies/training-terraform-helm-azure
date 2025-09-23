
#  Lab Exercise: Using Terraform Registry with Azure

##  Introduction to Terraform Registry

###  What is the Terraform Registry?

* The **Terraform Registry** is a public (and private) library of reusable Terraform modules and providers.
* Providers (like `azurerm`, `aws`, `gcp`) allow Terraform to talk to cloud APIs.
* Modules are **pre-built infrastructure templates** (e.g., VNet, VM, Storage).

### Why use Registry Modules?

1. **Reusability** – Avoid writing boilerplate code.
2. **Best Practices** – Modules are often created and tested by cloud experts.
3. **Consistency** – Standardized deployments across teams.
4. **Faster Development** – Quickly build infra without writing everything from scratch.

In this lab, we’ll use the **official Azure Resource Group module** from the Terraform Registry.

---

## Prerequisites

1. Terraform (≥ 1.5.x)
2. Azure CLI authenticated (`az login`)
3. An Azure subscription

---

## Step 1: Create Project Folder

```bash
mkdir terraform-registry-azure
cd terraform-registry-azure
```

Project structure:

```
terraform-registry-azure/
 ├── main.tf
 ├── variables.tf
 └── outputs.tf
```

---

## Step 2: Define Provider

`main.tf`

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```

---

##  Step 3: Use Azure Resource Group Module from Registry

We’ll use the **official Azure Resource Group module**:
 [https://registry.terraform.io/modules/Azure/resource-group/azurerm/latest](https://registry.terraform.io/modules/Azure/resource-group/azurerm/latest)

Add this to `main.tf`:

```hcl
module "rg" {
  source  = "Azure/resource-group/azurerm"
  version = "2.0.0"

  location = var.location
  prefix   = var.prefix
  tags = {
    environment = var.environment
    owner       = "Terraform-Lab"
  }
}
```

---

## Step 4: Define Variables

`variables.tf`

```hcl
variable "location" {
  description = "Azure region"
  default     = "Central India"
}

variable "prefix" {
  description = "Prefix for resource group name"
  default     = "tfreg"
}

variable "environment" {
  description = "Environment type"
  default     = "dev"
}
```

---

## Step 5: Add Outputs

`outputs.tf`

```hcl
output "resource_group_name" {
  description = "The name of the resource group"
  value       = module.rg.name
}

output "resource_group_id" {
  description = "The ID of the resource group"
  value       = module.rg.id
}
```

---

## Step 6: Initialize Terraform

```bash
terraform init
```
 This will:

* Download the `azurerm` provider.
* Download the Resource Group module from the Terraform Registry.

---

## Step 7: Plan & Apply

```bash
terraform plan
terraform apply -auto-approve
```

Terraform will create:

* A **Resource Group** in Azure with a name like: `tfreg-dev-rg`.

---

## Step 8: Verify

* Go to **Azure Portal → Resource Groups**.
* You should see the new RG with tags applied.

---

## Step 9: Destroy Resources

```bash
terraform destroy -auto-approve
```

---

## Learning Outcomes

By completing this lab, you:

* Learned what the **Terraform Registry** is.
* Used an **official Azure module** from the Registry.
* Deployed a **Resource Group** in Azure using just a few lines of code.
* Understood how **modules can be versioned and reused**.

---
