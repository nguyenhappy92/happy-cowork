---
name: review-terraform-plan
description: Use when asked to review a Terraform plan, check blast radius, assess infra change risk, or uses /review-plan. Reads a terraform plan output and flags destructive changes, resource replacements, and policy concerns.
---

# review-terraform-plan

## When to use

- "review this terraform plan" / "/review-plan"
- "check blast radius"
- "is this plan safe to apply?"
- "what does this plan change?"

## Preconditions

- A `terraform plan` output is available (piped, pasted, or in a file).
- Optionally: `terraform show -json <planfile>` for structured output.

## Procedure

1. **Parse the plan.** Look for the change summary line:
   ```
   Plan: X to add, Y to change, Z to destroy.
   ```
   If structured JSON is available, read `resource_changes[*].change.actions`.

2. **Categorize every resource change:**
   | Symbol | Action | Risk |
   |--------|--------|------|
   | `+` | create | low |
   | `~` | update in-place | medium |
   | `-/+` | replace (destroy then create) | HIGH |
   | `-` | destroy | HIGH |
   | `<=` | data read | none |

3. **Flag high-risk changes.** For each `-/+` or `-`:
   - Resource type and name.
   - Whether it holds state (databases, S3 buckets, IAM roles, security groups, load balancers).
   - Whether replacement is avoidable (e.g. `create_before_destroy` lifecycle missing).

4. **Check for common blast-radius patterns:**
   - VPC, subnet, or security group deletions (network disruption).
   - IAM role/policy replacements (auth breakage).
   - RDS, ElastiCache, or stateful workload replacements (data risk).
   - Auto-scaling group or launch template replacements (rolling restart).
   - DNS record changes (propagation delay).

5. **Report output:**
   ```markdown
   ## Terraform Plan Review

   **Summary:** X add / Y change / Z destroy

   ### High-risk changes
   - `aws_db_instance.main` — REPLACE — stateful resource, data risk if not snapshotted
   - ...

   ### Medium-risk changes
   - `aws_security_group.app` — UPDATE — verify ingress rules

   ### Safe changes
   - `aws_s3_bucket_policy.logs` — CREATE

   ### Recommendations
   - [ ] Snapshot `aws_db_instance.main` before apply
   - [ ] Confirm replacement is intentional or add `create_before_destroy`
   - [ ] Apply during low-traffic window
   ```

## Guardrails

- Never run `terraform apply` — analysis only.
- If no plan output is provided, ask for it before proceeding.
- If the plan includes >20 resource changes, summarize by resource type rather than listing every resource individually.
