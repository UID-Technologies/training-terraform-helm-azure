
#  Extended Lab: Node.js App with Ingress + TLS (Helm + Terraform)

---

##  Step 1: Prerequisites

* Domain name (e.g., `myaksapp.example.com`) pointing to your AKS Ingress public IP.
* Terraform, Helm, kubectl, Docker installed.
* Prior lab completed (Node app + Helm + ConfigMap + HPA).

---

##  Step 2: Install NGINX Ingress Controller with Helm (via Terraform)

Add Helm release for NGINX Ingress in **main.tf**:

```hcl
resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
  create_namespace = true

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }
}
```

Apply changes:

```bash
terraform apply -auto-approve
```

Check service:

```bash
kubectl get svc -n ingress-nginx
```

You’ll see an **EXTERNAL-IP** — use it in your domain’s DNS `A` record.

---

##  Step 3: Install Cert-Manager (for TLS)

Add Helm release for **cert-manager**:

```hcl
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }
}
```

---

##  Step 4: Create ClusterIssuer for Let’s Encrypt

Create a file `cert-issuer.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: your-email@example.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```

Apply it:

```bash
kubectl apply -f cert-issuer.yaml
```

---

##  Step 5: Update Node.js Helm Chart with Ingress + TLS

Edit `values.yaml` in your **node-app chart**:

```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: myaksapp.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: node-app-tls
      hosts:
        - myaksapp.example.com
```

---

###  `templates/ingress.yaml`

```yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "node-app.fullname" . }}
  annotations:
    kubernetes.io/ingress.class: {{ .Values.ingress.className }}
    {{- with .Values.ingress.annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  rules:
  {{- range .Values.ingress.hosts }}
    - host: {{ .host }}
      http:
        paths:
        {{- range .paths }}
          - path: {{ .path }}
            pathType: {{ .pathType }}
            backend:
              service:
                name: {{ include "node-app.fullname" $ }}
                port:
                  number: {{ $.Values.service.port }}
        {{- end }}
  {{- end }}
  tls:
  {{- range .Values.ingress.tls }}
    - secretName: {{ .secretName }}
      hosts:
      {{- range .hosts }}
        - {{ . }}
      {{- end }}
  {{- end }}
{{- end }}
```

---

##  Step 6: Deploy Updated Helm Release

Update Terraform Helm release in **main.tf**:

```hcl
resource "helm_release" "node_app" {
  name       = "node-app"
  chart      = "./node-app"
  namespace  = "default"

  set {
    name  = "image.repository"
    value = azurerm_container_registry.acr.login_server .. "/node-aks-app"
  }

  set {
    name  = "image.tag"
    value = "v2"
  }

  set {
    name  = "appMessage"
    value = "Hello from Node.js over HTTPS with Ingress + TLS "
  }
}
```

Apply:

```bash
terraform apply -auto-approve
```

---

##  Step 7: Verify

1. Check Ingress:

```bash
kubectl get ingress
```

2. Open in browser:

```
https://myaksapp.example.com
```

 You’ll see:

```
Hello from Node.js over HTTPS with Ingress + TLS 
```

---

##  Step 8: Cleanup

```bash
terraform destroy -auto-approve
```

---

#  Summary

Now your Node.js app on AKS supports:

* **Ingress Controller (NGINX)** → routes traffic
* **Cert-Manager with Let’s Encrypt** → auto TLS certificates
* **Helm + Terraform** → fully automated provisioning
* **HTTPS endpoint** for secure access 

