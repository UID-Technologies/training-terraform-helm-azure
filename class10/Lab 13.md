## Lab 13 — Addressing Real Failures: Image, Quotas, Secrets

### Objective

Simulate common production issues and resolve them using Helm values and K8s primitives.

### Description (Scenario)

Incidents often stem from wrong image tags, tight quotas, or secret wiring mistakes.

### Explanations

* Image pull failures show as `ImagePullBackOff`.
* ResourceQuota prevents over‑consumption.
* Secrets must match env/volume references in values.

### Steps

**A) Bad image tag**

```powershell
helm install cart-prod acme-s3/cart -n prod `
  --set image.repository="$ACR.azurecr.io/cart",image.tag="1.0.0"
helm upgrade cart-prod acme-s3/cart -n prod --reuse-values --set image.tag="does-not-exist"
kubectl -n prod get pods
kubectl -n prod describe pod (kubectl -n prod get pods -o name | Select-Object -First 1)
helm rollback cart-prod 1 -n prod
```

**B) Quota breach**

```powershell
kubectl -n prod apply -f - <<'YAML'
apiVersion: v1
kind: ResourceQuota
metadata: { name: prod-quota }
spec: { hard: { pods: "5", requests.cpu: "2", limits.cpu: "4" } }
YAML
helm upgrade cart-prod acme-s3/cart -n prod --reuse-values --set replicaCount=10  # expect failure
helm upgrade cart-prod acme-s3/cart -n prod --reuse-values --set replicaCount=3
```

**C) Secrets wiring**

```powershell
kubectl -n prod create secret generic cart-db `
  --from-literal=USER=cart --from-literal=PASSWORD='S3cr3t!'
# Ensure chart references secret (envFrom or specific keys), then:
helm upgrade cart-prod acme-s3/cart -n prod --reuse-values
```

### Verify

* Rollback restores healthy state; quotas enforced; secrets visible in pod env.

### Troubleshoot

* Secret key mismatches → align chart values with secret names/keys.

### Conclusion

You can recognize and remediate the most frequent production errors in minutes.

---

