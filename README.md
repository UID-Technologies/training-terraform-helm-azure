# Terraform Training and Lab – Azure & Helm

## Overview
This repository contains hands-on training material and lab exercises designed to teach **Infrastructure as Code (IaC)** concepts using **Terraform**, with a focus on deploying workloads to **Microsoft Azure** and managing applications via **Helm on Kubernetes (AKS)**.

The labs are structured to gradually build skills—from Terraform basics to advanced provisioning, Azure resource deployments, and Helm chart management—ensuring participants gain both theoretical understanding and real-world practical experience.

---

##  Training Objectives
- Understand **Terraform fundamentals** (providers, resources, variables, outputs, state management).
- Deploy and manage **Azure resources** using Terraform.
- Implement **modular and reusable Terraform code**.
- Use **Terraform with Azure Storage** for remote state management.
- Integrate **Helm with Terraform** for Kubernetes application deployments.
- Learn **best practices** for infrastructure automation in production-grade environments.

---

##  Lab Modules

### Lab 1 – Terraform Basics
- Install Terraform and configure Azure CLI.
- Initialize and apply a basic Terraform configuration.
- Manage providers, resources, and variables.

### Lab 2 – Azure Infrastructure with Terraform
- Create Azure Resource Groups, VNETs, Subnets, and Storage Accounts.
- Provision Azure Kubernetes Service (AKS).
- Use Terraform state files locally and remotely (Azure Storage backend).

### Lab 3 – Helm with Terraform on AKS
- Deploy Helm using Terraform’s Helm provider.
- Install sample applications (e.g., NGINX, Redis) via Helm charts.
- Manage Helm releases with Terraform.

### Lab 4 – Production-Ready Enhancements
- Implement **RBAC, Service Accounts, and Namespaces**.
- Configure **Ingress with NGINX and TLS**.
- Set up **Horizontal Pod Autoscaling (HPA)**.
- Secure secrets using **Azure Key Vault** integration.

---

## Prerequisites
- **Azure Subscription**
- **Azure CLI** installed  
  



* **Kubectl** installed

  ```bash
  winget install -e --id Kubernetes.kubectl
  ```
* **Helm** installed

  ```bash
  winget install -e --id Helm.Helm
  ```
* Terraform (latest version) installed

---

## Getting Started

1. Clone this repository:

   ```bash
   git clone https://github.com/<your-org>/terraform-azure-helm-labs.git
   cd terraform-azure-helm-labs
   ```

2. Login to Azure:

   ```bash
   az login
   ```

3. Set your subscription:

   ```bash
   az account set --subscription "<SUBSCRIPTION_ID>"
   ```

4. Initialize Terraform:

   ```bash
   terraform init
   ```

5. Run the first lab:

   ```bash
   terraform apply
   ```

---

## 📂 Repository Structure

```
.
├── labs
│   ├── lab1-terraform-basics/
│   ├── lab2-azure-infra/
│   ├── lab3-helm-on-aks/
│   └── lab4-production-ready/
├── modules/
│   ├── network/
│   ├── aks/
│   └── helm/
└── README.md
```

---

## Best Practices

* Always use **remote state** with Azure Storage for collaboration.
* Organize Terraform configurations into **modules** for reusability.
* Version-control all infrastructure code (Git).
* Regularly run `terraform plan` before applying changes.
* Use **Helm values files** for environment-specific customizations.

---

## References

* [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
* [Azure Terraform Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
* [Helm Documentation](https://helm.sh/docs/)
* [Azure Kubernetes Service (AKS)](https://learn.microsoft.com/en-us/azure/aks/)

---

## Author

**UID Technologies LLP**
Training & Solutions in Cloud, DevOps, and Modern Application Development.

---

