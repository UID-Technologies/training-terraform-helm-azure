# 0) What we’re building (at a glance)

**App (AcmeShop)**

* **web** (multi-container Pod): `nginx` (reverse proxy) + `webapp` (Node/Express)
* **api** (single-container Pod): `api` (Node/Express)
* **redis**: brought via Helm dependency (Bitnami/Redis)
* **worker**: background queue processor

**Platform bits**

* **AKS** + **ACR** (for images)
* **ingress-nginx** + optional **cert-manager** for TLS
* **RBAC** (ServiceAccounts, Role/RoleBinding)
* **HPA** (web/api)
* **PDB** (web/api)
* **NetworkPolicies** (lock down traffic)
* **Readiness/Liveness probes**
* **Resource requests/limits**
* **Azure Monitor** addon (logs/metrics)

---

# 1) Prereqs (install once)

```powershell
# PowerShell
winget install -e --id Microsoft.AzureCLI
winget install -e --id Kubernetes.kubectl
winget install -e --id Helm.Helm
# Optional: Docker Desktop if you’ll build images locally
```

Log into Azure and set your subscription:

```powershell
az login
az account set --subscription "<SUBSCRIPTION_ID>"
```

---

# 2) Provision Azure (RG, ACR, AKS, attach ACR, monitoring)

```powershell
$RG="rg-helm-aks"
$LOC="eastus"
$ACR="acmeshop$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"
$AKS="aks-acmeshop"

az group create -n $RG -l $LOC

# Container Registry (for your app images)
az acr create -n $ACR -g $RG -l $LOC --sku Standard

# AKS (managed identity; note: VM size is just an example)
az aks create `
  -g $RG -n $AKS -l $LOC `
  --node-count 2 --node-vm-size Standard_DS2_v2 `
  --enable-managed-identity

# Allow AKS to pull from ACR
az aks update -g $RG -n $AKS --attach-acr $ACR

# Enable Azure Monitor (Container insights)
az aks enable-addons -a monitoring -g $RG -n $AKS

# Kubeconfig
az aks get-credentials -g $RG -n $AKS --overwrite-existing
kubectl get nodes
```

---

# 3) (Optional) Build & push your images to ACR

> Skip if you’ll use public sample images. Replace `repo/app:tag` below if you build.

```powershell
$ACR_LOGIN="$ACR.azurecr.io"
az acr login -n $ACR

# Example: build & push web and api images (assuming Dockerfile exists)
docker buildx build --platform linux/amd64 -t $ACR_LOGIN/web:1.0.0 .\apps\web
docker push $ACR_LOGIN/web:1.0.0

docker buildx build --platform linux/amd64 -t $ACR_LOGIN/api:1.0.0 .\apps\api
docker push $ACR_LOGIN/api:1.0.0
```

---

# 4) Install cluster add-ons with Helm (Ingress & TLS)

## 4.1 Ingress NGINX

```powershell
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
kubectl create namespace ingress-nginx
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx `
  -n ingress-nginx `
  --set controller.replicaCount=2 `
  --set controller.metrics.enabled=true
```

## 4.2 (Optional) cert-manager (Let’s Encrypt or self-signed)

```powershell
helm repo add jetstack https://charts.jetstack.io
helm repo update
kubectl create namespace cert-manager
helm upgrade --install cert-manager jetstack/cert-manager `
  -n cert-manager `
  --set installCRDs=true
```

Create a simple **self-signed** ClusterIssuer (quick start). For Let’s Encrypt, swap to an ACME issuer later.

```powershell
@"
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned
spec:
  selfSigned: {}
"@ | kubectl apply -f -
```

---

# 5) Create namespaces & apply baseline security labels

```powershell
kubectl create namespace staging
kubectl create namespace prod

# Pod Security Admission (baseline)
kubectl label ns staging pod-security.kubernetes.io/enforce=baseline --overwrite=true
kubectl label ns prod    pod-security.kubernetes.io/enforce=baseline --overwrite=true
```

---

# 6) Helm project structure (umbrella chart)

```text
acmeshop/
  charts/
    acmeshop/                # Umbrella
      Chart.yaml
      values.yaml
      values.staging.yaml
      values.prod.yaml
      templates/
        _helpers.tpl
        rbac.yaml
        configmap.yaml
        secret.yaml
        web-deployment.yaml          # multi-container
        web-service.yaml
        api-deployment.yaml
        api-service.yaml
        worker-deployment.yaml
        ingress.yaml
        hpa-web.yaml
        hpa-api.yaml
        pdb.yaml
        networkpolicy.yaml
      charts/                 # (for dependencies: redis)
        # auto-populated by 'helm dependency build'
```

### `Chart.yaml`

```yaml
apiVersion: v2
name: acmeshop
description: Umbrella chart for AcmeShop on AKS
type: application
version: 0.1.0
appVersion: "1.0.0"

dependencies:
  - name: redis
    version: "19.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: redis.enabled
```

### `values.yaml` (defaults; overridden by env files)

```yaml
global:
  name: acmeshop

image:
  registry: "<your-acr-or-dockerhub>"   # e.g., myacr.azurecr.io
  pullPolicy: IfNotPresent

web:
  image: "web:1.0.0"
  replicas: 2
  containerPort: 3000
  nginxPort: 8080
  resources:
    requests: { cpu: "100m", memory: "128Mi" }
    limits:   { cpu: "500m", memory: "512Mi" }
  env:
    - name: NODE_ENV
      value: "production"
    - name: API_BASE_URL
      value: "http://api:8080"

api:
  image: "api:1.0.0"
  replicas: 2
  containerPort: 8080
  resources:
    requests: { cpu: "100m", memory: "128Mi" }
    limits:   { cpu: "500m", memory: "512Mi" }
  env:
    - name: NODE_ENV
      value: "production"
    - name: REDIS_HOST
      value: "acmeshop-redis-master"
    - name: REDIS_PORT
      value: "6379"

worker:
  image: "api:1.0.0"          # same image, different CMD for worker if you like
  replicas: 1
  resources:
    requests: { cpu: "100m", memory: "128Mi" }
    limits:   { cpu: "500m", memory: "512Mi" }

ingress:
  enabled: true
  className: "nginx"
  host: ""                    # set for real domain in prod
  tls:
    enabled: false
    issuer: "selfsigned"

redis:
  enabled: true
  architecture: replication
  replica:
    replicaCount: 1
```

### `values.staging.yaml`

```yaml
image:
  registry: "<your-acr>.azurecr.io"
web:
  replicas: 1
api:
  replicas: 1
ingress:
  enabled: true
  host: ""
  tls:
    enabled: false
```

### `values.prod.yaml`

```yaml
image:
  registry: "<your-acr>.azurecr.io"
web:
  replicas: 3
api:
  replicas: 3
ingress:
  enabled: true
  host: "shop.example.com"
  tls:
    enabled: true
    issuer: "selfsigned" # swap to letsencrypt-prod when ready
```

---

# 7) Core templates

### 7.1 RBAC (namespace-scoped)

`templates/rbac.yaml`

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: acmeshop-sa
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: acmeshop-deployer
rules:
- apiGroups: ["", "apps", "batch", "networking.k8s.io", "autoscaling"]
  resources: ["deployments","statefulsets","daemonsets","services","configmaps","secrets","ingresses","jobs","cronjobs","horizontalpodautoscalers","pods","pods/log","events"]
  verbs: ["get","list","watch","create","update","patch","delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: acmeshop-deployer-binding
subjects:
- kind: ServiceAccount
  name: acmeshop-sa
roleRef:
  kind: Role
  name: acmeshop-deployer
  apiGroup: rbac.authorization.k8s.io
```

### 7.2 Config & Secrets

`templates/configmap.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "acmeshop.fullname" . }}-config
data:
  APP_LOG_LEVEL: "info"
```

`templates/secret.yaml` (example — store real secrets in Key Vault / External Secrets in prod)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "acmeshop.fullname" . }}-secret
type: Opaque
stringData:
  JWT_SECRET: "change-me"  # demo only
```

### 7.3 **web** (multi-container: nginx + app)

`templates/web-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: {{ .Values.web.replicas }}
  selector: { matchLabels: { app: web } }
  template:
    metadata:
      labels: { app: web }
    spec:
      serviceAccountName: acmeshop-sa
      containers:
      - name: webapp
        image: "{{ .Values.image.registry }}/{{ .Values.web.image }}"
        ports: [{ containerPort: {{ .Values.web.containerPort }} }]
        envFrom:
        - configMapRef: { name: {{ include "acmeshop.fullname" . }}-config }
        - secretRef:    { name: {{ include "acmeshop.fullname" . }}-secret }
        readinessProbe:
          httpGet: { path: /healthz, port: {{ .Values.web.containerPort }} }
          initialDelaySeconds: 5
          periodSeconds: 10
        livenessProbe:
          httpGet: { path: /livez, port: {{ .Values.web.containerPort }} }
          initialDelaySeconds: 10
          periodSeconds: 20
        resources: {{- toYaml .Values.web.resources | nindent 10 }}

      - name: nginx
        image: "nginx:1.27-alpine"
        ports: [{ containerPort: {{ .Values.web.nginxPort }} }]
        volumeMounts:
        - mountPath: /etc/nginx/conf.d
          name: nginx-conf
        readinessProbe:
          httpGet: { path: /, port: {{ .Values.web.nginxPort }} }
          initialDelaySeconds: 5
          periodSeconds: 10

      volumes:
      - name: nginx-conf
        configMap:
          name: web-nginx-conf
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: web-nginx-conf
data:
  default.conf: |
    server {
      listen {{ .Values.web.nginxPort }};
      location / {
        proxy_pass http://127.0.0.1:{{ .Values.web.containerPort }};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
      }
    }
---
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  selector: { app: web }
  ports:
  - name: http
    port: 80
    targetPort: {{ .Values.web.nginxPort }}
  type: ClusterIP
```

### 7.4 **api**

`templates/api-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  replicas: {{ .Values.api.replicas }}
  selector: { matchLabels: { app: api } }
  template:
    metadata:
      labels: { app: api }
    spec:
      serviceAccountName: acmeshop-sa
      containers:
      - name: api
        image: "{{ .Values.image.registry }}/{{ .Values.api.image }}"
        ports: [{ containerPort: {{ .Values.api.containerPort }} }]
        env:
        {{- range .Values.api.env }}
        - name: {{ .name }}
          value: "{{ .value }}"
        {{- end }}
        envFrom:
        - secretRef: { name: {{ include "acmeshop.fullname" . }}-secret }
        readinessProbe:
          httpGet: { path: /healthz, port: {{ .Values.api.containerPort }} }
          initialDelaySeconds: 5
          periodSeconds: 10
        livenessProbe:
          httpGet: { path: /livez, port: {{ .Values.api.containerPort }} }
          initialDelaySeconds: 10
          periodSeconds: 20
        resources: {{- toYaml .Values.api.resources | nindent 10 }}
---
apiVersion: v1
kind: Service
metadata:
  name: api
spec:
  selector: { app: api }
  ports:
  - name: http
    port: 8080
    targetPort: {{ .Values.api.containerPort }}
  type: ClusterIP
```

### 7.5 **worker**

`templates/worker-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: worker
spec:
  replicas: {{ .Values.worker.replicas }}
  selector: { matchLabels: { app: worker } }
  template:
    metadata:
      labels: { app: worker }
    spec:
      serviceAccountName: acmeshop-sa
      containers:
      - name: worker
        image: "{{ .Values.image.registry }}/{{ .Values.worker.image }}"
        command: ["node","worker.js"]  # example
        resources: {{- toYaml .Values.worker.resources | nindent 10 }}
```

### 7.6 Ingress

`templates/ingress.yaml`

```yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: acmeshop
  annotations:
    kubernetes.io/ingress.class: {{ .Values.ingress.className | quote }}
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
{{- if and .Values.ingress.tls.enabled .Values.ingress.host }}
    cert-manager.io/cluster-issuer: {{ .Values.ingress.tls.issuer | quote }}
{{- end }}
spec:
{{- if .Values.ingress.tls.enabled }}
  tls:
  - hosts: [{{ .Values.ingress.host | quote }}]
    secretName: acmeshop-tls
{{- end }}
  rules:
  - host: {{ default "" .Values.ingress.host | quote }}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web
            port: { number: 80 }
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api
            port: { number: 8080 }
{{- end }}
```

### 7.7 HPA (web/api)

`templates/hpa-web.yaml`

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60
```

`templates/hpa-api.yaml` (same, `name: api` and `scaleTargetRef.name: api`)

### 7.8 PDB

`templates/pdb.yaml`

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: web-pdb
spec:
  minAvailable: 1
  selector:
    matchLabels: { app: web }
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-pdb
spec:
  minAvailable: 1
  selector:
    matchLabels: { app: api }
```

### 7.9 NetworkPolicies

`templates/networkpolicy.yaml`

```yaml
# Default deny ALL ingress in namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
spec:
  podSelector: {}
  policyTypes: ["Ingress"]

---
# Allow ingress-nginx to reach web/api
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-ingress
spec:
  podSelector:
    matchExpressions:
    - key: app
      operator: In
      values: ["web","api"]
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          app.kubernetes.io/name: ingress-nginx
```

---

# 8) Vendor dependency (Redis) & render

```powershell
cd .\acmeshop\charts\acmeshop
helm dependency update   # will pull bitnami/redis into charts/
helm template .\ | more  # preview everything
```

---

# 9) Deploy to **staging**

```powershell
helm upgrade --install acmeshop . `
  -n staging -f values.yaml -f values.staging.yaml

kubectl -n staging get all
kubectl -n staging get ing
```

Get the Ingress Controller’s public IP and hit the app. For a quick test without DNS, add a **hosts file** entry pointing your chosen host (or use the IP directly if you didn’t set a host).

---

# 10) TLS (self-signed now, Let’s Encrypt later)

If `ingress.tls.enabled=true` and `host` is set in values, cert-manager will create a TLS secret (`acmeshop-tls`) using `ClusterIssuer/selfsigned`.
For **Let’s Encrypt**, create an ACME `ClusterIssuer` (HTTP-01) and swap the issuer in `values.*.yaml`.

---

# 11) Deploy to **prod**

```powershell
helm upgrade --install acmeshop . `
  -n prod -f values.yaml -f values.prod.yaml
```

Point your real DNS (`shop.example.com`) at the ingress public IP. Verify TLS, scaling, and paths (`/` → web, `/api` → api).

---

# 12) Day-2: upgrades, rollbacks, canaries

**Upgrade**:

```powershell
# bump image tag in values and:
helm upgrade acmeshop . -n staging -f values.yaml -f values.staging.yaml
```

**Rollback**:

```powershell
helm history acmeshop -n staging
helm rollback acmeshop <REVISION> -n staging
```

**Canary** (via NGINX annotations; deploy a second Ingress pointing to canary Service and set canary-weight):

```powershell
kubectl -n staging annotate ingress acmeshop \
  nginx.ingress.kubernetes.io/canary="true" \
  nginx.ingress.kubernetes.io/canary-weight="10" --overwrite
```

---

# 13) (Optional) Publish your chart to **ACR (OCI)**

```powershell
# Get an ACR access token (user + password)
$token = az acr login -n $ACR --expose-token --output tsv --query accessToken
$uname = "00000000-0000-0000-0000-000000000000"
helm registry login "$ACR.azurecr.io" --username $uname --password $token

# Package & push
helm package .
helm push acmeshop-0.1.0.tgz oci://$ACR.azurecr.io/helm

# Install from ACR
helm pull oci://$ACR.azurecr.io/helm/acmeshop --version 0.1.0
helm upgrade --install acmeshop oci://$ACR.azurecr.io/helm/acmeshop `
  -n prod -f values.yaml -f values.prod.yaml
```

---

# 14) Production checklist (use/extend as needed)

* **RBAC/SA**: already namespace-scoped. Consider splitting deployer vs runtime SAs.
* **Secrets**: use **Azure Key Vault** with **External Secrets Operator** or CSI driver (avoid plain K8s Secrets).
* **Resources**: `requests/limits` set. Add **VPA** if needed.
* **Availability**: **PDBs**, replica ≥2 for critical workloads, multiple nodes/availability zones.
* **Autoscaling**: HPAs added; consider custom metrics (e.g., Prometheus Adapter).
* **Network**: default-deny, explicit allow (ingress-nginx → web/api; api → redis).
* **Ingress**: NGINX controller HA (2 replicas), TLS via cert-manager (Let’s Encrypt).
* **Observability**: Azure Monitor/Container Insights enabled; consider Prometheus/Grafana.
* **Backups/DR**: Velero for K8s objects & PVs; ACR/Registry backups; DB backups.
* **CI/CD**: GitHub Actions or Azure DevOps pipeline running `helm lint`, `helm template`, `helm test`, and `helm upgrade`.
* **Testing**: add a `helm test` Pod (e.g., curl to `/healthz`).
* **Policies**: Gatekeeper/OPA or Azure Policy for AKS.
* **Images**: sign with Notation/ACR, scan images (ACR Microsoft Defender plan).
* **Cost**: right-size nodes, use Spot for workers where safe, autoscale node pool.

---

## Ready-to-run commands (quick recap)

```powershell
# 1) Cluster & tooling
az group create -n rg-helm-aks -l eastus
az acr create -n <acr> -g rg-helm-aks --sku Standard
az aks create -g rg-helm-aks -n aks-acmeshop --enable-managed-identity --node-count 2
az aks update -g rg-helm-aks -n aks-acmeshop --attach-acr <acr>
az aks get-credentials -g rg-helm-aks -n aks-acmeshop --overwrite-existing

# 2) Ingress + (optional) cert-manager
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace
helm repo add jetstack https://charts.jetstack.io
helm upgrade --install cert-manager jetstack/cert-manager -n cert-manager --create-namespace --set installCRDs=true

# 3) Namespaces with PSA labels
kubectl create ns staging; kubectl create ns prod
kubectl label ns staging pod-security.kubernetes.io/enforce=baseline --overwrite=true
kubectl label ns prod    pod-security.kubernetes.io/enforce=baseline --overwrite=true

# 4) Deploy AcmeShop
cd .\acmeshop\charts\acmeshop
helm dependency update
helm upgrade --install acmeshop . -n staging -f values.yaml -f values.staging.yaml
# later
helm upgrade --install acmeshop . -n prod -f values.yaml -f values.prod.yaml
```

---


