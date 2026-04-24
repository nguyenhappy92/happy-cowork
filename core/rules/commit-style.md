---
description: Commit message conventions.
alwaysApply: true
---

# Commit style

- **Subject**: imperative mood, lowercase, <= 50 chars, no trailing period.
  - Good: `add daily-standup skill`
  - Bad: `Added a new skill for daily standup.`
- **Body** (optional): wrap at 72 chars, explain *why* and any trade-offs. Separate from subject with a blank line.
- Prefer conventional-commit prefixes when they fit: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`, `test:`, `perf:`.
- Reference issues with `Refs #123` or `Closes #123` in the body, never the subject.
- One logical change per commit. If you're tempted to say "and", split.
- Never commit secrets, generated files, or `.env`.
