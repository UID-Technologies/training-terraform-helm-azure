
# Simple Helm Project to Deploy Multi-Container App on AKS

### Application design

* **web** Pod:

  * `nginx` (reverse proxy)
  * `webapp` (Node.js)
* **api** Pod: Node.js API
* **redis**: external dependency (Bitnami chart)

---

## Step 1: Setup AKS & Helm

```powershell
# Variables
$RG="rg-helm-simple"
$LOC="eastus"
$AKS="aks-simple"

# Create resource group
az group create -n $RG -l $LOC

# Create AKS cluster
az aks create -g $RG -n $AKS --node-count 2 --enable-managed-identity

# Get kubeconfig
az aks get-credentials -g $RG -n $AKS --overwrite-existing

# Install Helm (if not already)
winget install Helm.Helm
```

---

## Step 2: Install Ingress Controller (NGINX)

```powershell
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx `
  -n ingress-nginx --create-namespace
```

---

## Step 3: Create Helm Chart

```powershell
helm create acmeshop
cd acmeshop
```

This generates a starter chart under `acmeshop/`.

---

## Step 4: Define Values

Edit `values.yaml`:

```yaml
image:
  registry: docker.io   # replace with ACR if needed
  web: "nginx:1.27-alpine"
  app: "myuser/webapp:1.0"
  api: "myuser/api:1.0"

web:
  replicas: 2
  containerPort: 3000
  nginxPort: 8080

api:
  replicas: 2
  containerPort: 8080
```

---

## Step 5: Web Deployment (multi-container)

Replace `templates/deployment.yaml` with:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: {{ .Values.web.replicas }}
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: webapp
        image: "{{ .Values.image.registry }}/{{ .Values.image.app }}"
        ports:
        - containerPort: {{ .Values.web.containerPort }}
      - name: nginx
        image: "{{ .Values.image.registry }}/{{ .Values.image.web }}"
        ports:
        - containerPort: {{ .Values.web.nginxPort }}
---
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  selector:
    app: web
  ports:
  - port: 80
    targetPort: {{ .Values.web.nginxPort }}
```

---

## Step 6: API Deployment

Create `templates/api.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  replicas: {{ .Values.api.replicas }}
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: "{{ .Values.image.registry }}/{{ .Values.image.api }}"
        ports:
        - containerPort: {{ .Values.api.containerPort }}
---
apiVersion: v1
kind: Service
metadata:
  name: api
spec:
  selector:
    app: api
  ports:
  - port: 8080
    targetPort: {{ .Values.api.containerPort }}
```

---

## Step 7: Ingress

Create `templates/ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: acmeshop
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api
            port:
              number: 8080
```

---

## Step 8: Deploy Redis (dependency)

```powershell
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install redis bitnami/redis -n default
```

---

## Step 9: Install Your Chart

```powershell
# From inside acmeshop/
helm upgrade --install acmeshop . -n default
```

Check:

```powershell
kubectl get pods,svc,ingress
```

Access via the Ingress public IP.

---

# What You Get

* **Multi-container web Pod** (`nginx + webapp`)
* **API Pod**
* **Redis** via Bitnami
* **Services** for internal DNS
* **Ingress** for external access (`/` → web, `/api` → api)
* Simple but extendable for scaling, TLS, RBAC later

---
