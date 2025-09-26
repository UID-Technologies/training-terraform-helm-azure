## Lab 9 — Rolling Back and Addressing Failure Cases

### Objective

Practice diagnosing bad releases (probes, images) and rolling back safely.

### Description (Scenario)

A faulty readiness probe causes pods to flap; you must recover quickly.

### Explanations

* Readiness probes gate traffic; bad paths keep pods out of Service endpoints.

### Steps

1. **Install healthy release**

```powershell
helm install cart-stable acme-s3/cart -n staging --set replicaCount=3
```
2. **Upgrade with bad probe**

```powershell
helm upgrade cart-stable acme-s3/cart -n staging --reuse-values `
   --set readinessProbe.httpGet.path="/wrong-health"
```
3. **Observe & diagnose**

   ```powershell
   kubectl -n staging get pods
   kubectl -n staging describe pod (kubectl -n staging get pods -o name | Select-Object -First 1)
   helm status cart-stable -n staging
   ```
4. **Rollback**

   ```powershell
   helm history cart-stable -n staging
   helm rollback cart-stable <previous> -n staging
   ```

### Verify

* Pods return to Ready; traffic restored.

### Troubleshoot

* No previous revision → ensure at least one successful install and an upgrade happened.

### Conclusion

You can triage failures rapidly and restore service with Helm history/rollback.

---

