## Lab 14 — A Look at Remaining CLI Commands

### Objective

Gain familiarity with lesser‑used but valuable Helm CLI commands.

### Description (Scenario)

SREs need a ready reference for day‑to‑day tasks and debugging.

### Explanations

* `dependency` locks subchart versions; `pull` fetches and untars third‑party charts for inspection.

### Steps

```powershell
helm create payments
# add subcharts in payments/Chart.yaml, then
helm dependency update .\payments
helm pull bitnami/redis --untar --version 19.0.0
helm registry login $ACR.azurecr.io   # OCI login if using ACR for charts
helm show values bitnami/redis | more
helm uninstall web-a -n team-a  # sample uninstall
```

### Verify

* Commands run successfully; outputs match expectations.

### Troubleshoot

* Version not found → `helm search repo <chart> --versions` to pick a valid one.

### Conclusion

You now have a working knowledge of the full Helm CLI surface for real‑world ops.

---

## Appendix — Cross‑Cutting Best Practices

* **Values layering** per env; keep sensitive values out of Git (use Key Vault/ESO).
* **Pin versions** for charts, images, and dependencies; commit `Chart.lock`.
* **Always diff before upgrade** (`helm diff`), then upgrade; keep rollback muscle memory.
* **Policy gates** in CI with `helm template | conftest`.
* **Observability**: liveness/readiness probes, metrics annotations, and dashboards.

## Final Conclusion

Across these scenario‑based labs, you learned to operate Helm securely and effectively: from RBAC and private repos to blue/green, canaries, policy testing, and failure recovery—all on Windows with AKS. This mirrors how modern platform and app teams ship confidently in production.
