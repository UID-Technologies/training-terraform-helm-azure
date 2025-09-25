

#  Extended Lab: Node.js App on AKS with Azure Key Vault Secrets

---

##  Step 1: Create Key Vault in Terraform

Extend `main.tf`:

```hcl
resource "azurerm_key_vault" "kv" {
  name                        = "aks-kv-sample123"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"

  soft_delete_retention_days = 7
}

# Allow AKS Managed Identity to access Key Vault
resource "azurerm_key_vault_access_policy" "aks_policy" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id

  secret_permissions = ["Get", "List"]
}

# Create a secret in Key Vault
resource "azurerm_key_vault_secret" "db_password" {
  name         = "DBPassword"
  value        = "SuperSecretPass123!"
  key_vault_id = azurerm_key_vault.kv.id
}

data "azurerm_client_config" "current" {}
```

---

##  Step 2: Install Secrets Store CSI Driver with Helm

Add to `main.tf`:

```hcl
resource "helm_release" "csi_secrets_store" {
  name       = "csi-secrets-store"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  namespace  = "kube-system"

  set {
    name  = "windows.enabled"
    value = "false"
  }
}

resource "helm_release" "csi_azure_provider" {
  name       = "csi-azure-provider"
  repository = "https://azure.github.io/secrets-store-csi-driver-provider-azure/charts"
  chart      = "csi-secrets-store-provider-azure"
  namespace  = "kube-system"
}
```

---

##  Step 3: Define SecretProviderClass

Create `templates/secretproviderclass.yaml` inside your Helm chart:

```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-kv-secrets
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "true"
    userAssignedIdentityID: ""
    keyvaultName: "aks-kv-sample123" # replace with your KV name
    cloudName: ""
    objects: |
      array:
        - |
          objectName: DBPassword
          objectType: secret
          objectVersion: ""
    tenantId: {{ .Values.azureTenantId }}
  secretObjects:
    - secretName: db-password
      type: Opaque
      data:
        - objectName: DBPassword
          key: DB_PASSWORD
```

---

##  Step 4: Update Deployment to Use Secret

Modify `deployment.yaml`:

```yaml
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: db-password
        key: DB_PASSWORD

volumeMounts:
  - name: secrets-store-inline
    mountPath: "/mnt/secrets-store"
    readOnly: true

volumes:
  - name: secrets-store-inline
    csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: "azure-kv-secrets"
```

---

##  Step 5: Update Node.js App

Update `app.js` to read from secret:

```js
const express = require("express");
const app = express();
const port = process.env.PORT || 3000;

const dbPassword = process.env.DB_PASSWORD || "NoSecretFound";

app.get("/", (req, res) => {
  res.send(`App running with DB password: ${dbPassword}`);
});

app.listen(port, () => {
  console.log(`App running at http://localhost:${port}`);
});
```

Rebuild & push:

```bash
docker build -t aksregistry123.azurecr.io/node-aks-app:v3 .
docker push aksregistry123.azurecr.io/node-aks-app:v3
```

---

##  Step 6: Update Terraform Helm Release

Update Helm release in `main.tf`:

```hcl
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
    value = "v3"
  }

  set {
    name  = "appMessage"
    value = "Hello from Node.js with Azure Key Vault secrets "
  }

  set {
    name  = "azureTenantId"
    value = data.azurerm_client_config.current.tenant_id
  }
}
```

---

##  Step 7: Deploy & Verify

```bash
terraform apply -auto-approve
```

Check pod:

```bash
kubectl logs <node-app-pod>
```

Expected output:

```
App running with DB password: SuperSecretPass123!
```

Check secret in Kubernetes:

```bash
kubectl get secret db-password -o yaml
```

---

##  Step 8: Cleanup

```bash
terraform destroy -auto-approve
```

---

#  Summary

Now your Node.js app on AKS:

* Uses **Azure Key Vault** to store secrets.
* Uses **CSI Secrets Store driver** to mount secrets into pods.
* Passes secrets as **environment variables** without hardcoding.
* Managed fully with **Terraform + Helm**.

---
