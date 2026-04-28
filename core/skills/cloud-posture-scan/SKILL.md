---
name: cloud-posture-scan
description: Use when running a cloud security posture scan (CSPM) on AWS, Azure, or GCP using prowler, scout-suite, or checkov, or "/cloud-scan". Requires read-only credentials; produces CIS-benchmark-aligned findings with remediation.
tools: [cursor, claude, copilot]
---

# cloud-posture-scan

## When to use

- "audit our AWS account"
- "are we CIS-compliant?"
- Quarterly cloud security review.
- Post-incident "what else is exposed?"
- "/cloud-scan"

## **Authorization gate**

- Use **read-only** credentials scoped to the target account/subscription/project.
- Confirm the account ID / subscription ID / project ID aloud before running. Wrong tenant = wasted scan or worse.
- Refuse if the user cannot confirm ownership.

## Preconditions

- Cloud CLI configured (`aws`, `az`, `gcloud`) with read-only creds.
- One of:
  - **AWS:** `prowler` (recommended), `scout-suite`, `cloudsplaining`.
  - **Azure:** `prowler` (now multi-cloud) or `scout-suite`.
  - **GCP:** `prowler` or `scout-suite`.
  - **IaC (preventive):** `checkov`, `tfsec`, `kics` against your Terraform/Bicep/CFN.

## Procedure

1. **Confirm scope:**
   ```
   aws sts get-caller-identity
   az account show --query '{name:name, id:id}'
   gcloud config get-value project
   ```

2. **Run the scanner** (read-only, may take 5–30 min):

   **AWS — Prowler v4:**
   ```
   prowler aws --severity critical high --output-formats json-ocsf html
   ```
   Optional: `--compliance cis_2.0_aws`, `--checks-folder` for custom.

   **Azure — Prowler:**
   ```
   prowler azure --az-cli-auth --severity critical high
   ```

   **GCP — Prowler:**
   ```
   prowler gcp --severity critical high
   ```

   **IaC pre-deploy:**
   ```
   checkov -d . --framework terraform --quiet --compact
   tfsec . --minimum-severity HIGH
   ```

3. **Triage by exploitability, not just severity:**

   | Finding | Treat as |
   |---|---|
   | Public S3/Blob/GCS bucket with read access + sensitive data | CRITICAL |
   | RDS / SQL DB publicly accessible (0.0.0.0/0 SG) | CRITICAL |
   | IAM user with `*:*` and active access keys, no MFA | CRITICAL |
   | Root account access keys exist | CRITICAL |
   | Security group `0.0.0.0/0` on 22 / 3389 / 1433 / 3306 / 5432 | HIGH |
   | KMS key without rotation; unencrypted EBS/disk on prod | HIGH |
   | CloudTrail / Activity Log / Audit Log disabled or single-region | HIGH |
   | Public AMI / image / snapshot | HIGH |
   | MFA not enforced for IAM users / Entra users | HIGH |
   | Missing tags / drift / unused resources | LOW (cost, not security) |

4. **Cross-link with IAM review** — for any over-privileged principal flagged, trigger `aws-iam-policy-review` / `azure-rbac-review` / `gcp-iam-review` to deep-dive.

5. **Cross-link with network review** — for any 0.0.0.0/0 finding, trigger `cloud-network-review`.

## Output

```markdown
## Cloud posture scan — <provider> <account/sub/project>

**Account:** <id> (<name>)
**Tool:** prowler 4.x | checkov 3.x
**Compliance frame:** CIS AWS 2.0 | CIS Azure 2.0 | CIS GCP 2.0
**Date:** <YYYY-MM-DD>
**Findings:** Critical: N, High: N, Medium: N

### Critical (24h SLA)

#### [CRITICAL] S3 bucket `prod-customer-exports` publicly readable
- **Resource:** `arn:aws:s3:::prod-customer-exports`
- **Why:** ACL grants `AllUsers READ`; bucket contains CSV exports of customer records.
- **Fix:**
  ```
  aws s3api put-public-access-block --bucket prod-customer-exports \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
  aws s3api put-bucket-acl --bucket prod-customer-exports --acl private
  ```
- **Detection going forward:** enable `s3-bucket-public-read-prohibited` AWS Config rule.
- **References:** CIS AWS 2.1.5, CWE-732.

#### [CRITICAL] IAM user `legacy-deploy` has `*:*` policy + 2 active access keys + no MFA
- **Fix:** rotate keys, scope to needed actions, enable MFA, OR migrate to IAM Roles + STS.

### High …

### Medium …

### Compliance summary
- CIS AWS 2.0: 47 / 60 passed (78%)
- Top failing controls: 1.4 (root keys), 2.1.5 (S3 public), 4.1 (CloudTrail multi-region).

### Recommended next steps
- [ ] Enable AWS Security Hub + Config aggregator (continuous posture).
- [ ] Add `checkov` to Terraform CI to prevent regressions.
- [ ] Schedule monthly prowler run with diff vs last report.
```

## Guardrails

- **Read-only creds only.** Never use admin keys for a scan; principle of least privilege applies to the auditor too.
- Some prowler checks call hundreds of APIs. Watch for throttling and cost (CloudWatch Logs Insights, etc.).
- For AWS Organizations / Azure Management Groups: scan one account/sub at a time; aggregating across the org needs delegated admin and explicit approval.
- Don't include account IDs or resource ARNs of OTHER customers if you find shared/cross-account resources — redact and flag for separate handling.
- Tag a finding as "accepted risk" only with: justification, owner, expiry date.
