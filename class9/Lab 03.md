

#  Lab Exercise: Build & Deploy Node.js App on AKS with Helm + Terraform

---

##  Prerequisites

* Azure CLI (`az`)
* Terraform (≥1.5)
* kubectl
* Helm
* Docker

---

##  Step 1: Create a Simple Node.js App

 Project structure:

```
node-app/
  app.js
  package.json
  Dockerfile
```

###  `app.js`

```js
const express = require("express");
const app = express();
const port = process.env.PORT || 3000;

app.get("/", (req, res) => {
  res.send("Hello from Node.js app running on AKS via Helm! 🚀");
});

app.listen(port, () => {
  console.log(`App running at http://localhost:${port}`);
});
```

###  `package.json`

```json
{
  "name": "node-aks-app",
  "version": "1.0.0",
  "main": "app.js",
  "dependencies": {
    "express": "^4.18.2"
  }
}
```

###  `Dockerfile`

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["node", "app.js"]
```

---

##  Step 2: Build & Push Image to ACR

1. Create ACR:

```bash
az acr create --resource-group rg-aks-helm --name aksregistry123 --sku Basic
```

2. Login to ACR:

```bash
az acr login --name aksregistry123
```

3. Build & push:

```bash
docker build -t aksregistry123.azurecr.io/node-aks-app:v1 .
docker push aksregistry123.azurecr.io/node-aks-app:v1
```

---

##  Step 3: Terraform Infrastructure with AKS + ACR

###  `main.tf`

```hcl
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-helm"
  location = "East US"
}

# Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "aksregistry123"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# AKS
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

  # Allow AKS to pull from ACR
  role_based_access_control {
    enabled = true
  }
}

# Grant AKS permission to ACR
resource "azurerm_role_assignment" "aks_acr" {
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}
```

---

##  Step 4: Helm Chart for Node App

Create chart:

```bash
helm create node-app
```

Inside `node-app/values.yaml`, set:

```yaml
replicaCount: 2

image:
  repository: aksregistry123.azurecr.io/node-aks-app
  tag: v1
  pullPolicy: Always

service:
  type: LoadBalancer
  port: 80

containerPort: 3000
```

Update **templates/deployment.yaml** → add container port:

```yaml
ports:
  - name: http
    containerPort: {{ .Values.containerPort }}
```

---

##  Step 5: Deploy with Terraform Helm Provider

Extend **main.tf**:

```hcl
provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
  }
}

resource "helm_release" "node_app" {
  name       = "node-app"
  chart      = "./node-app"
  namespace  = "default"

  set {
    name  = "image.repository"
    value = azurerm_container_registry.acr.login_server .. "/node-aks-app"
  }

  set {
    name  = "image.tag"
    value = "v1"
  }
}
```

---

##  Step 6: Deploy

```bash
terraform init
terraform apply -auto-approve
```

Check pods and service:

```bash
kubectl get pods
kubectl get svc
```

You’ll see:

```
NAME         TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)        AGE
node-app     LoadBalancer   10.0.147.215   20.102.145.23    80:31423/TCP   2m
```

Visit:

```
http://<EXTERNAL-IP>
```

 You should see:

```
Hello from Node.js app running on AKS via Helm! 🚀
```

---

##  Step 7: Cleanup

```bash
terraform destroy -auto-approve
```

---

#  Summary

In this advanced lab, you:

1. Built a **Node.js app** and containerized it.
2. Pushed the image to **Azure Container Registry**.
3. Created **AKS + ACR integration with Terraform**.
4. Created a **custom Helm chart**.
5. Deployed Node app on AKS using **Helm managed by Terraform**.

---

