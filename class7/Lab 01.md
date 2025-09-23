# Lab Exercise: Terraform Modules on Azure

##  Objective

* Understand Terraform modules and their benefits (reusability, DRY principle).
* Create a reusable **Terraform module** for an **Azure Virtual Network (VNet)**.
* Use the module in a root configuration to deploy a **VM inside the VNet**.

---

## Prerequisites

1. **Installed Tools**:

   * Terraform (≥ 1.5.x)
   * Azure CLI
   * Visual Studio Code (optional, for editing)
2. **Azure Setup**:

   * Azure Subscription
   * Run `az login` to authenticate
   * Run `az account set --subscription "<your-subscription-id>"`

---

## Introduction to Terraform Modules

### What is a Terraform Module?

A **Terraform module** is simply a **collection of `.tf` files grouped together** to manage a particular piece of infrastructure as a reusable component.

Think of a module like a **function in programming**:

* Instead of repeating the same Terraform code everywhere, you define it once in a module.
* Then you “call” that module from your main/root configuration, passing variables to customize it.

Terraform itself treats every `.tf` file in a directory as part of a module. The root folder where you run `terraform init` is also considered the **root module**.

---

### Why Use Modules? (Benefits)

1. **Reusability** – Write once, use everywhere (e.g., same VNet module for Dev, QA, Prod).
2. **Maintainability** – Easier to manage & update infrastructure.
3. **Consistency** – Ensures teams follow the same standards and naming conventions.
4. **Collaboration** – Teams can share modules internally or via the Terraform Registry.
5. **Abstraction** – Complex infrastructure (e.g., VNet + Subnets + NSG) can be wrapped in a simple interface.

---

### Real-World Use Cases of Modules

* **Networking Module** – Create VNet, Subnets, and NSGs with standard CIDR ranges.
* **Compute Module** – Define VM templates (size, OS, security, tagging) for different environments.
* **Storage Module** – Standardize Azure Storage Account creation with encryption and access policies.
* **AKS/EKS/GKE Module** – Deploy Kubernetes clusters with a fixed baseline configuration.
* **Multi-Environment Setup** – Same module can be reused for Dev, QA, Staging, and Production by passing different variables.

Example:
Instead of writing the same 50 lines of VNet code in 10 projects, you just call a **VNet module**:

```hcl
module "vnet" {
  source              = "./modules/vnet"
  vnet_name           = "vnet-dev"
  resource_group_name = "rg-dev"
  location            = "Central India"
  address_space       = ["10.0.0.0/16"]
  subnet_name         = "subnet-dev"
  subnet_prefix       = ["10.0.1.0/24"]
}
```

---

## Step 1: Create the Working Directory

```bash
mkdir terraform-modules-azure-lab
cd terraform-modules-azure-lab
```

Folder structure we’ll build:

```
terraform-modules-azure-lab/
 ├── main.tf
 ├── variables.tf
 ├── outputs.tf
 └── modules/
     └── vnet/
         ├── main.tf
         ├── variables.tf
         └── outputs.tf
```

---

## Step 2: Define the VNet Module

Create `modules/vnet/main.tf`:

```hcl
resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
}

resource "azurerm_subnet" "this" {
  name                 = var.subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.subnet_prefix
}
```

`modules/vnet/variables.tf`:

```hcl
variable "vnet_name" {}
variable "location" {}
variable "resource_group_name" {}
variable "address_space" {
  type = list(string)
}
variable "subnet_name" {}
variable "subnet_prefix" {
  type = list(string)
}
```

`modules/vnet/outputs.tf`:

```hcl
output "subnet_id" {
  value = azurerm_subnet.this.id
}
output "vnet_id" {
  value = azurerm_virtual_network.this.id
}
```

---

## Step 3: Root Configuration

Now, in the root folder, create `main.tf`:

```hcl
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-terraform-lab"
  location = "Central India"
}

module "vnet" {
  source              = "./modules/vnet"
  vnet_name           = "vnet-lab"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
  subnet_name         = "subnet-lab"
  subnet_prefix       = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name                = "nic-lab"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.vnet.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-lab"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

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

## Step 4: Define Variables & Outputs

`variables.tf`:

```hcl
variable "location" {
  default = "Central India"
}
```

`outputs.tf`:

```hcl
output "vm_ip" {
  value = azurerm_linux_virtual_machine.vm.public_ip_address
}
```

---

## Step 5: Initialize & Apply

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

---

## Step 6: Verify Deployment

* Check VM IP:

  ```bash
  terraform output vm_ip
  ```
* SSH into VM:

  ```bash
  ssh azureuser@<vm_ip>
  ```

---

## Step 7: Cleanup

```bash
terraform destroy -auto-approve
```

---

## Learning Outcomes

* You created and used a **Terraform module** for a VNet.
* You reused the module in a **root configuration** to deploy a **VM**.
* You learned **how modules enforce DRY principles** and improve reusability in Azure IaC.

---

Would you like me to extend this lab to include **multiple reusable modules** (like NSG, Storage, Key Vault) so you can build a full production-ready setup, or keep it minimal for training beginners?
