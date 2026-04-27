---
name: aws-iam-policy-review
description: Use when reviewing an AWS IAM policy, role, or trust document, checking for over-broad permissions, privilege escalation paths, or "/iam-review-aws". Audits a policy JSON for least-privilege violations.
tools: [cursor, claude, copilot]
---

# aws-iam-policy-review

## When to use

- "review this IAM policy"
- "is this role least-privilege?"
- "/iam-review-aws"
- "check this trust policy for confused-deputy risk"

## Inputs

- A policy or trust JSON (pasted, file path, or `aws iam get-role-policy …` output).
- Optional: principal it's attached to, the AWS account context, and intended use case.

## Procedure

1. **Confirm scope.** Identify policy type:
   - Identity policy (attached to user/role/group)
   - Resource policy (S3 bucket policy, KMS key policy, SQS, …)
   - Trust policy (who can `sts:AssumeRole`)
   - SCP / permission boundary

2. **Parse every `Statement`.** For each, capture `Effect`, `Action`, `NotAction`, `Resource`, `NotResource`, `Principal`, `Condition`.

3. **Flag risky patterns:**

   | Pattern | Why it's risky |
   |---|---|
   | `Action: "*"` on `Resource: "*"` | full admin |
   | `iam:PassRole` with `Resource: "*"` | privilege escalation |
   | `iam:CreatePolicyVersion`, `iam:SetDefaultPolicyVersion`, `iam:Attach*Policy` | self-escalation |
   | `sts:AssumeRole` cross-account without `sts:ExternalId` condition | confused deputy |
   | `kms:Decrypt` / `kms:GenerateDataKey` on `Resource: "*"` | broad data access |
   | `s3:*` without bucket scope or `Condition` | data risk |
   | `NotAction` / `NotResource` in an `Allow` statement | usually unintended grant |
   | `Effect: Allow` to `Principal: "*"` (resource policy) | public access |
   | Missing `aws:SourceAccount` / `aws:SourceArn` on service principals | confused-deputy |

4. **Check conditions for guardrails:** `aws:PrincipalOrgID`, `aws:SourceVpce`, `aws:SecureTransport`, `aws:MultiFactorAuthPresent`, IP allow-lists, tag-based scoping (`aws:ResourceTag/*`).

5. **Suggest a least-privilege rewrite** as a JSON diff. Replace wildcards with the smallest action set that covers the documented use case. Add `Condition` blocks where missing.

6. **Report:**
   ```markdown
   ## AWS IAM Policy Review — <policy/role name>

   **Type:** identity | resource | trust | SCP
   **Verdict:** safe | needs-changes | high-risk

   ### High-risk findings
   - `iam:PassRole` on `*` — allows attaching any role to compute. Limit to `arn:aws:iam::<acct>:role/app-*`.

   ### Medium-risk findings
   - No `aws:SecureTransport` condition on `s3:GetObject`.

   ### Suggested rewrite
   ```diff
   - "Action": "s3:*",
   - "Resource": "*"
   + "Action": ["s3:GetObject", "s3:PutObject"],
   + "Resource": "arn:aws:s3:::my-bucket/*",
   + "Condition": { "Bool": { "aws:SecureTransport": "true" } }
   ```

   ### Recommended next steps
   - [ ] Run `aws iam simulate-principal-policy` on critical actions.
   - [ ] Enable IAM Access Analyzer for unused-access findings.
   ```

## Guardrails

- **Never run** `aws iam put-*`, `attach-*`, `create-policy-version`, or `update-assume-role-policy` — review only.
- If the policy is attached to multiple principals, list them and the blast radius before suggesting changes.
- If a wildcard action looks intentional (e.g. an admin break-glass role), call it out and ask before recommending removal.
- Don't paste the policy back verbatim into the report — link or summarize.
