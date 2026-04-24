# Happy Cowork

A tool-neutral hub of AI coding **skills**, **rules**, **hooks**, and **MCP configs**, installed into every AI tool on my machine from a single source of truth.

Today it ships with a **Cursor** adapter; a **Claude Code** adapter is scaffolded and next on the runway. Aider, Continue, and Codex are planned.

Live site: <https://ai.happynguyen.name.vn/>

## What's inside

| Folder | Purpose |
|---|---|
| `core/skills/` | Agent skills in the standard `SKILL.md` format. Shared across every compatible tool. |
| `core/rules/` | Persistent rules — coding conventions, commit style, per-language guidance. |
| `core/hooks/` | Event-driven automation. Canonical event names; adapters translate to each tool. |
| `core/agents/` | Personas for specialized subagents (reviewer, planner, explorer). |
| `core/mcp/` | MCP server registry — each adapter renders this into its tool's native config. |
| `adapters/<tool>/` | One adapter per AI tool. Each knows that tool's native layout. |
| `bin/cowork` | The CLI. `install`, `uninstall`, `list`, `doctor`. |
| `bin/lib/` | Shared bash helpers (`log`, `link`, `frontmatter`). |
| `scripts/` | Plain shell helpers I invoke from the terminal. |
| `templates/` | Boilerplate: PR bodies, RFCs, issue templates. |
| `docs/` | Onboarding notes, workflow recipes, and the GitHub Pages site. |

## Quick start

One-line install (clones the repo, then auto-detects installed AI tools):

```bash
curl -fsSL https://ai.happynguyen.name.vn/install.sh | bash
```

Pick specific tools:

```bash
curl -fsSL https://ai.happynguyen.name.vn/install.sh | bash -s -- --tool=cursor,claude
```

Or clone manually:

```bash
git clone https://github.com/nguyenhappy92/happy-cowork.git ~/code/happy-cowork
cd ~/code/happy-cowork
bin/cowork install                       # auto-detect installed tools
bin/cowork install --tool=cursor          # one tool
bin/cowork install --only=skills,rules    # specific categories
bin/cowork doctor                         # verify install state
bin/cowork list tools | list skills       # introspect
```

The legacy `./install.sh` still works — it's a shim that calls `bin/cowork install --tool=cursor`.

Full walkthrough — prerequisites, update, uninstall, troubleshooting — at <https://ai.happynguyen.name.vn/install/>.

## CLI

```text
cowork install   [--tool=<t>[,<t>...]] [--only=<c>[,<c>...]] [--dry-run]
cowork uninstall [--tool=<t>[,<t>...]]
cowork list      tools | skills | rules | mcp
cowork doctor    [--tool=<t>]
cowork version
```

Categories are `skills`, `rules`, `hooks`, `mcp`, `agents`. Tools are the subfolders under `adapters/`.

## Adding a new skill

1. Ask your AI tool: "Use the `create-skill` skill to add a new skill called `my-thing`."
2. Or manually: `mkdir core/skills/my-thing && $EDITOR core/skills/my-thing/SKILL.md`.
3. Every `SKILL.md` needs frontmatter:

```markdown
---
name: my-thing
description: One-liner that starts with "Use when …" so the agent knows when to pick it.
tools: [cursor, claude]   # optional; default: every tool
---
```

4. Commit and push. The install uses symlinks, so no reinstall is needed on your own machine.

## Supported tools

| Tool | Adapter | Status |
|---|---|---|
| Cursor | `adapters/cursor/` | shipping |
| Claude Code | `adapters/claude/` | scaffold (install NYI) |
| Aider | — | planned |
| Continue.dev | — | planned |
| Codex | — | planned |

Adding a new tool: create `adapters/<name>/adapter.sh` implementing `adapter_<name>::{name,target,detect,install,uninstall,doctor}`. The CLI discovers it automatically.

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

1. **Single source of truth.** `core/` is tool-neutral. Adapters project it — no duplication, no drift.
2. **Symlink, don't copy.** Edits in `core/` take effect immediately for every installed tool.
3. **One folder per skill.** Keeps diffs and discovery clean.
4. **Descriptions matter.** The agent selects skills by their `description` frontmatter — write it like a trigger phrase.
5. **Opt-in per tool.** Skills can declare `tools: [cursor]` in frontmatter if a tool-specific API is required.
6. **No secrets in git.** Use `.env.example` + direnv / 1Password CLI for anything sensitive.
7. **Bash core, no runtime.** The CLI and adapters are plain bash. No Node, Python, or Go required.
8. **Promote twice-repeated prompts into skills.** If I type the same instructions twice, it belongs here.

## Roadmap

- [x] Landing page on GitHub Pages (`docs/index.html` → <https://ai.happynguyen.name.vn/>).
- [x] One-line curl-pipe installer (`docs/install.sh` → <https://ai.happynguyen.name.vn/install.sh>).
- [x] Install walkthrough page (`docs/install/index.html` → <https://ai.happynguyen.name.vn/install/>).
- [x] Multi-tool refactor: `core/` + `adapters/` + `bin/cowork`.
- [ ] Complete Claude Code adapter (render `CLAUDE.md`, install skills, install hooks).
- [ ] Aider and Continue adapters.
- [ ] CI lint for `SKILL.md` frontmatter + adapter smoke tests (bats).
- [ ] `cowork add skill <name>` scaffolder.
- [ ] `justfile` shortcuts.
- [ ] Canvas dashboards for recurring analyses.

## License

MIT — see `LICENSE`.
