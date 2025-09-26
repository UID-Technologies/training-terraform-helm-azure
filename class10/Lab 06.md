## Lab 6 — Helm S3: Private Chart Distribution with MinIO

### Objective

Run an S3‑compatible chart repository on cluster and push/pull charts with `helm-s3`.

### Description (Scenario)

You need a private, self‑hosted chart repo for internal packages.

### Explanations

* **MinIO** provides S3‑compatible storage; `helm-s3` treats buckets as Helm repos.

### Steps

1. **Install MinIO**

   ```powershell
   kubectl create ns platform
   helm repo add bitnami https://charts.bitnami.com/bitnami
   helm install minio bitnami/minio -n platform `
     --set auth.rootUser=admin --set auth.rootPassword=Password123!
   ```
2. **Port‑forward & create bucket**

   ```powershell
   kubectl -n platform port-forward svc/minio 9000:9000 9001:9001
   # Open http://localhost:9001 → login → create bucket "helm-charts"
   ```
3. **Install plugin & set creds**

   ```powershell
   helm plugin install https://github.com/hypnoglow/helm-s3.git
   $env:AWS_ACCESS_KEY_ID="admin"; $env:AWS_SECRET_ACCESS_KEY="Password123!"
   ```
4. **Init and add repo (path‑style)**

   ```powershell
   helm s3 init s3://helm-charts
   helm repo add acme-s3 s3://helm-charts `
     --endpoint http://127.0.0.1:9000 --region us-east-1 --s3-force-path-style
   helm repo update
   ```
5. **Create, package, push chart**

   ```powershell
   helm create cart
   helm package cart
   helm s3 push cart-0.1.0.tgz acme-s3
   helm search repo acme-s3
   ```

### Verify

* `helm search repo acme-s3` lists your `cart` chart.

### Troubleshoot

* 403/signature errors → ensure env vars and `--s3-force-path-style`.

### Conclusion

You have a private, internal distribution mechanism for Helm charts.

---

## Lab 6 — Helm with Azure Blob Storage: Private Chart Distribution

### Objective

Host a private Helm chart repository on **Azure Blob Storage** and push/pull charts with Helm.

### Description (Scenario)

You need a secure, self-hosted chart repository for internal Helm packages, but instead of S3, you’ll use **Azure Blob Storage**.

### Explanations

* Azure Blob Storage provides object storage accessible via HTTPS.
* Helm supports any static HTTP(S) file server as a chart repository.
* By enabling **static website hosting** or serving blobs directly, Azure Blob can act as your private Helm repo.

---

## Steps

### 1. **Create a Storage Account**

```powershell
# Variables
$RESOURCE_GROUP="helm-rg"
$STORAGE_ACCOUNT="helmcharts$((Get-Random))"
az group create -n $RESOURCE_GROUP -l eastus
az storage account create -n $STORAGE_ACCOUNT -g $RESOURCE_GROUP -l eastus --sku Standard_LRS
```

---

### 2. **Enable Blob Container for Helm Repo**

```powershell
$CONTAINER="helm-charts"
az storage container create -n $CONTAINER --account-name $STORAGE_ACCOUNT --auth-mode login
```

---

### 3. **Generate Storage Key / SAS Token**

```powershell
# Get storage account key
$ACCOUNT_KEY=$(az storage account keys list -g $RESOURCE_GROUP -n $STORAGE_ACCOUNT --query [0].value -o tsv)

# OR generate SAS token (preferred for scoped access)
$SAS=$(az storage container generate-sas --account-name $STORAGE_ACCOUNT -n $CONTAINER `
   --permissions rwl --expiry (Get-Date).AddDays(1).ToString("yyyy-MM-dd") -o tsv)
```

---

### 4. **Package and Upload a Helm Chart**

```powershell
helm create cart
helm package cart

# Upload chart to Azure Blob
az storage blob upload --account-name $STORAGE_ACCOUNT `
  --account-key $ACCOUNT_KEY `
  -c $CONTAINER -f cart-0.1.0.tgz -n cart-0.1.0.tgz
```

---

### 5. **Generate an Index File**

Helm requires an `index.yaml` in the repo root.

```powershell
helm repo index . --url "https://$STORAGE_ACCOUNT.blob.core.windows.net/$CONTAINER"
az storage blob upload --account-name $STORAGE_ACCOUNT `
  --account-key $ACCOUNT_KEY `
  -c $CONTAINER -f index.yaml -n index.yaml
```

---

### 6. **Add Azure Blob Repo to Helm**

```powershell
helm repo add acme-azure "https://$STORAGE_ACCOUNT.blob.core.windows.net/$CONTAINER"
helm repo update
```

---

### 7. **Verify Charts**

```powershell
helm search repo acme-azure
```

---

## Verify

* `helm search repo acme-azure` should list the `cart` chart from Azure Blob.

---

## Troubleshoot

* 403 errors → check SAS token expiry or storage key.
* `index.yaml` missing → ensure it was uploaded alongside `.tgz` chart.
* Access denied → ensure container ACL is set to allow blob read access (or provide SAS in repo URL).

---

## Conclusion

You now have a **private Helm chart distribution mechanism on Azure Blob Storage**, replacing S3/MinIO.

---

