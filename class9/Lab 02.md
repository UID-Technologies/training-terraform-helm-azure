
#  Lab Exercise: Deploy Sample App on AKS using Terraform + Helm

---

##  Prerequisites

(Same as earlier lab)

* Azure CLI (`az`)
* Terraform (≥1.5)
* kubectl
* Helm (`helm version`)

---

##  Step 1: Infrastructure Setup with Terraform

We’ll reuse **Terraform** to provision AKS. Add Helm provider to Terraform.

###  `main.tf`

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~>2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~>2.0"
    }
  }
  required_version = ">=1.5.0"
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-helm"
  location = "East US"
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-helm-cluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "akslabhelm"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Kubernetes provider using AKS creds
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
}

# Helm provider
provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
  }
}
```

---

##  Step 2: Create Helm Chart (Locally)

Create a new Helm chart for NGINX:

```bash
helm create nginx-sample
```

This creates:

```
nginx-sample/
  Chart.yaml
  values.yaml
  templates/
    deployment.yaml
    service.yaml
```

###  Customize `values.yaml`

```yaml
replicaCount: 2

image:
  repository: nginx
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: LoadBalancer
  port: 80
```

---

##  Step 3: Terraform Helm Release

Add this to **main.tf**:

```hcl
resource "helm_release" "nginx" {
  name       = "nginx-sample"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx"
  version    = "15.9.1"

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "replicaCount"
    value = "2"
  }
}
```

 Here we are using **Bitnami’s NGINX chart** from Helm repo.
Alternatively, you could point `chart = "./nginx-sample"` if you want to deploy the **local chart you created**.

---

##  Step 4: Deploy Infrastructure + App

```bash
terraform init
terraform apply -auto-approve
```

Terraform will:

1. Create Resource Group + AKS.
2. Deploy Helm chart → NGINX on AKS.

---

##  Step 5: Verify Deployment

```bash
kubectl get pods
kubectl get svc
```

You’ll see:

```
NAME             TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)        AGE
nginx-sample     LoadBalancer   10.0.147.215   20.52.123.45     80:31423/TCP   2m
```

Open in browser:

```
http://<EXTERNAL-IP>
```

 You should see NGINX welcome page.

---

##  Step 6: Cleanup

```bash
terraform destroy -auto-approve
```

---

#  Summary

In this extended lab you:

1. Provisioned **AKS with Terraform**.
2. Used the **Helm provider in Terraform**.
3. Deployed NGINX via a **Helm chart** (Bitnami or local).
4. Verified service exposure via LoadBalancer.

---

