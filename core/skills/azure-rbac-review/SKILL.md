---
name: azure-rbac-review
description: Use when reviewing Azure RBAC role assignments, custom role definitions, or management-group scope, checking for over-broad permissions, or "/rbac-review-azure". Audits Azure RBAC for least-privilege violations.
tools: [cursor, claude, copilot]
---

# azure-rbac-review

## When to use

- "review this Azure role assignment"
- "is this custom role least-privilege?"
- "/rbac-review-azure"
- "audit role assignments at this subscription / management group"

## Inputs

- A role definition JSON (`az role definition show …`) or assignment list (`az role assignment list --all -o json`).
- Optional: scope (management group, subscription, resource group, resource), the principal type (user, group, SPN, managed identity).

## Procedure

1. **Identify scope hierarchy.** Note that an assignment at `management group → subscription → RG → resource` inherits downward. Always report the **effective** scope, not just where the assignment was created.

2. **Catalogue assignments / actions.** For each role, list:
   - `actions`, `notActions`
   - `dataActions`, `notDataActions`
   - `assignableScopes`
   - Principal display name and object ID
   - Scope path

3. **Flag risky patterns:**

   | Pattern | Why it's risky |
   |---|---|
   | Built-in `Owner` or `User Access Administrator` outside break-glass | can re-grant itself anywhere |
   | `Contributor` at management-group or subscription scope to a human user | excess blast radius |
   | `*` in `actions` of a custom role | full plane access |
   | `Microsoft.Authorization/*/write` granted broadly | self-escalation via role assignment |
   | `Microsoft.KeyVault/vaults/*/secrets/getSecret/action` (dataActions) on `*` | broad secret read |
   | Assignment to a guest user without conditional access | weak auth posture |
   | Assignment to an SPN with no expiry / no review | stale identity risk |
   | Classic administrators still present | bypasses RBAC |
   | `assignableScopes: ["/"]` on a custom role | tenant-wide reuse |

4. **Check Conditional Access & PIM:**
   - Is the role eligible (PIM) or active? Prefer eligible + JIT for privileged roles.
   - Is MFA enforced for the assignee?
   - Are there break-glass exclusions documented?

5. **Suggest least-privilege alternatives.** Map broad built-in roles to scoped equivalents:
   - `Contributor` → `Storage Blob Data Contributor`, `Key Vault Secrets User`, `AcrPush`, etc.
   - `Owner` → split into `Contributor` + `Role Based Access Control Administrator` (scoped).

6. **Report:**
   ```markdown
   ## Azure RBAC Review — <scope>

   **Verdict:** safe | needs-changes | high-risk

   ### High-risk findings
   - `Owner` granted to `<user>@…` at subscription `prod-shared`. Move to PIM-eligible, time-bound.

   ### Suggested replacements
   | Current | Recommended | Scope |
   |---|---|---|
   | Contributor | Storage Blob Data Contributor | RG `data-prod` |
   | Owner | RBAC Administrator + Contributor | Subscription `prod-shared`, PIM eligible |

   ### Recommendations
   - [ ] Move all Owner / User Access Admin to PIM with approval.
   - [ ] Add an Access Review every 90 days for subscription-scope roles.
   - [ ] Remove classic administrators.
   ```

## Guardrails

- **Never run** `az role assignment create|delete` or `az role definition create|update|delete` — review only.
- If a role is used by automation (SPN / managed identity), check what pipelines depend on it before recommending change.
- Report Azure AD (Entra ID) directory roles separately from Azure resource RBAC — they have different blast radii.
- Flag, don't auto-remove, anything that looks like a break-glass account.
