---
name: create-pr
description: Use when the user asks to create a PR, open a pull request, or uses /create-pr. Opens a GitHub pull request with a well-structured summary using the gh CLI, optionally checking out a new branch from current changes and targeting dev or main based on the user's prompt.
---

# create-pr

## When to use

Trigger whenever the user says any of:

- "create a PR" / "open a pull request" / "/create-pr"
- "push this and open a PR"
- "PR this branch into dev/main"

## Preconditions

- `gh` is installed and authenticated (`gh auth status`).
- Working tree is committed OR the user has explicitly asked you to commit first.
- A remote named `origin` exists.

## Procedure

1. **Survey the branch.** In parallel:
   - `git status --short`
   - `git log --oneline @{upstream}..HEAD 2>/dev/null || git log --oneline -20`
   - `git diff --stat origin/main...HEAD 2>/dev/null || git diff --stat`
2. **Determine base branch.** Default to `dev` if it exists on origin, else `main`. Override if the user named one.
3. **Determine current branch.** If on `main`/`dev`, create a new branch: `feat/<short-slug>` derived from the change summary.
4. **Push** with `git push -u origin HEAD`.
5. **Draft a PR body** using this template:

   ```markdown
   ## Summary
   - <bullet per meaningful change>

   ## Why
   <1-2 sentences on motivation>

   ## Test plan
   - [ ] <how you verified>
   - [ ] <edge cases considered>

   ## Screenshots / logs
   <if UI or output changed>
   ```

6. **Open the PR** with `gh pr create --base <base> --title "<title>" --body "$(cat <<'EOF' ... EOF)"`.
7. **Return the PR URL** to the user.

## Guardrails

- Never force-push.
- Never push directly to `main` or `dev`.
- If there are uncommitted changes, ask before committing them.
- Skip `--no-verify`; let hooks run.
