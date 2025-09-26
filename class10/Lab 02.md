## Lab 2 — Kubernetes RBAC & Service Accounts for Helm (Least Privilege)

### Objective

Create a least‑privilege ServiceAccount and Role for Helm operations in a single namespace.

### Description (Scenario)

Security requires that AcmeMart devs can only manage resources in `dev` and not cluster‑wide.

### Explanations

* **Role/RoleBinding** limit permissions within a namespace; avoid ClusterRole where possible.
* Helm v3 uses the caller’s Kubernetes auth; it inherits RBAC from your kube context.

### Steps

1. **Create ServiceAccount**

   ```powershell
   kubectl -n dev create serviceaccount helm-sa
   ```
2. **Create Role**

```powershell
@'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata: { name: helm-deployer }
rules:
- apiGroups: ["", "apps", "batch", "networking.k8s.io", "autoscaling"]
  resources: ["deployments","statefulsets","daemonsets","services","configmaps","secrets","ingresses","jobs","cronjobs","horizontalpodautoscalers","pods"]
  verbs: ["get","list","watch","create","update","patch","delete"]
- apiGroups: [""]
  resources: ["pods/log","events"]
  verbs: ["get","list","watch"]
'@ | kubectl apply -n dev -f -

```
3. **Bind Role to SA**

```powershell

kubectl -n dev create rolebinding helm-deployer-binding --role=helm-deployer  --serviceaccount=dev:helm-sa

```
4. **Create a user context for this SA (demo)**

```powershell
$TOKEN=(kubectl -n dev create token helm-sa)
$CTX=(kubectl config current-context)
$CLUSTER_NAME = kubectl config view -o jsonpath="{.contexts[?(@.name=='$CTX')].context.cluster}"
kubectl config set-credentials helm-dev --token=$TOKEN
kubectl config set-context helm-dev --cluster=$CLUSTER_NAME --namespace=dev --user=helm-dev
kubectl config use-context helm-dev
```
5. **Exercise permissions**

   ```powershell
   kubectl get deploy -n dev   # should work
   kubectl get ns              # should be Forbidden
   ```

### Verify

* Limited operations succeed in `dev`; cluster‑wide calls are forbidden.

### Troubleshoot

* Missing verb/resource → extend Role rules based on error messages.

### Conclusion

Helm operations can now be performed under least privilege, satisfying security controls.

---

