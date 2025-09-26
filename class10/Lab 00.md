# Helm Real‑World Lab Manual (Windows + AKS)

> A scenario‑driven, step‑by‑step series you can run on Windows with Azure Kubernetes Service (AKS) and Helm v3. 

---

## Lab 0 — One‑time Platform Setup (AKS + ACR + Namespaces)

### Objective

Provision a working Kubernetes platform on Azure with AKS and ACR, and prepare environment namespaces for later labs.

### Description (Scenario)

You’re the Platform Engineer at **AcmeMart**. You need a cluster, a container registry, and three namespaces: `dev`, `staging`, `prod`.

### Explanations

* **AKS** hosts workloads; **ACR** stores images.
* Namespaces enable safe multi‑tenancy and promote isolation by environment.

### Prerequisites

Windows PowerShell, Azure subscription, Docker (optional for pushing images).

### Steps

1. **Install tools**

   ```powershell
   winget install -e --id Microsoft.AzureCLI
   choco install kubernetes-helm
   ```
2. **Login & set variables**

   ```powershell
   az login
   $RG="helm-lab-rg"; $LOC="eastus"; $CLUSTER="helm-lab-cluster"
   $ACR="acmemartacr$((Get-Random))"
   ```
3. **Create Resource Group & AKS**

   ```powershell
   az group create -n $RG -l $LOC
   az aks create -n $CLUSTER -g $RG --node-count 2 --enable-managed-identity
   az aks get-credentials -n $CLUSTER -g $RG
   kubectl get nodes
   ```
4. **Create ACR & attach to AKS**

   ```powershell
   az acr create -n $ACR -g $RG --sku Basic
   az aks update -n $CLUSTER -g $RG --attach-acr $ACR
   ```
5. **Create namespaces**

   ```powershell
   kubectl create ns dev; kubectl create ns staging; kubectl create ns prod
   ```

### Verify

* `kubectl get ns` shows `dev`, `staging`, `prod`.
* `kubectl get nodes` shows Ready nodes.

### Troubleshoot

* Wrong kube context → `kubectl config get-contexts` then `kubectl config use-context <ctx>`.
* ACR attach fails → wait for AKS creation to complete, then rerun.

### Conclusion

A clean platform baseline is ready for Helm‑based deployments and environment isolation.

---
