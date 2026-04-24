# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

`happy-cowork` is a tool-neutral hub of AI coding skills, rules, hooks, and MCP configs. Content lives once in `core/` and adapters project it into each AI tool's native layout via symlinks.

## CLI

The main entry point is `bin/cowork` (plain bash, no runtime dependencies):

```bash
bin/cowork install                        # auto-detect installed tools
bin/cowork install --tool=cursor,claude   # specific tools
bin/cowork install --only=skills,rules    # specific categories
bin/cowork install --dry-run              # preview without changes
bin/cowork uninstall --tool=cursor
bin/cowork list tools | skills | rules | mcp
bin/cowork doctor [--tool=<name>]
```

Categories: `skills`, `rules`, `hooks`, `mcp`, `agents`.

Helper scripts:

```bash
scripts/new-branch.sh <slug> [base]       # creates feat/<slug> from origin/<base>
scripts/cleanup-branches.sh
```

## Architecture

```
core/           Tool-neutral source of truth
  skills/<name>/SKILL.md     One folder per skill
  rules/*.md                 Persistent coding/commit rules
  hooks/hooks.json           Hook event config
  hooks/scripts/             Hook shell scripts
  agents/*.md                Subagent persona definitions
  mcp/servers.json           MCP server registry

adapters/<tool>/adapter.sh   One adapter per AI tool
bin/cowork                   CLI — discovers and delegates to adapters
bin/lib/                     Shared bash helpers (log, link, frontmatter)
```

### How installs work

The CLI sources each adapter and calls `adapter_<tool>::install <categories>`. Adapters create **symlinks** from the tool's config dir back into `core/`, so edits in `core/` are instantly live without reinstalling.

Exception: MCP is **copied** as `mcp.template.json` (never symlinked) because users hand-edit their tool's `mcp.json` with secrets.

### Adapter interface

Each `adapters/<name>/adapter.sh` must implement these functions under the `adapter_<name>::` namespace:

- `name` — echo the tool slug
- `target` — echo the tool's config directory (e.g. `~/.cursor`)
- `detect` — exit 0 if the tool is installed
- `install <categories>` — create symlinks / drop files
- `uninstall` — remove symlinks owned by this repo
- `doctor` — report link health

The CLI auto-discovers adapters by scanning `adapters/*/adapter.sh`.

Env overrides: `CURSOR_HOME` (default `~/.cursor`), `CLAUDE_HOME` (default `~/.claude`).

### Skill format

Every skill is `core/skills/<name>/SKILL.md` with required frontmatter:

```markdown
---
name: my-thing
description: Use when … (agent uses this as a trigger phrase)
tools: [cursor, claude]   # optional; omit to target all tools
---
```

### Shared bash libs

- `bin/lib/log.sh` — `cowork::log`, `cowork::warn`, `cowork::info`, `cowork::dim`, `cowork::die`
- `bin/lib/link.sh` — `cowork::link`, `cowork::link_children`, `cowork::unlink_if_ours`
- `bin/lib/frontmatter.sh` — `cowork::frontmatter_field`, `cowork::frontmatter_list`, `cowork::targets_tool`

## Coding conventions

From `core/rules/`:

- Clarity over cleverness; early returns over nested ifs; no dead code.
- Commits: imperative mood, lowercase, <=50 chars, no trailing period, conventional-commit prefixes (`feat:`, `fix:`, `docs:`, `refactor:`, `chore:`).
- Branch names: `feat/<slug>`.
- Never commit `.env` or secrets.

## Claude Code project settings

`.claude/settings.json` disables git/PR attribution for this repo: `includeCoAuthoredBy: false`, `gitAttribution: false`, and empty `attribution.commit` / `attribution.pr` (the `attribution` object takes precedence over the deprecated `includeCoAuthoredBy` flag). For personal overrides, use `~/.claude/settings.json` or `.claude/settings.local.json` (gitignored by Claude Code when created).

## Skills inventory

General workflow (all tools):
`create-pr`, `rebase`, `review-pr`, `daily-standup`, `triage-issues`, `release-notes`

Platform engineering:
`review-terraform-plan`, `triage-incident`, `draft-runbook`, `deploy-checklist`, `cost-impact-summary`, `k8s-health-check`

Agent personas (`core/agents/`):
`reviewer`, `planner`, `explorer`, `sre`, `platform-analyst`

## Current status

- Cursor adapter: fully implemented.
- Claude Code adapter (`adapters/claude/adapter.sh`): stub — `install`/`uninstall` are not yet implemented. The planned work is to symlink `core/skills` → `~/.claude/skills`, render `core/rules/*` into `~/.claude/CLAUDE.md`, and render `core/agents/*` into `~/.claude/agents/`.

## Prerequisites

- bash 4+, git 2.30+
- `gh` CLI authenticated (`gh auth login`) — required for PR skills
- Optional: `jq`, `direnv`
