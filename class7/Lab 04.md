# Lab Exercise: Chaining Multiple Terraform Registry Modules (Azure Full Environment)

## Introduction

### What Are Chained Modules?

* **Chaining modules** means using the **outputs of one module** as **inputs to another**.
* Example:

  * Resource Group module → gives RG name
  * VNet module → needs RG name
  * VM module → needs VNet + Subnet IDs

### Why Chain Modules?

1. **Separation of Concerns** – Each module manages one component (RG, VNet, VM).
2. **Reusability** – Modules can be reused independently.
3. **Scalability** – Easier to extend (e.g., add NSG or Storage module later).

---

## Prerequisites

1. Terraform (≥ 1.5.x)
2. Azure CLI authenticated (`az login`)
3. SSH Key Pair (for VM login):

   ```bash
   ssh-keygen -t rsa -b 2048 -f ~/.ssh/azure_terraform_key
   ```

---

## Step 1: Project Structure

```bash
mkdir terraform-registry-chaining
cd terraform-registry-chaining
```

```
terraform-registry-chaining/
 ├── main.tf
 ├── variables.tf
 └── outputs.tf
```

---

## Step 2: Define Variables

`variables.tf`

```hcl
variable "location" {
  default = "Central India"
}

variable "prefix" {
  default = "tfchain"
}

variable "environment" {
  default = "dev"
}

variable "admin_username" {
  default = "azureuser"
}

variable "public_key_path" {
  description = "Path to SSH Public Key"
  default     = "~/.ssh/azure_terraform_key.pub"
}
```

---

## Step 3: Chain Modules

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

# -------------------
# Resource Group
# -------------------
module "rg" {
  source  = "Azure/resource-group/azurerm"
  version = "2.0.0"

  location = var.location
  prefix   = var.prefix
  tags = {
    environment = var.environment
  }
}

# -------------------
# Virtual Network + Subnet
# -------------------
module "vnet" {
  source  = "Azure/network/azurerm"
  version = "3.5.0"

  resource_group_name = module.rg.name
  address_space       = ["10.0.0.0/16"]

  subnets = [
    {
      name           = "subnet1"
      address_prefix = "10.0.1.0/24"
    }
  ]

  location = var.location
  prefix   = var.prefix
}

# -------------------
# Virtual Machine
# -------------------
module "vm" {
  source  = "Azure/compute/azurerm"
  version = "4.2.0"

  resource_group_name = module.rg.name
  location            = var.location
  admin_username      = var.admin_username
  ssh_key_path        = var.public_key_path

  vm_os_simple        = "UbuntuServer"
  vm_size             = "Standard_B1s"

  public_ip_dns       = "${var.prefix}-${var.environment}-vm"
  vnet_subnet_id      = module.vnet.vnet_subnets[0]
}
```

---

## Step 4: Outputs

`outputs.tf`

```hcl
output "resource_group_name" {
  value = module.rg.name
}

output "vnet_name" {
  value = module.vnet.vnet_name
}

output "subnet_ids" {
  value = module.vnet.vnet_subnets
}

output "vm_public_ip" {
  value = module.vm.public_ip_address
}
```

---

##  Step 5: Initialize Terraform

```bash
terraform init
```
 This downloads:

* `azurerm` provider
* `Azure/resource-group` module
* `Azure/network` module
* `Azure/compute` module

---

## Step 6: Plan & Apply

```bash
terraform plan
terraform apply -auto-approve
```

Terraform will provision:

* Resource Group: `tfchain-dev-rg`
* Virtual Network: `vnet-tfchain-dev`
* Subnet: `subnet1`
* VM: `vm-tfchain-dev` with Public IP

---

## Step 7: Verify Deployment

* In **Azure Portal → Resource Groups**, check the new RG.
* Inside it, confirm:

  * VNet + Subnet
  * VM with public IP

To SSH into the VM:

```bash
ssh -i ~/.ssh/azure_terraform_key azureuser@<vm_public_ip>
```

---

## Step 8: Destroy

```bash
terraform destroy -auto-approve
```

---

## Learning Outcomes

* Learned how to **chain multiple registry modules together**.
* Deployed a full Azure environment: **Resource Group + VNet + Subnet + VM**.
* Understood how **module outputs** can be passed as **inputs to other modules**.
* Practiced clean, modular, and reusable Terraform design.

---

Next Level:

* Add **NSG module** and attach it to the subnet.
* Add **Storage module** for VM disks.
* Use **Terraform Workspaces** with these chained modules for multi-environment infra.

---


let’s extend the **chained Terraform Registry lab** by adding:

1. **NSG Module** → attach it to the Subnet for security.
2. **Storage Module** → create a Storage Account for VM disks/logs.

This gives us a **more production-like Azure environment**.

---

#  Extended Lab: Chained Registry Modules with NSG + Storage

##  What’s New

* **Network Security Group (NSG)**: Controls inbound/outbound traffic for the subnet.
* **Storage Account**: Provides a place to store VM boot diagnostics and logs.

---

##  Step 1: Update Project Structure

We’ll continue inside the same project folder:

```
terraform-registry-chaining/
 ├── main.tf
 ├── variables.tf
 └── outputs.tf
```

---

##  Step 2: Add Variables

Update `variables.tf`:

```hcl
variable "location" {
  default = "Central India"
}

variable "prefix" {
  default = "tfchain"
}

variable "environment" {
  default = "dev"
}

variable "admin_username" {
  default = "azureuser"
}

variable "public_key_path" {
  description = "Path to SSH Public Key"
  default     = "~/.ssh/azure_terraform_key.pub"
}

variable "storage_account_tier" {
  default = "Standard"
}

variable "storage_replication_type" {
  default = "LRS"
}
```

---

##  Step 3: Add NSG Module

 Registry: [Azure/network-security-group/azurerm](https://registry.terraform.io/modules/Azure/network-security-group/azurerm/latest)

In `main.tf` add after the VNet module:

```hcl
# -------------------
# Network Security Group (NSG)
# -------------------
module "nsg" {
  source  = "Azure/network-security-group/azurerm"
  version = "3.0.0"

  resource_group_name = module.rg.name
  location            = var.location
  prefix              = "${var.prefix}-${var.environment}"

  security_rules = [
    {
      name                       = "allow-ssh"
      priority                   = 1001
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "allow-http"
      priority                   = 1002
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
}
```

 Attach NSG to Subnet in VNet module call:

```hcl
module "vnet" {
  source  = "Azure/network/azurerm"
  version = "3.5.0"

  resource_group_name = module.rg.name
  address_space       = ["10.0.0.0/16"]

  subnets = [
    {
      name           = "subnet1"
      address_prefix = "10.0.1.0/24"
      nsg_id         = module.nsg.network_security_group_id
    }
  ]

  location = var.location
  prefix   = var.prefix
}
```

---

## Step 4: Add Storage Module

 Registry: [Azure/storage-account/azurerm](https://registry.terraform.io/modules/Azure/storage-account/azurerm/latest)

In `main.tf` add:

```hcl
# -------------------
# Storage Account
# -------------------
module "storage" {
  source  = "Azure/storage-account/azurerm"
  version = "2.0.0"

  resource_group_name       = module.rg.name
  location                  = var.location
  prefix                    = "${var.prefix}${var.environment}"
  account_tier              = var.storage_account_tier
  account_replication_type  = var.storage_replication_type
}
```

---

## Step 5: Update VM Module to Use Storage

```hcl
module "vm" {
  source  = "Azure/compute/azurerm"
  version = "4.2.0"

  resource_group_name = module.rg.name
  location            = var.location
  admin_username      = var.admin_username
  ssh_key_path        = var.public_key_path

  vm_os_simple        = "UbuntuServer"
  vm_size             = "Standard_B1s"

  public_ip_dns       = "${var.prefix}-${var.environment}-vm"
  vnet_subnet_id      = module.vnet.vnet_subnets[0]

  # Boot diagnostics stored in the Storage Account
  boot_diagnostics_storage_uri = module.storage.primary_blob_endpoint
}
```

---

## Step 6: Outputs

Update `outputs.tf`:

```hcl
output "resource_group_name" {
  value = module.rg.name
}

output "vnet_name" {
  value = module.vnet.vnet_name
}

output "subnet_ids" {
  value = module.vnet.vnet_subnets
}

output "nsg_id" {
  value = module.nsg.network_security_group_id
}

output "storage_account_name" {
  value = module.storage.name
}

output "vm_public_ip" {
  value = module.vm.public_ip_address
}
```

---

## Step 7: Run the Deployment

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

Terraform will create:

* **Resource Group**
* **VNet + Subnet (with NSG attached)**
* **NSG (rules for SSH + HTTP)**
* **Storage Account**
* **VM with boot diagnostics stored in Storage Account**

---

## Step 8: Verify in Azure

* Go to **Azure Portal → Resource Groups → tfchain-dev-rg**
* Confirm:
  - VNet + Subnet
  - NSG attached to subnet
  - Storage Account created
  - VM deployed with Public IP

Test SSH:

```bash
ssh -i ~/.ssh/azure_terraform_key azureuser@<vm_public_ip>
```

---

## Step 9: Destroy

```bash
terraform destroy -auto-approve
```

---

##  Learning Outcomes

* Added **Network Security Group (NSG)** module for subnet-level security.
* Added **Storage Account** module for VM boot diagnostics.
* Learned how to **chain multiple modules (RG → VNet → NSG → Storage → VM)**.
* Built a **more production-ready Azure environment** using Registry modules.

---
