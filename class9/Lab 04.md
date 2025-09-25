
#  Extended Lab: ConfigMaps + HPA for Node.js App on AKS (Helm + Terraform)

---

##  Step 1: Update Node.js App to use Env Vars

Modify `app.js`:

```js
const express = require("express");
const app = express();
const port = process.env.PORT || 3000;
const message = process.env.APP_MESSAGE || "Hello from default message! ";

app.get("/", (req, res) => {
  res.send(message);
});

app.listen(port, () => {
  console.log(`App running at http://localhost:${port}`);
});
```

Rebuild & push new image:

```bash
docker build -t aksregistry123.azurecr.io/node-aks-app:v2 .
docker push aksregistry123.azurecr.io/node-aks-app:v2
```

---

##  Step 2: Extend Helm Chart with ConfigMap

Inside `node-app/templates/`, create a file:

###  `configmap.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "node-app.fullname" . }}-config
data:
  APP_MESSAGE: {{ .Values.appMessage | quote }}
```

---

Update **deployment.yaml** to mount ConfigMap as env vars:

```yaml
envFrom:
  - configMapRef:
      name: {{ include "node-app.fullname" . }}-config
```

---

##  Step 3: Add HPA Template

Inside `node-app/templates/`, create:

###  `hpa.yaml`

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "node-app.fullname" . }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "node-app.fullname" . }}
  minReplicas: {{ .Values.autoscaling.minReplicas }}
  maxReplicas: {{ .Values.autoscaling.maxReplicas }}
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: {{ .Values.autoscaling.targetCPUUtilizationPercentage }}
```

---

##  Step 4: Extend `values.yaml`

```yaml
replicaCount: 2

image:
  repository: aksregistry123.azurecr.io/node-aks-app
  tag: v2
  pullPolicy: Always

service:
  type: LoadBalancer
  port: 80

containerPort: 3000

appMessage: "Hello from Node.js app with ConfigMap + HPA "

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 5
  targetCPUUtilizationPercentage: 50
```

---

##  Step 5: Terraform Helm Release with Config + HPA

Update **helm\_release** block in `main.tf`:

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
    value = "Deployed via Terraform + Helm with HPA "
  }
}
```

---

##  Step 6: Deploy & Verify

```bash
terraform apply -auto-approve
```

Check resources:

```bash
kubectl get configmap
kubectl get pods
kubectl get hpa
```

Simulate load (optional):

```bash
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh
# inside pod
while true; do wget -q -O- http://node-app.default.svc.cluster.local; done
```

Watch autoscaling:

```bash
kubectl get hpa --watch
```

You’ll see pods scaling up/down based on CPU usage 

---

##  Step 7: Cleanup

```bash
terraform destroy -auto-approve
```

---

#  Summary

Now your **Node.js Helm app on AKS** supports:

1. **ConfigMap** → dynamic environment variables
2. **HPA** → scales pods based on CPU utilization
3. Fully managed via **Terraform + Helm**

---

