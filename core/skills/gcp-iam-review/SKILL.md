---
name: gcp-iam-review
description: Use when reviewing GCP IAM bindings, custom roles, or service-account permissions, checking for over-broad grants or impersonation paths, or "/iam-review-gcp". Audits GCP IAM for least-privilege violations.
tools: [cursor, claude, copilot]
---

# gcp-iam-review

## When to use

- "review this GCP IAM policy"
- "is this service account least-privilege?"
- "/iam-review-gcp"
- "audit project / folder / org IAM bindings"

## Inputs

- A policy from `gcloud projects get-iam-policy <proj> --format=json` (or folder/org/resource equivalent).
- Optional: target scope (project, folder, org), the principal in question, intended use case.

## Procedure

1. **Confirm scope.** GCP IAM inherits downward: org → folder → project → resource. Always evaluate the **effective** binding for a principal at the resource being reviewed, not just direct grants.

2. **List bindings.** For each `binding`, capture `role`, `members`, `condition`.

3. **Flag risky patterns:**

   | Pattern | Why it's risky |
   |---|---|
   | `roles/owner` at org or folder | god mode |
   | `roles/editor` to a human user or external SA | broad write across services |
   | `roles/iam.securityAdmin` + `roles/iam.serviceAccountTokenCreator` together | self-escalation |
   | `roles/iam.serviceAccountUser` on a privileged SA | impersonation chain |
   | `roles/iam.serviceAccountTokenCreator` on a privileged SA | mint tokens for it |
   | `roles/iam.workloadIdentityUser` granted broadly | external workload can impersonate |
   | `allUsers` or `allAuthenticatedUsers` on storage/PubSub/BigQuery | public data |
   | `roles/cloudkms.cryptoKeyDecrypter` on a KMS key with broad members | broad data access |
   | Primitive roles (`owner`, `editor`, `viewer`) at all | always prefer predefined / custom |
   | Custom role with `*` permissions or `*.set*IamPolicy` | self-escalation |
   | Bindings without `condition` on time-bound or tag-based scopes | no guardrail |
   | External-domain principals (`user:…@external`) outside expected list | unexpected access |

4. **Check service-account hygiene:**
   - User-managed keys present? (Should be **none**; prefer Workload Identity Federation / impersonation.)
   - Default compute / App Engine SAs being used? (Should be replaced with scoped SAs.)
   - SA impersonation chains: who can `actAs` whom?

5. **Check VPC-SC and Org Policies:** Are there constraints like `iam.allowedPolicyMemberDomains`, `iam.disableServiceAccountKeyCreation`? Note gaps.

6. **Suggest least-privilege rewrites.** Replace primitive / broad predefined roles with:
   - Storage: `roles/storage.objectViewer`, `roles/storage.objectCreator`
   - Secrets: `roles/secretmanager.secretAccessor` (scoped to specific secret)
   - GKE: `roles/container.developer` instead of `roles/container.admin`

7. **Report:**
   ```markdown
   ## GCP IAM Review — <scope>

   **Verdict:** safe | needs-changes | high-risk

   ### High-risk findings
   - `roles/owner` granted to `group:platform@…` at org. Recommend scoping to specific folders, time-bound.
   - SA `data-pipeline@…` has `roles/iam.serviceAccountTokenCreator` on `prod-admin@…` — privilege escalation path.

   ### Suggested rewrite
   ```diff
   - role: roles/editor
   - members: [user:dev@example.com]
   + role: roles/storage.objectAdmin
   + members: [user:dev@example.com]
   + condition:
   +   title: "ttl-2026-q3"
   +   expression: 'request.time < timestamp("2026-09-30T00:00:00Z")'
   ```

   ### Recommendations
   - [ ] Disable user-managed SA keys via org policy.
   - [ ] Replace default compute SA usage on `<workload>`.
   - [ ] Adopt Workload Identity Federation for CI principals.
   ```

## Guardrails

- **Never run** `gcloud projects add-iam-policy-binding`, `remove-iam-policy-binding`, `set-iam-policy`, or `iam service-accounts keys create` — review only.
- For impersonation chains, list every hop before suggesting removal of any link.
- Distinguish org-level vs project-level findings in the report — the remediation owner is different.
- Treat `allUsers` / `allAuthenticatedUsers` as critical, regardless of resource type.
