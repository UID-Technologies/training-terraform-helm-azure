
# Lab Guide: Terraform Cloud with Azure

## **Prerequisites**

* Terraform CLI (v1.5+ installed)
* Terraform Cloud account ([https://app.terraform.io](https://app.terraform.io))
* Azure Subscription with `Contributor` role
* Azure CLI installed and logged in (`az login`)
* GitHub (or local Git) for storing Terraform code

---

## **Lab 1: Introduction to Terraform Cloud**

**Objective:** Understand Terraform Cloud and set up an organization/workspace.

1. Go to [Terraform Cloud](https://app.terraform.io) → Sign up / Log in.
2. Create a new **Organization** (example: `tfcloud-azure-lab`).
3. Create a **Workspace**:

   * **Name:** `azure-rg-lab`
   * **Execution Mode:** Remote
   * **VCS Integration:** GitHub (connect your repo) or “CLI-driven” if you want to push manually.

**Key Concepts:**

* **Organization** = Top-level container
* **Workspace** = Unit of Terraform execution (like an environment)
* **Runs** = Terraform Plan/Apply executions managed by Terraform Cloud

---

## **Lab 2: Creating Infrastructure with Terraform Cloud**

**Objective:** Use Terraform Cloud to deploy an Azure Resource Group.

1. In your Git repo, create a `main.tf` with:

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

resource "azurerm_resource_group" "rg" {
  name     = "rg-tfcloud-lab"
  location = "East US"
}
```

2. Commit & push the code to GitHub.

3. In Terraform Cloud → `azure-rg-lab` workspace → **Queue Plan**.

4. Provide Azure credentials to Terraform Cloud:

   * Go to **Workspace → Variables**
   * Add environment variables:

     ```bash
     ARM_CLIENT_ID
     ARM_CLIENT_SECRET
     ARM_SUBSCRIPTION_ID
     ARM_TENANT_ID
     ```
   * Mark `ARM_CLIENT_SECRET` as **sensitive**.

5. Run `terraform plan` → `terraform apply` directly in Terraform Cloud.

Verify in Azure:

```bash
az group show -n rg-tfcloud-lab
```

---

## **Lab 3: Overview of Sentinel Security**

**Objective:** Learn policy enforcement with **Sentinel** in Terraform Cloud.

1. Go to Terraform Cloud → **Policies** → Create a new policy set.
2. Example Sentinel Policy (enforce location = eastus):

```hcl
import "tfplan/v2" as tfplan

main = rule {
  all tfplan.resource_changes as _, rc {
    rc.change.after.location is "eastus"
  }
}
```

3. Attach policy set to your organization.
4. Try to change RG location in `main.tf` to `westus`.
5. Run plan in Terraform Cloud → Policy will **deny** run.

Sentinel = Policy-as-Code for governance & compliance.

---

## **Lab 4: Introduction to Local and Remote Backends**

**Objective:** Compare **local state** vs **remote state**.

1. **Local Backend (default):**

   * Run locally:

     ```bash
     terraform init
     terraform apply
     ```
   * State file: `terraform.tfstate` stored in project folder.
   * Risk: Sensitive data stored locally → conflicts in team.

2. **Remote Backend:**

   * Stores state in a shared location (Azure Storage, S3, Terraform Cloud).
   * Provides **locking**, **versioning**, and **collaboration**.

---

## **Lab 5: Implementing Remote Backend in Terraform Cloud**

**Objective:** Configure Terraform Cloud as backend for state.

1. Update `main.tf` → add backend block:

```hcl
terraform {
  backend "remote" {
    organization = "tfcloud-azure-lab"

    workspaces {
      name = "azure-rg-lab"
    }
  }
}
```

2. Re-initialize project:

   ```bash
   terraform init
   ```

   * You’ll be prompted to migrate state → choose **Yes**.

3. Verify:

   * Go to Terraform Cloud → `States` → see state file stored remotely.
   * Locking is enforced automatically.

---

## **End-of-Lab Outcomes**

* Created infra in Azure via Terraform Cloud
* Enforced compliance with Sentinel
* Understood Local vs Remote backend differences
* Migrated state to Terraform Cloud remote backend

---

