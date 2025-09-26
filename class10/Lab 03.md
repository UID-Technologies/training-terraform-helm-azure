## Lab 3 — “Helm per Namespace” as an Operating Pattern

### Objective

Run separate releases for different teams/environments with namespace isolation and unique values.

### Description (Scenario)

Teams A & B share the same cluster but must have independent releases and scaling.

### Explanations

* Helm v3 scopes releases by namespace; reusing a release name in another namespace is allowed.
* Values files enable opinionated per‑team differences (replicas, resources).

### Steps

1. **Create team namespaces**

   ```powershell
   kubectl create ns team-a
   kubectl create ns team-b
   ```
2. **Ensure repo & update**

   ```powershell
   helm repo add bitnami https://charts.bitnami.com/bitnami
   helm repo update
   ```
3. **Install with different configs**

   ```powershell
   helm install web-a bitnami/nginx -n team-a --set replicaCount=1
   helm install web-b bitnami/nginx -n team-b --set replicaCount=3
   ```
4. **List releases**

   ```powershell
   helm ls -n team-a; helm ls -n team-b
   ```

### Verify
```yaml
kubectl -n team-a get deploy web-a-nginx
kubectl -n team-b get deploy web-b-nginx

```


* Team‑A has 1 replica; Team‑B has 3 replicas.

### Troubleshoot

* Name collision within the same namespace → pick unique release names per namespace.

### Conclusion

You’ve established a scalable, multi‑tenant pattern: one Helm per namespace with independent lifecycle.

---

