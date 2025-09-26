## Lab 8 — Canary Releases with NGINX Ingress (Manual)

### Objective

Deliver changes gradually (10% → 50% → 100%) using Ingress canary annotations.

### Description (Scenario)

Reduce blast radius by sending a small percentage of traffic to the new version.

### Explanations

* Canary is a progressive rollout. NGINX supports `canary: true` and weight rules.

### Steps

1. **Install Ingress controller**

   ```powershell
   helm install ingress bitnami/nginx-ingress-controller -n platform --create-namespace
   ```
2. **Deploy stable & canary**

   ```powershell
   helm install cart-stable acme-s3/cart -n staging --set replicaCount=10
   helm install cart-canary acme-s3/cart -n staging --set replicaCount=1,service.nameOverride="cart-canary"
   ```
3. **Create canary Ingress**

```powershell
@"
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: cart
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: cart-stable
            port:
              number: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: cart-canary
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "10"
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: cart-canary
            port:
              number: 80
"@ | kubectl -n staging apply -f -

```
4. **Adjust weight**

```powershell
 kubectl -n staging annotate ingress cart-canary `
  'nginx.ingress.kubernetes.io/canary-weight=50' --overwrite
```

### Verify

* Repeated requests show mixed versions. Use version header or UI marker.

### Troubleshoot

* No external IP yet → `kubectl -n platform get svc -w` until assigned.

### Conclusion

You’ve implemented a safe, progressive rollout strategy with observable traffic shifting.

---

