## Lab 4 — Managing Known Client Repos (Public + Private)

### Objective

Add, prioritize, and pin Helm repositories and chart versions.

### Description (Scenario)

AcmeMart prefers internal charts when available; public charts are a fallback.

### Explanations

* Pinning versions ensures reproducibility; internal repos can be backed by ChartMuseum/OCI/S3.

### Steps

1. **Add repos & update**

   ```powershell
   helm repo add bitnami https://charts.bitnami.com/bitnami
   helm repo add acmemart https://charts.acmemart.internal   # example
   helm repo update
   ```
2. **Search and pin**

   ```powershell
   helm search repo bitnami/nginx --versions | Select-Object -First 5
   ```
3. **Install pinned version**

   ```powershell
   helm install web-pinned bitnami/nginx -n dev --version 15.8.7
   ```

### Verify

* `helm ls -n dev` shows the pinned release.

### Troubleshoot

* Private repo TLS → use `--ca-file` or fix trust chain in Windows cert store.

### Conclusion

You can deterministically select and consume curated charts across repos.

---

