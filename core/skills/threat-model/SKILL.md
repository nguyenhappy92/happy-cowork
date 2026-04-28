---
name: threat-model
description: Use when threat-modeling a new feature, service, or architecture using STRIDE and a basic attack tree, or "/threat-model". Produces a list of threats, mitigations, and gaps mapped to data-flow trust boundaries.
tools: [cursor, claude, copilot]
---

# threat-model

## When to use

- "threat-model this design"
- New service / architecture before code is written.
- Significant change to trust boundaries (new public endpoint, new third-party integration).
- "/threat-model"

## Preconditions

- An architecture description: diagram, ADR, design doc, or spoken-word walkthrough.
- Identified data assets (what's worth attacking).
- Known users / actors (human, service, external).

If any of these are missing, ask before continuing. Threat-modeling thin air produces fan-fiction.

## Procedure

1. **Draw the data-flow.** Even a text DFD works:
   ```
   [User browser] --HTTPS--> [API gateway] --mTLS--> [Order service] --TLS--> [Postgres]
                                                       |
                                                       +--HTTPS--> [Stripe API]
   ```
   Mark **trust boundaries** (where data crosses control domains): browser↔API, API↔internal services, app↔DB, your-cloud↔third-party.

2. **Inventory assets.** What's the attacker after?
   - Customer PII / payment data.
   - Auth tokens / API keys.
   - Service availability.
   - Reputation / ability to impersonate.

3. **Apply STRIDE per element / data flow:**

   | Letter | Threat | Property violated | Example |
   |---|---|---|---|
   | **S**poofing | identity | authentication | stolen JWT replays as user |
   | **T**ampering | integrity | integrity | client-side amount manipulation |
   | **R**epudiation | non-repudiation | audit | "I didn't make that order" without logs |
   | **I**nfo disclosure | confidentiality | confidentiality | error leaks DB schema |
   | **D**enial of service | availability | availability | unbounded query / file upload |
   | **E**levation of privilege | authorization | authorization | IDOR; role check missing |

4. **Build a small attack tree per critical asset:**
   ```
   Goal: exfiltrate customer PII
   ├── Compromise app via SQLi → mitigated (parametrized queries) ✓
   ├── Steal DB credentials
   │   ├── from env in container → READ-ONLY but in image, mitigated by IRSA ✓
   │   └── from CI secrets → MFA + OIDC federation ✓
   ├── Abuse over-privileged read API
   │   └── /admin/users returns all users; only role check on UI — GAP
   └── Backup snapshot publicly readable → covered by cloud-posture-scan
   ```

5. **For each threat, decide:**
   - **Mitigated** (control X) — note the control + where to verify.
   - **Accepted** — note who accepted, why, expiry.
   - **Open** — must be addressed before ship.

6. **Link to skills:**
   - Code-level threats → `backend-endpoint-review`.
   - IAM threats → `aws-iam-policy-review` etc.
   - Network threats → `cloud-network-review`.
   - Once shipped → `dast-baseline-scan` to verify.

## Output

```markdown
## Threat model — <feature / service>

**Scope:** <what's in / out>
**Assets:** <list>
**Actors:** <human users, services, attackers>
**Trust boundaries:** <list>

### Data-flow diagram
```
<DFD as text or mermaid>
```

### STRIDE matrix

| Element / flow | S | T | R | I | D | E |
|---|---|---|---|---|---|---|
| Browser → API | JWT theft | TLS pinning n/a | logged✓ | TLS✓ | rate-limit at edge | n/a |
| API → Order svc | mTLS✓ | mTLS✓ | per-request id✓ | mTLS✓ | timeout✓ | **role check missing** |
| Order svc → Postgres | password vault✓ | TLS✓ | DB audit on | TLS+at-rest✓ | conn pool cap | least-priv role✓ |

### Open threats (must fix before ship)

#### [HIGH] E: missing role check on `Order svc /admin/orders`
- **Mitigation:** add server-side authz middleware; deny by default.
- **Verify:** integration test for non-admin → 403.

#### [MEDIUM] D: file upload has no size cap
- **Mitigation:** 5MB cap at API gateway + service; reject > limit.

### Accepted risks
- Stripe webhook replay window 5min — accepted by <name> until <date>; mitigated by idempotency key.

### Verification plan
- [ ] `backend-endpoint-review` on /admin/orders.
- [ ] `dast-baseline-scan` against staging post-deploy.
- [ ] Add role-check unit + integration tests.
```

## Guardrails

- Don't invent threats that ignore real mitigations. "An attacker could…" needs an actual path past the controls.
- Don't skip the DFD — most missed threats are missed boundaries.
- Don't conflate **risk** (probability × impact) with **threat** (the path). Triage with risk; document with threat.
- A threat model is a living doc — note the version of the architecture it applies to.
