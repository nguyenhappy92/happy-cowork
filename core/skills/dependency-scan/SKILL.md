---
name: dependency-scan
description: Use when scanning a project's third-party dependencies for known CVEs across npm, pip, Go, Maven, Cargo, etc., or "/dep-scan". Runs trivy, npm audit, pip-audit, govulncheck, or osv-scanner and produces a prioritized fix list.
tools: [cursor, claude, copilot]
---

# dependency-scan

## When to use

- "scan dependencies for vulns"
- "is this lockfile safe?"
- Pre-release CVE check.
- After a high-profile CVE drops (log4shell-style).
- "/dep-scan"

## Preconditions

- A lockfile (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `poetry.lock`, `requirements.txt`, `go.sum`, `Cargo.lock`, `pom.xml`, `gradle.lockfile`).
- One of: `trivy`, `osv-scanner`, or the language-native scanner (`npm audit`, `pip-audit`, `govulncheck`).
- Internet access for the vuln database.

## Procedure

1. **Pick the right tool.** Prefer `osv-scanner` (multi-ecosystem, OSV.dev-backed) or `trivy fs`. Fall back to native:

   | Ecosystem | Native | Generic |
   |---|---|---|
   | npm / yarn / pnpm | `npm audit --json` | `osv-scanner --lockfile=package-lock.json` |
   | Python | `pip-audit -r requirements.txt` | `trivy fs --scanners vuln .` |
   | Go | `govulncheck ./...` (call-graph aware!) | `osv-scanner --lockfile=go.mod` |
   | Java | OWASP `dependency-check` | `trivy fs .` |
   | Rust | `cargo audit` | `osv-scanner --lockfile=Cargo.lock` |
   | Multi-lang monorepo | — | `trivy fs --scanners vuln .` or `osv-scanner -r .` |

2. **Run with JSON output** so you can parse and rank.

3. **Rank by EXPLOITABILITY, not just CVSS:**
   - **CRITICAL:** in CISA KEV catalog, OR CVSS ≥ 9 with public exploit, OR `govulncheck` says the vulnerable function is reachable from your code.
   - **HIGH:** CVSS ≥ 7 in a runtime dependency in a network-facing path.
   - **MEDIUM:** CVSS ≥ 4, or runtime dep with no known exploit.
   - **LOW:** dev-only dep (`devDependencies`, `[dev-packages]`), or behind a feature flag, or CVSS < 4.
   - **INFO:** transitive in a non-reachable code path (let `govulncheck` decide for Go).

4. **For each finding, identify the fix path:**
   - Direct dep with patched version → bump.
   - Transitive dep → can the parent be bumped? Use `npm ls <pkg>` / `pip show <pkg>` / `go mod why <pkg>`.
   - No fix yet → mitigate (disable feature, WAF rule, version pin) and watch.

5. **Cross-check against project policy:**
   - License changes from the bump? Run `license-checker` / `pip-licenses`.
   - Major-version bump? Note the breaking changes.
   - Runtime requirement change (Node version, Python version)?

## Output

```markdown
## Dependency scan — <project>

**Tool:** osv-scanner 1.x | trivy 0.50 | govulncheck 1.x
**Lockfiles scanned:** package-lock.json, go.sum
**Findings:** Critical: N, High: N, Medium: N, Low: N

### Critical / High (act now)

| CVE | Package | Current → Fixed | Direct? | KEV? | Reachable? | Fix |
|---|---|---|---|---|---|---|
| CVE-2024-XXXX | lodash 4.17.20 → 4.17.21 | direct | yes | n/a | bump in `package.json` |
| CVE-2024-YYYY | golang.org/x/net 0.17 → 0.23 | indirect via grpc-go | no | yes | `go get -u golang.org/x/net@v0.23.0 && go mod tidy` |

### Medium (next sprint)
…

### No-fix (mitigate)
- CVE-2024-ZZZZ in `pkg-foo` — no patch. Mitigation: disable `--enable-foo` flag.

### Suppressions / accepted risk
- CVE-2023-AAAA: dev-only, not shipped. Tracked in `.trivyignore`.

### Follow-ups
- [ ] Add `osv-scanner` to CI (block on Critical/High in runtime deps).
- [ ] Enable Dependabot / Renovate for weekly auto-bumps.
```

## Guardrails

- **Don't auto-bump majors.** Major versions break things; flag them, let a human decide.
- Don't dismiss a CVE because "it's transitive" — log4shell was transitive.
- For Go specifically, prefer `govulncheck` — it does call-graph reachability and dramatically cuts noise.
- If the project has no lockfile, **say so** — scanning `package.json` ranges only is incomplete. Recommend committing a lockfile first.
- Never silently add a suppression — every `.trivyignore` / `.osv-scanner-ignore` line needs a comment with reason + expiry date.
