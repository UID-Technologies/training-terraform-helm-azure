## Lab 12 — `helm template`: Bypass Release Mgmt, Use Helm as Templating/Packaging

### Objective

Render YAML and apply with `kubectl` (or GitOps), without creating Helm release state.

### Description (Scenario)

A regulated environment disallows Helm release metadata in the cluster.

### Explanations

* `helm template` renders templates locally; `kubectl apply` manages objects.

### Steps

```powershell
helm lint .\cart
helm package .\cart
helm template cart .\cart --values .\values.staging.yaml > manifests.yaml
kubectl apply -n staging -f .\manifests.yaml
```

### Verify

* `helm ls -n staging` is empty, but objects exist via `kubectl -n staging get all`.

### Troubleshoot

* CRDs must be installed before dependent resources.

### Conclusion

You can still benefit from Helm templating when Helm releases aren’t allowed.

---

