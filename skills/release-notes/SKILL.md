---
name: release-notes
description: Use when the user says "draft release notes", "/release-notes", or "changelog for v<x>". Generates release notes from a git range by grouping commits/PRs into Features, Fixes, and Chores.
---

# release-notes

## When to use

- "draft release notes for v1.4.0"
- "/release-notes"
- "changelog since <tag>"

## Inputs

- **From ref** — last tag (default: `git describe --tags --abbrev=0`).
- **To ref** — defaults to `HEAD`.
- **Version name** — the target version, for the header.

## Procedure

1. **Resolve range:** `FROM..TO`.
2. **Collect commits:**
   ```bash
   git log FROM..TO --no-merges --pretty=format:'%H%x09%s%x09%an'
   ```
3. **Map commits to PRs** using `gh pr list --search "<sha>" --state merged --json number,title,labels,author`.
4. **Classify** by conventional-commit prefix or PR labels:
   - `feat:` or label `feature` → **Features**
   - `fix:` or label `bug` → **Fixes**
   - `perf:` → **Performance**
   - `docs:`, `chore:`, `refactor:`, `test:` → **Chores**
   - anything breaking (`!` or `BREAKING CHANGE:`) → **Breaking changes** (top of list).
5. **Render:**

   ```markdown
   ## v<VERSION> — <YYYY-MM-DD>

   ### Breaking changes
   - <title> (#<pr>) — @<author>

   ### Features
   - ...

   ### Fixes
   - ...

   ### Performance
   - ...

   ### Chores
   - ...

   **Full changelog:** <FROM>...<TO>
   ```

6. Offer to write to `CHANGELOG.md` or create a GitHub Release with `gh release create`.

## Guardrails

- Skip merge commits and commits whose subject is just `wip` / `fixup!`.
- Preserve author attribution where available.
- Ask before pushing a tag or creating a GitHub Release.
