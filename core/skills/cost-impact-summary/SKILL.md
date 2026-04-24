---
name: cost-impact-summary
description: Use when asked about cost impact of a change, "what does this cost", "cost estimate", or "/cost-check". Summarizes the AWS/GCP/cloud cost implications of an infra or code change.
---

# cost-impact-summary

## When to use

- "what does this change cost?" / "/cost-check"
- "cost impact of this PR"
- "estimate the infra cost"
- "is this expensive to run?"

## Inputs

- Terraform plan output, PR diff, or a description of the infra change.
- Optionally: current AWS/GCP account, region, expected traffic/load.

## Procedure

1. **Identify billable resource changes** from the plan/diff:
   - Compute: EC2, ECS tasks, Lambda, GKE nodes
   - Storage: S3, EBS, RDS, ElastiCache
   - Network: NAT Gateway, data transfer, load balancers, CloudFront
   - Other: managed services (RDS, MSK, OpenSearch, etc.)

2. **For each changed resource, estimate:**
   - Current cost (if it's a modification).
   - New cost (size, count, or tier change).
   - Delta (+ increase / - savings).

   Use rough public pricing. Flag when a precise estimate requires Infracost or AWS Pricing Calculator.

3. **Highlight cost surprises:**
   - NAT Gateway data processing charges (often overlooked).
   - Cross-AZ or cross-region data transfer.
   - Provisioned IOPS changes.
   - Reserved/Savings Plan coverage gaps.
   - Lambda duration vs. provisioned concurrency trade-offs.

4. **Output:**
   ```markdown
   ## Cost Impact Summary

   | Resource | Change | Est. Monthly Delta |
   |---|---|---|
   | `aws_instance.app` | t3.medium → t3.large | +$29/mo |
   | `aws_nat_gateway` | new | +$32/mo + transfer |
   | `aws_rds_instance.main` | db.t3 → db.m5 | +$85/mo |

   **Estimated total delta:** +$146/mo

   ### Watch out for
   - NAT Gateway data transfer charges depend on traffic volume — estimate based on X GB/day.
   - `aws_rds_instance` upgrade requires a maintenance window.

   ### For precise numbers
   Run: `infracost breakdown --path .`
   Or: AWS Pricing Calculator for <resource>
   ```

## Guardrails

- Estimates are rough — always caveat with "verify with Infracost or AWS Cost Explorer."
- If `infracost` is available in the environment, prefer running it over manual estimation.
- Do not approve or reject a change based on cost alone — surface the data, let the user decide.
