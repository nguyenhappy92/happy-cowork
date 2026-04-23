---
name: daily-standup
description: Use when the user says "standup", "what did I do yesterday", or "/standup". Summarizes recent git activity across repositories into a standup-ready bullet list covering yesterday, today's plan, and blockers.
---

# daily-standup

## When to use

- "standup" / "/standup"
- "what did I do yesterday?"
- "prep my standup"

## Inputs

- Optional list of repo paths. Default: the current repo only.
- Optional `--since` (default: `yesterday 00:00`).
- Optional author filter (default: `git config user.email`).

## Procedure

1. **Resolve author.** `git config user.email`.
2. **For each repo**, run:
   ```bash
   git log --since="yesterday 00:00" --until="today 00:00" \
           --author="<email>" --pretty=format:'- %s (%h)' --no-merges
   ```
3. **Collect open work in progress:**
   - `git branch --show-current`
   - `git status --short`
   - `gh pr list --author @me --state open --json number,title,url,isDraft`
4. **Format output:**

   ```markdown
   **Yesterday**
   - <commit subject> (<repo>@<sha>)

   **Today**
   - Continue <branch or PR>
   - <planned items>

   **Blockers**
   - <if any, else "none">
   ```

5. If the user has a team template, honor it.

## Guardrails

- Keep it under ~10 bullets total.
- Deduplicate commits that share a subject across cherry-picks.
- Never fabricate progress — if `git log` is empty, say so.
