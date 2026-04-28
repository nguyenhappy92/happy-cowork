---
name: secret-scan
description: Use when scanning a repo or filesystem for committed secrets (API keys, tokens, private keys, passwords) with gitleaks or trufflehog, or "/secret-scan". Flags exposed credentials with file:line and remediation steps including key rotation.
tools: [cursor, claude, copilot]
---

# secret-scan

## When to use

- "scan for secrets"
- "did we leak any keys?"
- Pre-release / pre-open-source audit.
- After suspecting a leak.
- "/secret-scan"

## Preconditions

- A git repo (preferred — full history scan) or a filesystem path.
- `gitleaks` (>= 8.x) or `trufflehog` (>= 3.x) installed. If neither, fall back to `git grep` heuristics for the obvious patterns.
- User confirmation if the repo is private and findings will be shared.

## Procedure

1. **Pick the tool:**
   - `gitleaks detect --source . --no-banner --redact -v` — fast, low FP, scans full history by default.
   - `trufflehog git file://. --only-verified` — slower, but verifies live credentials against provider APIs.
   - For a non-git path: `gitleaks detect --source <path> --no-git`.

2. **Run the scan.** Capture stdout and exit code. Non-zero = findings.

3. **Triage each hit:**
   - **Verified live** (trufflehog confirms it works) → **CRITICAL**, rotate immediately.
   - **High-confidence pattern** (AWS access key, GitHub PAT, Stripe key, JWT signing secret, private key) → **HIGH**, rotate.
   - **Medium-confidence** (generic high-entropy string in a config file) → **MEDIUM**, manually verify.
   - **Test fixture / dummy** (matches `EXAMPLE`, `dummy`, `XXXXX`, repo-known fixture) → **INFO**, suppress with `.gitleaksignore`.

4. **Check the blast radius.** For each real secret:
   - When was it committed? (`git log -p -S '<fragment>'`)
   - Is the commit public? (Pushed to a public remote or fork.)
   - What does the credential grant? (Console-only? Programmatic? Scope?)

5. **Remediate (in this order — order matters):**
   1. **Rotate the secret at the provider.** Old value must be dead before any cleanup.
   2. **Remove from current code.** Replace with env var / secret manager reference.
   3. **Purge from history** if the repo is public (`git filter-repo` or BFG). For private repos, rotation alone is usually enough.
   4. **Add detection** to CI: `gitleaks-action` or pre-commit hook.

## Output

```markdown
## Secret scan — <repo>

**Tool:** gitleaks 8.x | trufflehog 3.x
**Scope:** full git history | working tree only
**Findings:** N (Critical: X, High: Y, Medium: Z)

### Findings

#### [CRITICAL] AWS access key in `config/prod.env:14`
- **Commit:** `abc1234` (2025-11-03, public on origin/main)
- **Verified live:** yes (trufflehog)
- **Grants:** programmatic access, role `prod-deploy` (admin on `s3:*`)
- **Fix:**
  1. Rotate in IAM console NOW.
  2. Replace with `${AWS_ACCESS_KEY_ID}` from secrets manager.
  3. `git filter-repo --path config/prod.env --invert-paths` and force-push (coordinate with team).
  4. Audit CloudTrail for misuse during exposure window.

#### [HIGH] …

### Suppressions added
- `.gitleaksignore` entries for: <fixture paths>

### CI hardening
- [ ] Add gitleaks pre-commit hook
- [ ] Add gitleaks GitHub Action on PRs
```

## Guardrails

- **Never paste raw secret values into the report or chat.** Redact: `AKIA****WXYZ`, last 4 chars only.
- Treat every finding as live until proven dummy. Rotation cost is cheap; assumption cost is a breach.
- If a secret grants prod write access, **stop and tell the user to rotate before doing anything else.**
- Don't push history rewrites without explicit approval — it breaks every clone.
