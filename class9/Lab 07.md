

#  Extended Lab: Observability with Prometheus + Grafana on AKS (Helm + Terraform)

---

##  Step 1: Prerequisites

* Prior lab with **Node.js app on AKS** (Helm, ConfigMap, HPA, Ingress + TLS, Key Vault).
* Terraform, Helm, kubectl installed.
* A running AKS cluster.

---

##  Step 2: Add Helm Repositories

In Terraform, add Helm releases for **Prometheus** and **Grafana**.

###  `main.tf`

```hcl
# Prometheus
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  create_namespace = true

  set {
    name  = "grafana.adminPassword"
    value = "AdminPass123"
  }
}

# Grafana (already included in kube-prometheus-stack, but if you want separate chart use below)
# resource "helm_release" "grafana" {
#   name       = "grafana"
#   repository = "https://grafana.github.io/helm-charts"
#   chart      = "grafana"
#   namespace  = "monitoring"
#   create_namespace = true
# }
```

 The `kube-prometheus-stack` chart includes **Prometheus, Grafana, Alertmanager** and default dashboards.

Apply changes:

```bash
terraform apply -auto-approve
```

---

##  Step 3: Expose Grafana

Check Grafana service:

```bash
kubectl get svc -n monitoring
```

You’ll see something like:

```
prometheus-grafana   ClusterIP   10.0.156.99   <none>        80/TCP   1m
```

Expose via **Ingress** (reuse your existing ingress controller).

###  `grafana-ingress.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana-ingress
  namespace: monitoring
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  rules:
    - host: grafana.myaksapp.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: prometheus-grafana
                port:
                  number: 80
  tls:
    - secretName: grafana-tls
      hosts:
        - grafana.myaksapp.example.com
```

Apply:

```bash
kubectl apply -f grafana-ingress.yaml
```

---

##  Step 4: Access Grafana

Get Grafana admin password:

```bash
kubectl get secret prometheus-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 --decode
```

Login at:

```
https://grafana.myaksapp.example.com
```

Default username: `admin`
Password: value from above

---

##  Step 5: Create Node.js App Metrics Endpoint

Update your **Node.js app** (`app.js`) to expose Prometheus metrics:

```js
const express = require("express");
const client = require("prom-client");
const app = express();
const port = process.env.PORT || 3000;

// Prometheus metrics
const collectDefaultMetrics = client.collectDefaultMetrics;
collectDefaultMetrics({ timeout: 5000 });

const counter = new client.Counter({
  name: "http_requests_total",
  help: "Total number of requests",
});

app.get("/", (req, res) => {
  counter.inc();
  res.send("Hello from Node.js app with Prometheus metrics 🚀");
});

app.get("/metrics", async (req, res) => {
  res.set("Content-Type", client.register.contentType);
  res.end(await client.register.metrics());
});

app.listen(port, () => {
  console.log(`App running at http://localhost:${port}`);
});
```

Rebuild and push:

```bash
docker build -t aksregistry123.azurecr.io/node-aks-app:v4 .
docker push aksregistry123.azurecr.io/node-aks-app:v4
```

Update **Helm values.yaml**:

```yaml
image:
  repository: aksregistry123.azurecr.io/node-aks-app
  tag: v4

service:
  type: LoadBalancer
  port: 80
  targetPort: 3000

metrics:
  enabled: true
  path: /metrics
  port: 3000
```

---

##  Step 6: ServiceMonitor for Node.js App

Prometheus Operator uses a `ServiceMonitor` to scrape metrics.

Create `templates/servicemonitor.yaml` in your Node app Helm chart:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {{ include "node-app.fullname" . }}
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ include "node-app.name" . }}
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
```

Apply via Terraform Helm release update.

---

##  Step 7: Verify Monitoring

Check targets in Prometheus:

```bash
kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090
```

Visit:

```
http://localhost:9090/targets
```

You should see your Node.js app as a target.

Check Grafana dashboards at:

```
https://grafana.myaksapp.example.com
```

* Import dashboard ID `1860` (Node.js/Express) or `3662` (Prometheus stats) from Grafana community.

---

##  Step 8: Cleanup

```bash
terraform destroy -auto-approve
```

---

#  Summary

Now your AKS setup has **full observability**:

* **Prometheus** → collects metrics from Node.js app (`/metrics`)
* **Grafana** → dashboards & visualization (HTTPS via Ingress + cert-manager)
* **ServiceMonitor** → automatically scrapes app metrics
* Everything provisioned via **Terraform + Helm** 

---

