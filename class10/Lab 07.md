## Lab 7 — Using the CLI to Manage Releases: Install/Upgrade, Blue‑Green, Rollback

### Objective

Perform installs, upgrades, blue/green routing, and safe rollbacks.

### Description (Scenario)

`cart-service` v1 (blue) is live. You want to ship v1.1 (green) and switch traffic, with a rollback plan.

### Explanations

* Blue/green keeps two versions running; an Ingress/Service controls traffic.
* Rollback reverts to a known‑good revision tracked by Helm.

### Steps

1. **Push images to ACR (sample)**

   ```powershell
   az acr login -n $ACR
   docker pull mcr.microsoft.com/azuredocs/azure-vote-front:v1
   docker tag mcr.microsoft.com/azuredocs/azure-vote-front:v1 $ACR.azurecr.io/cart:1.0.0
   docker push $ACR.azurecr.io/cart:1.0.0
   docker tag $ACR.azurecr.io/cart:1.0.0 $ACR.azurecr.io/cart:1.1.0
   docker push $ACR.azurecr.io/cart:1.1.0
   ```
2. **Install blue**

   ```powershell
   helm install cart-blue acme-s3/cart -n staging `
     --version 0.1.0 --set image.repository="$ACR.azurecr.io/cart",image.tag="1.0.0"
   ```
3. **Install green**

   ```powershell
   helm install cart-green acme-s3/cart -n staging `
     --version 0.1.0 --set image.repository="$ACR.azurecr.io/cart",image.tag="1.1.0",service.nameOverride="cart-green"
   ```
4. **Switch traffic** (via values or Service selector)

   ```powershell
   # Example: chart has a router toggle
   helm upgrade cart-blue acme-s3/cart -n staging --reuse-values --set router.active=green
   ```
5. **Rollback if needed**

   ```powershell
   helm history cart-blue -n staging
   helm rollback cart-blue 1 -n staging
   ```

### Verify

* Both deployments exist; traffic targets green.

### Troubleshoot

* Image pull errors → ensure ACR images exist; AKS attached to ACR.

### Conclusion

You can ship new versions with near‑zero downtime and revert quickly when required.

---

