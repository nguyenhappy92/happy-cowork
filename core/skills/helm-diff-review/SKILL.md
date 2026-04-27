---
name: helm-diff-review
description: Use when reviewing a `helm diff upgrade` or ArgoCD diff output before applying a Kubernetes release, or "/helm-diff". Flags destructive changes, image rollbacks, and risky manifest mutations.
tools: [cursor, claude, copilot]
---

# helm-diff-review

## When to use

- "review this helm diff"
- "is this release safe to apply?"
- "/helm-diff"
- "what does this ArgoCD sync change?"

## Preconditions

- A `helm diff upgrade <release> <chart>` output, OR an `argocd app diff <app>` output, OR `kubectl diff -f` output.
- Optional: target cluster context, current image tag, change ticket.

## Procedure

1. **Parse the diff.** Group changes by Kubernetes `kind` and `name`. Note adds (`+`), removes (`-`), and modifications.

2. **Categorize changes by risk:**

   | Change | Risk |
   |---|---|
   | New `Deployment` / `StatefulSet` / `Job` / `CronJob` | low–medium |
   | Image tag update on `Deployment` | medium (verify it's a roll-forward, not rollback) |
   | `replicas` change | low (scale-up) / medium (scale-down) |
   | `resources` (requests/limits) change | medium (eviction / scheduling) |
   | `livenessProbe` / `readinessProbe` change | medium (rollout stalls) |
   | `Service` `type` change (ClusterIP ↔ LoadBalancer ↔ NodePort) | HIGH (public exposure) |
   | `Service` `selector` change | HIGH (silent traffic loss) |
   | `Ingress` host / TLS change | HIGH |
   | `PersistentVolumeClaim` size or storageClass change | HIGH (data risk; some are immutable) |
   | `StatefulSet` `volumeClaimTemplates` change | HIGH (immutable; recreate required) |
   | `NetworkPolicy` change | HIGH (silent traffic loss) |
   | `RoleBinding` / `ClusterRoleBinding` add/escalation | HIGH |
   | `ServiceAccount` annotation change (IRSA / Workload Identity) | HIGH |
   | `Secret` data change | HIGH (rotate-or-break) |
   | `ConfigMap` change consumed via env (no rolling update trigger) | medium (won't propagate without restart) |
   | `CRD` schema change | HIGH (cluster-wide blast radius) |
   | Resource removal (`-` Deployment / Service / PVC) | HIGH |

3. **Verify image direction.** If image tag changed, check that the new tag is newer / has a higher build number. A "downgrade" is often an unintended rollback.

4. **Check for missing rollout triggers.** ConfigMap/Secret changes mounted as files don't restart pods unless the chart adds a checksum annotation (`checksum/config: …`). Flag if the change won't be picked up.

5. **Check release-level concerns:**
   - Hooks: `helm.sh/hook: pre-upgrade,post-upgrade,pre-delete`. Pre-upgrade hooks can mutate cluster state before the rollback window.
   - `--atomic` / `--wait` not used? Suggest enabling.
   - Chart version bump: read the chart's `CHANGELOG.md` / `Chart.yaml` for breaking changes.

6. **Report:**
   ```markdown
   ## Helm Diff Review — <release> on <context>

   **Chart:** <name> <old-ver> → <new-ver>
   **Verdict:** safe | needs-changes | high-risk

   ### High-risk changes
   - `Service/api` `selector.app` changed `api` → `api-v2` — will sever traffic until pods labeled v2 exist.
   - `PVC/postgres-data` storageClass changed — likely requires recreate; data loss risk.

   ### Medium-risk changes
   - `Deployment/web` resources.limits.memory 512Mi → 256Mi — risk of OOMKill under load.

   ### Safe changes
   - +1 NetworkPolicy `allow-monitoring`

   ### Recommendations
   - [ ] Snapshot `pvc/postgres-data` before apply.
   - [ ] Verify `api-v2` Deployment is rolled out before changing Service selector (do as two releases).
   - [ ] Run `helm upgrade --atomic --wait --timeout 5m`.
   - [ ] Apply during off-peak window.
   ```

## Guardrails

- **Never run** `helm upgrade`, `helm rollback`, `argocd app sync`, or `kubectl apply` — analysis only.
- If the diff includes >30 changes, summarize by `kind` rather than listing every object.
- Always cross-check `kubectl config current-context` if the user includes a context — confirm intended cluster before reviewing prod-impacting diffs.
- If the diff format is ambiguous (no `+` / `-` markers), ask for `helm diff` instead of plain template diff.
