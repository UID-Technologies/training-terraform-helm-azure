
# Lab: Create & Publish an Azure Resource Group Module on Terraform Registry

---

## Prerequisites

* Terraform installed (`terraform -v`)
* Azure CLI installed (`az login`)
* GitHub account (Terraform Registry uses GitHub)
* Terraform Registry account (sign in with GitHub → [registry.terraform.io](https://registry.terraform.io))

---

## **Step 1: Create a New GitHub Repo for Your Module**

1. Go to [GitHub](https://github.com) → Create a new repository

   * Name: `terraform-azurerm-resource-group`
   * Description: `Terraform module to create Azure Resource Groups`
   * Public repository (required for Terraform Registry)
   * Initialize with `README.md`

**Naming Convention:**
`terraform-<PROVIDER>-<NAME>` → e.g. `terraform-azurerm-resource-group`

---

## **Step 2: Clone Repo Locally**

```bash
git clone https://github.com/<your-username>/terraform-azurerm-resource-group.git
cd terraform-azurerm-resource-group
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

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}
```

### `variables.tf`

```hcl
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
```

### `outputs.tf`

```hcl
output "resource_group_id" {
  description = "The ID of the resource group"
  value       = azurerm_resource_group.this.id
}

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.this.name
}
```

### `README.md`

````markdown
# Azure Resource Group Terraform Module

This module creates an Azure Resource Group.

## Usage

```hcl
module "rg" {
  source  = "github.com/<your-username>/terraform-azurerm-resource-group"
  resource_group_name = "my-rg"
  location            = "eastus"
  tags = {
    environment = "dev"
  }
}
````

## Outputs

* `resource_group_id`
* `resource_group_name`

````

---

## **Step 4: Commit & Push Code**
```bash
git add .
git commit -m "Initial commit: Azure Resource Group module"
git push origin main
````

---

## **Step 5: Tag a Release**

Terraform Registry requires a **semantic version tag** (`v1.0.0`, `v1.1.0`, etc.)

```bash
git tag v1.0.0
git push origin v1.0.0
```

---

## **Step 6: Publish on Terraform Registry**

1. Go to [Terraform Registry Publish Page](https://registry.terraform.io/namespaces)
2. Click **Publish Module**
3. Choose your GitHub repo: `terraform-azurerm-resource-group`
4. Registry will auto-detect the repo and release `v1.0.0`
5. After publishing, your module will be available at:

   ```
   https://registry.terraform.io/modules/<your-username>/resource-group/azurerm
   ```

---

## **Step 7: Consume the Module**

Now test it from another Terraform project.

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

module "rg" {
  source  = "<your-username>/resource-group/azurerm"
  version = "1.0.0"

  resource_group_name = "demo-rg"
  location            = "eastus"
  tags = {
    owner = "varun"
    env   = "lab"
  }
}
```

### Run:

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

You’ll see a new Resource Group created in Azure.

---

## **Step 8: Update & Republish (Optional)**

* Make changes (e.g., add support for `lock`, `tags`)
* Commit & push
* Tag a new version:

  ```bash
  git tag v1.1.0
  git push origin v1.1.0
  ```
* Terraform Registry auto-updates with the new release.

---

# Final Outcome

* You built a **Terraform module** for Azure Resource Groups
* Published it to **Terraform Registry**
* Reused it across projects with just a few lines of code

---
