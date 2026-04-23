# Happy Cowork

My personal hub of Cursor skills, rules, hooks, and helper scripts that I "cowork" with every day. This repo is the single place I put reusable prompts, agent personas, and automation so any machine I touch can pick them up with one command.

## What's inside

| Folder | Purpose |
|---|---|
| `skills/` | Cursor agent skills (one folder per skill, each with a `SKILL.md`). |
| `rules/` | Persistent Cursor rules — coding conventions, commit style, per-language guidance. |
| `hooks/` | Cursor hooks (`hooks.json` + scripts) for event-driven automation. |
| `agents/` | Prompt/persona definitions for specialized subagents. |
| `mcp/` | MCP server configs (Datadog, Linear, GitLens, …). |
| `scripts/` | Plain shell helpers I invoke from the terminal. |
| `templates/` | Boilerplate: PR bodies, RFCs, issue templates. |
| `docs/` | Longer-form docs, recipes, and onboarding notes. |

## Quick start

```bash
git clone git@github.com:<you>/happy-cowork.git ~/code/happy-cowork
cd ~/code/happy-cowork
./install.sh           # symlinks skills/rules/hooks into ~/.cursor/
```

After install, open Cursor and the agent can invoke any skill in `skills/` by description.

## Adding a new skill

1. Ask Cursor: "Use the `create-skill` skill to add a new skill called `my-thing`."
2. Or manually: `mkdir skills/my-thing && $EDITOR skills/my-thing/SKILL.md`.
3. Every `SKILL.md` needs frontmatter:

```markdown
---
name: my-thing
description: One-liner that starts with "Use when …" so the agent knows when to pick it.
---
```

4. Commit and push. `install.sh` uses symlinks, so no reinstall is needed on your own machine.

## Current skills

| Skill | When to use |
|---|---|
| `create-pr` | Opening a new PR with a well-structured summary. |
| `rebase` | Rebasing the current branch onto `dev` or `main`. |
| `review-pr` | Reviewing a GitHub PR for quality, security, and conventions. |
| `daily-standup` | Summarizing yesterday's commits for standup. |
| `triage-issues` | Triaging open GitHub / Linear issues by priority. |
| `release-notes` | Drafting release notes from a git range. |

## Design principles

1. **Symlink, don't copy.** Edits in the repo take effect immediately in `~/.cursor/`.
2. **One folder per skill.** Keeps diffs and discovery clean.
3. **Descriptions matter.** The agent selects skills by their `description` frontmatter — write it like a trigger phrase.
4. **No secrets in git.** Use `.env.example` + direnv/1Password CLI for anything sensitive.
5. **Promote twice-repeated prompts into skills.** If I type the same instructions twice, it belongs here.

## Roadmap

- [ ] CI lint for `SKILL.md` frontmatter.
- [ ] `justfile` shortcuts (`just new-skill foo`).
- [ ] Canvas dashboards for recurring analyses.
- [ ] Shared MCP config for team members.

## License

MIT — see `LICENSE`.
