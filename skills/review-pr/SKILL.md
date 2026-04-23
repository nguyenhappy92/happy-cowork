---
name: review-pr
description: Use when the user says /review-pr, "review this PR", or "review PR <number/url>". Reviews a GitHub Pull Request using the gh CLI, analyzing code quality, logic correctness, security, and adherence to project conventions.
---

# review-pr

## When to use

- "/review-pr"
- "review this PR"
- "review PR 123" or a GitHub PR URL

## Procedure

1. **Resolve the PR.** Parse the number/URL from the user's prompt; if absent, run `gh pr view --json number,headRefName,baseRefName`.
2. **Gather context** in parallel:
   - `gh pr view <n> --json title,body,author,files,additions,deletions,baseRefName,headRefName`
   - `gh pr diff <n>`
   - `gh pr checks <n>`
3. **Read project conventions.** Check for `AGENTS.md`, `CONTRIBUTING.md`, or `.cursor/rules/` and note any rules that apply.
4. **Review across these axes:**
   - **Correctness** — logic bugs, off-by-one, null handling, async/await misuse.
   - **Security** — injection, auth, secrets, unsafe deserialization, SSRF.
   - **Performance** — obvious N+1, unbounded loops, hot-path allocations.
   - **Style / conventions** — matches repo rules, naming, structure.
   - **Tests** — are new paths covered? Any flakiness risks?
   - **Docs** — is README / changelog / migration guide updated where needed?
5. **Produce output** in this shape:

   ```markdown
   ## Summary
   <2-3 sentence assessment>

   ## Blocking
   - [ ] <must-fix items with file:line>

   ## Suggestions
   - <nice-to-haves with file:line>

   ## Nits
   - <tiny style points>

   ## Questions
   - <clarifications for the author>
   ```

6. **Offer to post** the review with `gh pr review <n> --comment --body -` if the user wants it on the PR.

## Guardrails

- Cite `file:line` for every point.
- Never approve or request changes without explicit user direction.
- Do not modify the PR branch.
