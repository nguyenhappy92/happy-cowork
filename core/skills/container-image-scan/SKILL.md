---
name: container-image-scan
description: Use when scanning a container image or Dockerfile for vulnerabilities, misconfigurations, and best-practice violations using trivy, dockle, or hadolint, or "/image-scan". Flags base-image CVEs, root user, missing healthchecks, and bloat.
tools: [cursor, claude, copilot]
---

# container-image-scan

## When to use

- "scan this image"
- "is this Dockerfile safe / lean?"
- Pre-push to registry, pre-deploy.
- "/image-scan"

## Preconditions

- A built image (`<repo>:<tag>` or local `docker images` ref) **or** a Dockerfile path.
- `trivy`, `dockle`, `hadolint`, or `grype` available. Docker daemon optional (trivy can pull).

## Procedure

1. **Lint the Dockerfile** (if available):
   ```
   hadolint Dockerfile
   ```
   Common hits:
   - `DL3008` — pin `apt` versions.
   - `DL3007` — don't use `:latest`.
   - `DL3018` — pin `apk` versions.
   - `DL4006` — use `SHELL ["/bin/bash", "-o", "pipefail", "-c"]` for piped commands.

2. **Scan the built image for CVEs:**
   ```
   trivy image --severity HIGH,CRITICAL --ignore-unfixed <image>
   ```
   - `--ignore-unfixed` cuts noise on stuff you can't act on.
   - Add `--scanners vuln,secret,config` for full sweep.

3. **Audit image best practices:**
   ```
   dockle <image>
   ```
   Watches for: running as root, sensitive files, unnecessary shells, COPY of secrets.

4. **Check image hygiene:**
   - **Base image:** distroless / chainguard / alpine / -slim variant? Pinned by SHA?
   - **User:** non-root (`USER 1000`)?
   - **Layers:** combined `RUN` to reduce size? `.dockerignore` present?
   - **Secrets:** any `ENV TOKEN=` / `ARG TOKEN=` (build args bake in)?
   - **HEALTHCHECK** present?
   - **Multi-stage** build to drop build deps?

5. **Rank findings:**
   - **CRITICAL:** running as root + network-facing; secret in image; KEV CVE in base.
   - **HIGH:** fixable CRITICAL/HIGH CVE in runtime libs; `:latest` in prod manifest.
   - **MEDIUM:** outdated base, missing `USER`, no `HEALTHCHECK`.
   - **LOW:** image size > 500MB without reason; missing `.dockerignore`.

## Output

```markdown
## Container image scan — <image:tag>

**Tools:** trivy 0.50, dockle 0.4, hadolint 2.x
**Base:** node:20.11-alpine3.19 (digest sha256:abcd…)
**Size:** 187 MB, 12 layers
**Findings:** Critical: N, High: N, Medium: N

### Critical / High

#### [CRITICAL] CVE-2024-XXXX in `openssl 3.0.10` (base layer)
- **Fixed in:** 3.0.13 — bump base to `node:20.11-alpine3.19.1`.

#### [CRITICAL] Running as root
- **Where:** Dockerfile final stage has no `USER` directive.
- **Fix:**
  ```dockerfile
  RUN adduser -D -u 1000 app
  USER app
  ```

#### [HIGH] AWS key baked into image as ENV
- **Where:** `ENV AWS_SECRET_ACCESS_KEY=…` in layer 7.
- **Fix:** rotate the key, switch to runtime injection (k8s Secret / IRSA / Workload Identity).

### Dockerfile hygiene
- [ ] DL3007: replace `FROM node:latest` with pinned digest.
- [ ] DL3008: pin apk packages.
- [ ] Add `HEALTHCHECK CMD wget -q --spider http://localhost:8080/healthz || exit 1`.
- [ ] Add `.dockerignore` (currently 40MB of `node_modules` + `.git` shipped).

### Suggested rebuild
```dockerfile
FROM node:20.11-alpine3.19@sha256:… AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM gcr.io/distroless/nodejs20-debian12@sha256:…
WORKDIR /app
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
USER nonroot
EXPOSE 8080
HEALTHCHECK CMD ["/nodejs/bin/node", "-e", "fetch('http://localhost:8080/healthz').then(r=>process.exit(r.ok?0:1))"]
CMD ["dist/server.js"]
```
```

## Guardrails

- Never store the image in a public registry without a re-scan. CVEs accumulate over time even when nothing changes.
- `--ignore-unfixed` is a triage tool, not a scoring tool — don't tell the user the image is "clean" while ignoring 200 unfixed CVEs.
- If the image embeds a secret, treat it like a secret-scan finding: **rotate first**, then rebuild.
