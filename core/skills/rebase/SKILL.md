---
name: rebase
description: Use when the user says /rebase, "rebase onto dev", "rebase onto main", "sync with main", or "update my branch from dev". Rebases the current branch onto a target branch, fetching latest, and handles conflicts by reporting them clearly.
---

# rebase

## When to use

Trigger phrases:

- "/rebase"
- "rebase onto dev" / "rebase onto main"
- "sync with main" / "update my branch from dev"

## Procedure

1. **Identify target branch** from the user's prompt; default to `dev` if it exists on origin, else `main`.
2. **Guard against dirty tree.** Run `git status --short`. If there are uncommitted changes, ask the user whether to stash or commit first.
3. **Fetch.** `git fetch origin --prune`.
4. **Rebase.** `git rebase origin/<target>`.
5. **On conflict:**
   - Run `git status` and list the conflicted files.
   - Summarize each conflict briefly (which hunks clash) without auto-resolving unless the resolution is trivial and unambiguous.
   - Stop and hand control back to the user with next-step commands (`git rebase --continue`, `git rebase --abort`).
6. **On success:**
   - Run `git log --oneline origin/<target>..HEAD` to show the rebased commits.
   - Remind the user they may need `git push --force-with-lease` if the branch was previously pushed.

## Guardrails

- Never run `git push --force` (prefer `--force-with-lease`, and only when the user asks).
- Never `git reset --hard` without explicit consent.
- Do not rebase `main` or `dev` themselves.
