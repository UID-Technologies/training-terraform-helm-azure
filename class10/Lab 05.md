## Lab 5 — Working with Plugins (helm‑diff, lint) in Real Workflow

### Objective

Preview changes safely, lint charts, and upgrade with confidence.

### Description (Scenario)

Peer reviews require a `diff` before production upgrades.

### Explanations

* `helm-diff` shows resource‑level changes; `helm lint` catches chart issues early.

### Steps

1. **Install plugin & lint**

   ```powershell
   helm plugin install https://github.com/databus23/helm-diff
   helm lint bitnami/nginx
   ```
2. **Install baseline & preview change**

   ```powershell
   helm install web-diff bitnami/nginx -n dev --set service.type=ClusterIP
   helm diff upgrade web-diff bitnami/nginx -n dev --set service.type=LoadBalancer
   ```
3. **Apply change**

   ```powershell
   helm upgrade web-diff bitnami/nginx -n dev --set service.type=LoadBalancer
   ```

### Verify

* Diff output clearly shows the service type switch.

### Troubleshoot

* Plugin issues → `helm plugin list`, remove/reinstall.

### Conclusion

Change previews are now part of your standard operating procedure.

---

