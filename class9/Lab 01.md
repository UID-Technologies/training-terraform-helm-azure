

#  Lab Exercise: Deploy Sample App on AKS with Terraform

---

##  Prerequisites

1. **Azure Account** with Contributor role.
2. **Installed tools**:

   * [Terraform](https://developer.hashicorp.com/terraform/downloads) (≥ 1.5)
   * [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
   * [kubectl](https://kubernetes.io/docs/tasks/tools/)
   * [Docker](https://www.docker.com/) (optional if building your own image)

---

##  Step 1: Login and Setup

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "<YOUR_SUBSCRIPTION_ID>"
```

Create a new working directory:

```bash
mkdir terraform-aks-sample
cd terraform-aks-sample
```

---

##  Step 2: Terraform Files

###  `main.tf` (Infrastructure definition)

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
  required_version = ">=1.5.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-sample"
  location = "East US"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-sample-cluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "akssample"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}
```

---

###  `variables.tf`

```hcl
variable "prefix" {
  default = "sampleapp"
}
```

---

###  `outputs.tf`

```hcl
output "aks_name" {
  value = azurerm_kubernetes_cluster.aks.name
}
```

---

##  Step 3: Terraform Deployment

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

 This will create:

* Azure Resource Group
* AKS cluster with 2 nodes

---

##  Step 4: Configure `kubectl`

Fetch cluster credentials:

```bash
az aks get-credentials --resource-group rg-aks-sample --name aks-sample-cluster
```

Verify:

```bash
kubectl get nodes
```

---

##  Step 5: Sample Application

Let’s deploy **NGINX** as our sample app.

###  `k8s-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-sample
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-sample
  template:
    metadata:
      labels:
        app: nginx-sample
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
```

###  `k8s-service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: LoadBalancer
  selector:
    app: nginx-sample
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

---

##  Step 6: Deploy App

```bash
kubectl apply -f k8s-deployment.yaml
kubectl apply -f k8s-service.yaml
```

Check status:

```bash
kubectl get pods
kubectl get svc
```

Wait for `EXTERNAL-IP` in the LoadBalancer service:

```bash
kubectl get svc nginx-service
```

Visit in browser:

```
http://<EXTERNAL-IP>
```

You should see the **NGINX welcome page** 

---

##  Step 7: Cleanup

When done:

```bash
terraform destroy -auto-approve
```

---

# Summary

In this lab, you:

1. Created AKS with Terraform.
2. Configured kubectl to connect.
3. Deployed a sample NGINX app using Kubernetes manifests.
4. Exposed it via LoadBalancer service.

