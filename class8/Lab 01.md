# Lab: Terraform + Git Integration & State Management on Azure

## **Pre-requisites**

* Azure Subscription with `Contributor` access
* Terraform installed (v1.5+)
* Git installed
* GitHub or Azure DevOps Git repository
* Azure CLI installed
* Storage Account + Container for remote state (will create in the lab)

---

## **Lab 1: Git Initialization**

**Objective:** Create a new Git repository for Terraform code.

1. Create a new project directory:

   ```bash
   mkdir tf-azure-lab && cd tf-azure-lab
   ```

2. Initialize Git:

   ```bash
   git init
   ```

3. Create a `.gitignore` file:

   ```gitignore
   .terraform/
   *.tfstate
   *.tfstate.backup
   crash.log
   ```

   > Ensures sensitive files like state are not committed.

4. Add and commit:

   ```bash
   git add .
   git commit -m "Initial Terraform project setup"
   ```

---

## **Lab 2: Git Commit & Push**

**Objective:** Push code to remote GitHub/Azure DevOps.

1. Create a remote repo (GitHub/Azure DevOps).
2. Link remote:

   ```bash
   git remote add origin <repo-url>
   ```
3. Push:

   ```bash
   git branch -M main
   git push -u origin main
   ```

---

## **Lab 3: Git Branching**

**Objective:** Work in a feature branch.

1. Create and switch:

   ```bash
   git checkout -b feature/add-rg
   ```
2. Add Terraform file:

   ```hcl
   resource "azurerm_resource_group" "rg" {
     name     = "rg-tf-lab"
     location = "East US"
   }
   ```
3. Commit changes:

   ```bash
   git add .
   git commit -m "Added Resource Group module"
   ```
4. Push and create PR/MR:

   ```bash
   git push origin feature/add-rg
   ```

---

## **Lab 4: Git Tagging**

**Objective:** Tag releases for infra versions.

1. Create tag:

   ```bash
   git tag v1.0.0
   ```
2. Push tags:

   ```bash
   git push origin v1.0.0
   ```

---

## **Lab 5: Security Challenges in TFState**

**Objective:** Understand risks of committing state to Git.

* Run `terraform apply` locally.
* Observe files generated: `terraform.tfstate`, `.terraform.lock.hcl`.
* Discuss risks:

  * Secrets (passwords, keys) stored in plaintext in state.
  * TFState diffs show sensitive changes.
* Demo: open `terraform.tfstate` and note credentials.

**Best Practice:** Never commit `tfstate` to Git.

---

## **Lab 6: Remote State Management with Azure**

**Objective:** Configure backend in Azure Storage.

1. Create storage account + container:

   ```bash
   az group create -n rg-tfstate -l eastus
   az storage account create -n tflabstorage$RANDOM -g rg-tfstate -l eastus --sku Standard_LRS
   az storage container create -n tfstate --account-name <storage-name>
   ```

2. Add backend block in `main.tf`:

   ```hcl
   terraform {
     backend "azurerm" {
       resource_group_name   = "rg-tfstate"
       storage_account_name  = "<storage-name>"
       container_name        = "tfstate"
       key                   = "terraform.tfstate"
     }
   }
   ```

3. Initialize:

   ```bash
   terraform init -backend-config="resource_group_name=rg-tfstate" \
     -backend-config="storage_account_name=<storage-name>" \
     -backend-config="container_name=tfstate" \
     -backend-config="key=terraform.tfstate"
   ```

---

## **Lab 7: Terraform State Management**

**Objective:** Explore state commands.

1. Show current state:

   ```bash
   terraform state list
   ```

2. Show a resource:

   ```bash
   terraform state show azurerm_resource_group.rg
   ```

3. Remove from state:

   ```bash
   terraform state rm azurerm_resource_group.rg
   ```

4. Refresh state:

   ```bash
   terraform refresh
   ```

---

## **Lab 8: Importing Existing Resources**

**Objective:** Import Azure resources into state.

1. Create resource group manually:

   ```bash
   az group create -n rg-import-lab -l eastus
   ```

2. Define resource in Terraform:

   ```hcl
   resource "azurerm_resource_group" "rg_imported" {
     name     = "rg-import-lab"
     location = "East US"
   }
   ```

3. Run import:

   ```bash
   terraform import azurerm_resource_group.rg_imported /subscriptions/<sub_id>/resourceGroups/rg-import-lab
   ```

4. Verify with:

   ```bash
   terraform state list
   ```




