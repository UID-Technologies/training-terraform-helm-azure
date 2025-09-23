# Lab Exercise: Terraform Workspaces on Azure

## Introduction to Terraform Workspaces

### What is a Workspace?

* A **Terraform workspace** is like a separate “instance” of your Terraform state.
* By default, Terraform starts with a workspace named **default**.
* You can create additional workspaces (e.g., **dev**, **qa**, **prod**) so the same codebase can deploy infrastructure with different state files.

This is very useful in **multi-environment Azure deployments** where you want separate VNets, Resource Groups, or VMs for each environment but still use the same Terraform code.

---

### Why Use Workspaces? (Use Cases)

1. **Multi-Environment Management** – Deploy dev, staging, and prod with one codebase.
2. **State Separation** – Each workspace has its own state file, reducing conflicts.
3. **Cost Optimization** – You can spin up dev/test environments quickly, then destroy them without touching prod.
4. **Simplicity** – No need to duplicate folders or maintain separate `.tf` files.

---

## Prerequisites

1. Terraform (≥ 1.5.x) installed
2. Azure CLI installed & authenticated (`az login`)
3. An Azure subscription

---

## Lab Objective

* Use Terraform Workspaces to manage **multiple environments** (`dev`, `prod`) with one codebase.
* Deploy environment-specific **Resource Groups, Storage Accounts, and Virtual Machines**.
* Understand how to vary configurations (VM size, name) per workspace.

---

## Step 1: Setup Working Directory

```bash
mkdir terraform-workspaces-azure
cd terraform-workspaces-azure
```
---


## Step 2: Project Structure

```
terraform-workspaces-azure/
 ├── main.tf
 ├── variables.tf
 ├── outputs.tf
 └── terraform.tfvars
```

---

## Step 3: Define Variables

`variables.tf`

```hcl
variable "location" {
  description = "Azure Region"
  default     = "Central India"
}

variable "vm_size" {
  description = "VM Size"
  type        = string
}

variable "admin_username" {
  default = "azureuser"
}

variable "admin_password" {
  description = "Admin password for VM"
  type        = string
  sensitive   = true
}
```

---

## Step 4: Main Configuration

`main.tf`

```hcl
provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-${terraform.workspace}"
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${terraform.workspace}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "subnet-${terraform.workspace}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP
resource "azurerm_public_ip" "pip" {
  name                = "pip-${terraform.workspace}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Network Interface
resource "azurerm_network_interface" "nic" {
  name                = "nic-${terraform.workspace}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

# Linux VM
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-${terraform.workspace}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [azurerm_network_interface.nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
```

---

## Step 5: Define Environment-Specific Variables

`terraform.tfvars` is **optional** for common variables, but environment-specific values will be handled via workspaces.

To keep it simple, we’ll define **per-workspace defaults** in `main.tf` using locals:

```hcl
locals {
  vm_size_map = {
    dev  = "Standard_B1s"
    prod = "Standard_B2s"
  }
}

# Override VM size based on workspace
variable "vm_size" {
  default = ""
}

# Assign from map
resource "azurerm_linux_virtual_machine" "vm" {
  # same config as before, just replace size
  size = local.vm_size_map[terraform.workspace]
  ...
}
```

---

## Step 6: Initialize Terraform

```bash
terraform init
```

---

## Step 7: Create Workspaces

```bash
terraform workspace new dev
terraform workspace new prod
```

List them:

```bash
terraform workspace list
```

---

## Step 8: Deploy Dev Environment

```bash
terraform workspace select dev
terraform apply -auto-approve
```

Expected Azure resources:

* Resource Group: `rg-dev`
* VM: `vm-dev` (size: **Standard\_B1s**)

---

## Step 9: Deploy Prod Environment

```bash
terraform workspace select prod
terraform apply -auto-approve
```

Expected Azure resources:

* Resource Group: `rg-prod`
* VM: `vm-prod` (size: **Standard\_B2s**)

---

## Step 10: Verify

Check in Azure Portal:

* Under **Resource Groups**, you should see `rg-dev` and `rg-prod`.
* Each has its own **VM + Networking resources**.

---

## Step 11: Cleanup

Destroy **only dev**:

```bash
terraform workspace select dev
terraform destroy -auto-approve
```

Destroy **only prod**:

```bash
terraform workspace select prod
terraform destroy -auto-approve
```

---

## Learning Outcomes

* Understood **Terraform Workspaces** and their role in **multi-environment deployments**.
* Created **separate environments (dev, prod)** using the same codebase.
* Learned how to **customize configurations** per workspace (VM size, names).
* Practiced switching, applying, and destroying workspaces safely.

---

