## Lab 10 — Inspecting Charts and Releases (Forensics)

### Objective

Audit what’s deployed, which values were used, and how things changed over time.

### Description (Scenario)

SREs need a paper trail for incidents and compliance.

### Explanations

* `helm get` family retrieves rendered manifests/values; `history` shows revision timeline.

### Steps

```powershell
helm get values cart-stable -n staging
helm get manifest cart-stable -n staging | more
helm get notes cart-stable -n staging
helm history cart-stable -n staging
# If helm-diff plugin is installed
helm diff revision cart-stable 3 4 -n staging
```

### Verify

* You can account for every change to the release.

### Troubleshoot

* Wrong namespace or release name leads to “unknown release”.

### Conclusion

Operational visibility is established for audits and RCA work.

---

