---
name: dast-baseline-scan
description: Use when running an authorized non-intrusive DAST baseline scan (OWASP ZAP baseline, nuclei, nikto) against a web app or API endpoint you own, or "/dast". Requires explicit authorization; refuses unowned targets.
tools: [cursor, claude, copilot]
---

# dast-baseline-scan

## When to use

- "scan our staging API for vulns"
- "run a baseline DAST against this endpoint"
- Pre-release web-app security check.
- "/dast"

## **Authorization gate — read first**

Before running ANYTHING:

1. Confirm the target host. Resolve it. Note the IP.
2. Match against the table:

   | Target | Action |
   |---|---|
   | `localhost`, `127.0.0.1`, `*.localhost`, RFC1918 docker network | Proceed. |
   | Staging / preprod owned by user | Require: "I own and authorize scanning of `<host>`." |
   | **Production** | Require written authorization with: system, time window, source IP, rollback contact. Capture in report. |
   | Anything else (third-party SaaS, partner API, random URL) | **Refuse.** Tell user this is unauthorized scanning and likely illegal. |

3. **Never scan a target whose ownership you cannot verify.** When in doubt, refuse.

## Preconditions

- Authorized target URL (see gate above).
- `docker` available (recommended way to run ZAP).
- For authenticated scans: a low-privilege test account credential, NEVER a real user's cred.
- Maintenance window confirmed if scanning staging/prod.

## Procedure

1. **Recon (passive, gentle):**
   ```
   curl -sI https://<target>
   ```
   Note: server header, security headers (HSTS, CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy).

2. **ZAP baseline scan** (passive, ~2–5 min, no active attacks):
   ```
   docker run --rm -t ghcr.io/zaproxy/zaproxy zap-baseline.py \
     -t https://<target> \
     -r zap-report.html \
     -J zap-report.json
   ```
   For an API with an OpenAPI spec:
   ```
   docker run --rm -t ghcr.io/zaproxy/zaproxy zap-api-scan.py \
     -t https://<target>/openapi.json -f openapi
   ```

3. **Nuclei templated checks** (CVE-style, low-impact):
   ```
   nuclei -u https://<target> -severity critical,high,medium -rl 50
   ```
   `-rl 50` rate-limits to 50 req/sec. Lower for fragile targets.

4. **Headers / TLS quick checks:**
   - `testssl.sh https://<target>` — TLS config.
   - Manual: cookies have `Secure`, `HttpOnly`, `SameSite`?

5. **Rank findings:**
   - **CRITICAL:** auth bypass, SQLi confirmed, RCE, exposed admin panel, exposed `.env` / `.git/`.
   - **HIGH:** missing auth on sensitive endpoint, reflected XSS confirmed, SSRF, IDOR, weak TLS (< 1.2, RC4), known-exploited CVE on a fingerprinted product.
   - **MEDIUM:** missing security headers, verbose errors leaking stack traces, mixed content, cookies without Secure/HttpOnly.
   - **LOW / INFO:** server version disclosure, missing `robots.txt`.

## Output

```markdown
## DAST baseline — <target>

**Authorization:** localhost | staging owner-asserted | prod ref:<ticket> + window <start–end>
**Tools:** zap-baseline 2.14, nuclei <ver>, testssl.sh 3.x
**Source IP:** <ip>
**Date / window:** <YYYY-MM-DD HH:MM–HH:MM TZ>

### Summary
- Critical: N, High: N, Medium: N, Low: N
- Requests sent: ~<N>, errors observed in target logs: <N>

### Findings

#### [CRITICAL] Exposed `.git/` directory
- **URL:** `https://<target>/.git/config`
- **Evidence:** `HTTP 200, Content-Type: text/plain` returning git config.
- **Why:** full source tree (and history, including secrets) downloadable.
- **Fix:** block `/.git/` in nginx/CDN; remove from deployed artifact; rotate any secrets in history.
- **References:** CWE-538.

#### [HIGH] Reflected XSS in `q` param of `/search`
- **Request:** `GET /search?q=<svg/onload=alert(1)>`
- **Response:** parameter echoed unescaped in `<h1>` tag.
- **Fix:** server-side HTML escape; CSP `script-src 'self'`.
- **References:** CWE-79, OWASP A03:2021.

#### [MEDIUM] Missing security headers
- HSTS, CSP, X-Content-Type-Options absent.
- **Fix:** add at edge (nginx / CDN). Suggested values: <…>

### TLS
- Protocols: TLS 1.2, TLS 1.3 ✓; SSLv3 / TLS 1.0 / 1.1 absent ✓
- Cipher suites: <ok / weak>
- HSTS: missing — add `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload`.

### Out of scope / not tested
- Authenticated flows behind <login> — needs test account.
- Business-logic flaws — DAST does not catch these; pair with code review.

### Follow-ups
- [ ] Re-scan after fixes.
- [ ] Add ZAP baseline to CI against ephemeral env.
```

## Guardrails

- **NEVER** run this against a target you don't own or have written authorization for.
- Use `zap-baseline` (passive), not `zap-full-scan` (active attacks), unless explicitly authorized for active fuzzing.
- Cap rate (`nuclei -rl`, ZAP delay) — don't DoS your own service.
- Stop immediately if the target shows distress (5xx spike, increased latency).
- Strip auth tokens / cookies / PII from any captured request/response in the report.
- Findings reports go to **private** channels only.
- If the scan reveals **active compromise** (web shell, unknown admin), stop and trigger incident response — do not poke further.
