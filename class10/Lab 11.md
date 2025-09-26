## Lab 11 — How to Test It All: Hooks, Unittest Plugin, Conftest/OPA, `helm template`

### Objective

Add multi‑layer testing: runtime smoke tests, unit tests, and policy checks; leverage `helm template` for CI.

### Description (Scenario)

Platform mandates tests before promotion to `prod`.

### Explanations

* **Hook tests** run in‑cluster after install/upgrade.
* **helm‑unittest** validates templates statically.
* **Conftest/OPA** enforces org policies (e.g., deny LB in dev).

### Steps

1. **Hook‑based test pod** (in chart)

   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: "{{ include "cart.fullname" . }}-test"
     annotations: { "helm.sh/hook": test }
   spec:
     containers:
     - name: wget
       image: busybox
       command: ['sh','-c','wget -qO- http://{{ include "cart.fullname" . }}:{{ .Values.service.port }}/healthz || exit 1']
     restartPolicy: Never
   ```

   Run: `helm test cart-stable -n staging`
2. **helm‑unittest**

   ```powershell
   helm plugin install https://github.com/quintush/helm-unittest
   mkdir .\cart\tests -Force
   @"
   suite: Service checks
   templates:
     - templates/service.yaml
   tests:
     - it: should be ClusterIP in dev
       set:
         - name: global.env
           value: dev
       asserts:
         - equal:
             path: spec.type
             value: ClusterIP
   "@ | Set-Content .\cart\tests\service_test.yaml
   helm unittest .\cart
   ```
3. **Conftest/OPA**

   ```powershell
   choco install conftest -y
   mkdir .\policy -Force
   @"
   package k8s
   deny[msg] {
     input.kind == "Service"
     input.metadata.namespace == "dev"
     input.spec.type == "LoadBalancer"
     msg := "LoadBalancer Services not allowed in dev"
   }
   "@ | Set-Content .\policy\deny-lb-in-dev.rego

   helm template cart .\cart -n dev | conftest test -p .\policy -
   ```
4. **Render for CI**

   ```powershell
   helm template cart .\cart --values .\values.dev.yaml > rendered.yaml
   kubectl apply --dry-run=client -f rendered.yaml
   ```

### Verify

* Hook test Succeeds; unit tests pass; conftest denies bad patterns.

### Troubleshoot

* Conftest input errors → pipe YAML with `-`.

### Conclusion

You’ve built layered quality gates that prevent regressions and policy drift.

---

