## Lab 1 — Installing & Using the Helm CLI (Helm v3 “Initialization”)

### Objective

Install/verify Helm v3, configure repos, and understand v2 (Tiller) vs v3 differences.

### Description (Scenario)

New engineers join AcmeMart and must bootstrap Helm locally without Tiller.

### Explanations

* **Helm v2** used Tiller (server inside cluster). **Helm v3** is client‑only.
* “Initialization” in v3 = repos, plugins, cache; no server component.

### Steps

1. **Check Helm & env**

   ```powershell
   helm version
   helm env
   ```
2. **Add public repo & update**

   ```powershell
   helm repo add bitnami https://charts.bitnami.com/bitnami
   helm repo update
   ```
3. **Discover charts & values**

   ```powershell
   helm search repo nginx
   helm show values bitnami/nginx | more
   ```

### Verify

* `helm version` shows v3.x
* Search returns multiple nginx charts

### Troubleshoot

* Corp proxy: set `HTTP_PROXY/HTTPS_PROXY` env vars and retry `helm repo update`.

### Conclusion

Helm client is ready; you can search, view defaults, and prepare to install charts—no Tiller required.

---

