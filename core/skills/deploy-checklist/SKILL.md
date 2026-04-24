---
name: deploy-checklist
description: Use when asked "is this safe to deploy", "pre-deploy check", "deploy checklist", or "/deploy-check". Runs a pre-deployment safety checklist: diff review, rollback plan, dependencies, and go/no-go decision.
---

# deploy-checklist

## When to use

- "is this safe to deploy?" / "/deploy-check"
- "pre-deploy checklist"
- "should I deploy this now?"
- "review before I ship"

## Inputs

- Branch name or PR number.
- Target environment (prod / staging / canary).
- Optionally: deploy window, change ticket, service name.

## Procedure

1. **Survey the change.** In parallel:
   ```bash
   git log --oneline origin/main..HEAD
   git diff --stat origin/main...HEAD
   gh pr view <PR> --json title,body,reviews,statusCheckRollup
   ```

2. **Check CI status.** All required checks must be green. If any are failing or pending, output **NO-GO** immediately with the check names.

3. **Run the checklist:**

   ```markdown
   ## Pre-deploy Checklist — <service> to <env>

   ### Change review
   - [ ] PR approved by >= 1 reviewer
   - [ ] CI all green
   - [ ] No secrets or credentials in diff
   - [ ] Migrations are backwards-compatible (if any)
   - [ ] Feature flags in place for risky changes

   ### Dependencies
   - [ ] Downstream services compatible with this change
   - [ ] No shared infra changes that affect other teams
   - [ ] External API / third-party dependencies verified

   ### Rollback plan
   - [ ] Previous version is deployable (`git log` shows last good SHA)
   - [ ] Rollback command documented: `<command>`
   - [ ] Database migrations are reversible (or blue/green deploy)

   ### Timing
   - [ ] Not deploying during peak traffic (check dashboard)
   - [ ] On-call engineer aware / available
   - [ ] Change window approved (if required)
   ```

4. **Go / No-Go decision:**
   - **GO** — all boxes checked, no blockers.
   - **GO with caveats** — minor items to watch, list them.
   - **NO-GO** — list blocking reasons explicitly.

## Guardrails

- Never trigger a deploy — checklist and recommendation only.
- If deploying to prod and CI is not green, always NO-GO regardless of other factors.
- Flag database migrations and config changes as higher risk items.
