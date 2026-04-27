---
name: cloud-network-review
description: Use when reviewing cloud network design across AWS VPC, Azure VNet, or GCP VPC — security groups, NSGs, firewall rules, peering, private endpoints — or "/network-review". Flags over-broad ingress, missing egress controls, and cross-cloud connectivity risks.
tools: [cursor, claude, copilot]
---

# cloud-network-review

## When to use

- "review this VPC / VNet / subnet design"
- "check security groups / NSGs / firewall rules"
- "is this network exposed to the internet?"
- "/network-review"

## Inputs

- Terraform / Bicep / CloudFormation / `gcloud` describing the network, OR
- Live state via `aws ec2 describe-…`, `az network …`, `gcloud compute networks …`.
- Optional: which cloud(s), workload sensitivity, compliance requirements (PCI, HIPAA, …).

## Procedure

1. **Map the topology.** Capture VPC/VNet CIDRs, subnets (public/private), route tables, gateways (IGW/NAT/VGW, NAT/Bastion, Cloud NAT/Cloud Router), peering, transit gateway / vWAN / Network Connectivity Center, VPN/ExpressRoute/Interconnect, private endpoints.

2. **Audit ingress** (per-cloud equivalents):

   | Cloud | Construct | Red flags |
   |---|---|---|
   | AWS | Security Group, NACL | `0.0.0.0/0` on 22/3389/3306/5432; `-1` (all protocols) from anywhere |
   | Azure | NSG, Application Security Group | `Internet` source on management ports; `*` source/dest with `Allow` |
   | GCP | VPC firewall rule | `0.0.0.0/0` source on SSH/RDP; `--allow=all`; tag-based rules with broad tags |

3. **Audit egress.** Egress-by-default is common — flag when unrestricted egress is unnecessary (PCI / regulated). Recommend egress allow-lists via NAT + firewall rules, Azure Firewall, or Cloud NAT + VPC firewall egress rules.

4. **Audit private connectivity:**
   - Are managed services reached via PrivateLink / Private Endpoint / Private Service Connect, or over the public internet?
   - DNS: split-horizon configured? Private DNS zones linked to the right VNets/VPCs?
   - For cross-VPC/VNet: peering vs transit. Avoid full-mesh peering at scale.

5. **Audit data exfiltration controls:**
   - VPC endpoints / endpoint policies for S3, KMS, STS (AWS).
   - Service Endpoints / Private Endpoints + storage firewall (Azure).
   - VPC Service Controls perimeter (GCP).

6. **Audit logging:**
   - VPC Flow Logs / NSG Flow Logs / VPC Flow Logs enabled with reasonable sampling and a sink.
   - Firewall logs (Azure Firewall, GCP firewall logging) enabled on `Deny` at minimum.

7. **Audit DDoS / WAF posture** for any public ingress: AWS Shield + WAF, Azure DDoS Protection + Front Door/App Gateway WAF, Cloud Armor.

8. **Report:**
   ```markdown
   ## Cloud Network Review — <env / account / project>

   **Cloud(s):** AWS | Azure | GCP
   **Verdict:** safe | needs-changes | high-risk

   ### Topology summary
   - 1 VPC / 6 subnets (3 public, 3 private), NAT GW in az-a only (single point of failure).

   ### High-risk findings
   - SG `sg-…` allows `0.0.0.0/0` on tcp/22 — restrict to bastion CIDR.
   - NSG `nsg-app` has `*` source `Allow` on 1433.

   ### Medium-risk findings
   - No VPC endpoints for S3 / KMS — traffic egresses NAT GW (cost + exfil risk).
   - VPC Flow Logs disabled on `vpc-prod`.

   ### Recommendations
   - [ ] Add a second NAT GW in az-b for HA.
   - [ ] Replace `0.0.0.0/0` SSH ingress with Session Manager / Bastion / IAP.
   - [ ] Enable Flow Logs to a central log account / workspace.
   - [ ] Add VPC Service Controls perimeter around BigQuery / GCS (GCP).
   ```

## Guardrails

- **Never apply** changes (`aws ec2 authorize-security-group-ingress`, `az network nsg rule create`, `gcloud compute firewall-rules create/update/delete`) — review only.
- If a `0.0.0.0/0` ingress is intentional (public web tier), confirm there's a WAF / DDoS layer in front before downgrading the finding.
- Flag overlapping CIDRs across peered networks — they will break routing on day one of an extension.
- For multi-cloud reviews, label each finding with the cloud — don't blur AWS vs Azure terminology.
