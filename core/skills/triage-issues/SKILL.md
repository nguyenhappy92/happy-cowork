---
name: triage-issues
description: Use when the user says "triage issues", "/triage", or "what should I work on next". Pulls open GitHub issues assigned to or authored by the user and groups them by priority, staleness, and required action.
---

# triage-issues

## When to use

- "triage issues" / "/triage"
- "what should I work on next?"
- "clean up my issue backlog"

## Procedure

1. **Pull candidates** (repo-scoped unless user asks org-wide):
   ```bash
   gh issue list --assignee @me --state open --limit 100 \
     --json number,title,labels,updatedAt,url,repository
   ```
2. **Enrich** with last comment time if needed: `gh issue view <n> --json comments`.
3. **Bucket** into:
   - **Act today** — labeled `p0`/`bug`/`urgent`, or assigned and updated in last 24h.
   - **This week** — labeled `p1`, or touched in last 7 days.
   - **Stale** — no update in 30+ days. Suggest closing or re-labeling.
   - **Needs info** — last comment is from someone else asking a question.
4. **Produce output:**

   ```markdown
   ### Act today
   - #123 <title> (<repo>) — <one-line why>

   ### This week
   - ...

   ### Stale (>30d, consider closing)
   - ...

   ### Waiting on you (needs reply)
   - ...
   ```

5. Offer to open the top one in the browser with `gh issue view <n> --web`.

## Guardrails

- Do not close, label, or comment on issues without explicit user approval.
- Limit default scope to 100 issues to keep output tractable.
