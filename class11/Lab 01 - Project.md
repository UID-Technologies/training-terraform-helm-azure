
# Simple Helm Project to Deploy Multi-Container App on AKS

### Application design

* **web** Pod:

  * `nginx` (reverse proxy)
  * `webapp` (Node.js)
* **api** Pod: Node.js API
* **redis**: external dependency (Bitnami chart)

---

### Project Structure
```yaml
acmeshop/
  Chart.yaml
  values.yaml
  templates/
    deployment.yaml     # web (nginx + webapp)
    api.yaml            # api
    ingress.yaml        # ingress rules
  api/
    Dockerfile
    server.js
  webapp
    Dockerfile
    server.js
```



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


## Step 4: WebApp (Node.js frontend)

We’ll make a minimal Express.js frontend that renders a page and also calls your API service.

`webapp/server.js`

```js
const express = require("express");
const path = require("path");
const app = express();
const PORT = process.env.PORT || 3000;

// Serve static files (if you want to add HTML/CSS/JS later)
app.use(express.static(path.join(__dirname, "public")));

// Root route
app.get("/", (req, res) => {
  res.send(`
    <html>
      <head><title>AcmeShop</title></head>
      <body>
        <h1>Welcome to AcmeShop WebApp</h1>
        <p>This page is served by the Node.js webapp, proxied by Nginx.</p>
        <p>Try the <a href="/products">Products Page</a>.</p>
      </body>
    </html>
  `);
});

// Products page calls the backend API
app.get("/products", async (req, res) => {
  try {
    const fetch = (await import("node-fetch")).default;
    const apiResp = await fetch("http://api:8080/api/products"); // service name `api`
    const products = await apiResp.json();

    let html = "<h2>Product List (from API)</h2><ul>";
    products.forEach(p => {
      html += `<li>${p.name} - $${p.price}</li>`;
    });
    html += "</ul><a href='/'>Back</a>";

    res.send(html);
  } catch (err) {
    res.status(500).send("Error fetching products from API: " + err);
  }
});

app.listen(PORT, () => {
  console.log(`Webapp running on port ${PORT}`);
});

```

`webapp/Dockerfile`

```dockerfile
FROM node:20-alpine

# Set work directory
WORKDIR /app

# Copy source
COPY server.js .

# Install dependencies
RUN npm init -y && npm install express node-fetch

# Expose app port
EXPOSE 3000

# Run app
CMD ["node", "server.js"]

```

### Build & Push Image

From inside the webapp/ folder:
```bash
# Build Docker image
docker build -t <docker_hub_account>/webapp:1.0 .

# Push to DockerHub (or ACR if using Azure)
docker push <docker_hub_account>/webapp:1.0

```

## Step 5: Api (Node.js backend)

We’ll make a minimal Express.js backend 

`api/server.js`

```js
const express = require("express");
const app = express();
const PORT = process.env.PORT || 8080;

app.use(express.json());

app.get("/api", (req, res) => {
  res.json({ message: "Welcome to AcmeShop API", status: "OK" });
});

app.get("/api/products", (req, res) => {
  res.json([
    { id: 1, name: "Laptop", price: 999 },
    { id: 2, name: "Phone", price: 499 },
    { id: 3, name: "Tablet", price: 299 }
  ]);
});

app.listen(PORT, () => {
  console.log(`API running on port ${PORT}`);
});


```

`webapp/Dockerfile`

```dockerfile
FROM node:20-alpine

WORKDIR /app

COPY server.js .

RUN npm init -y && npm install express

EXPOSE 8080

CMD ["node", "server.js"]

```



### Build & Push Image
```bash
# Build Docker image
docker build -t <docker_hub_account>/webapp:1.0 .

# Push to DockerHub (or ACR if using Azure)
docker push <docker_hub_account>/webapp:1.0

```


## Step 6: Define Values

Edit `values.yaml`:

```yaml
image:
  registry: docker.io   # replace with ACR if needed
  nginx: "nginx:latest"
  app: "<docker_hub_account>/webapp:1.0"
  api: "<docker_hub_account>/api:1.0"

web:
  replicas: 2
  containerPort: 3000
  nginxPort: 8080

api:
  replicas: 2
  containerPort: 8080
```

---

## Step 7: Web Deployment (multi-container)

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

## Step 8: API Deployment

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

## Step 9: Ingress

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

## Step 10: Deploy Redis (dependency)

```powershell
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install redis bitnami/redis -n default
```

---

## Step 11: Install Your Chart

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
