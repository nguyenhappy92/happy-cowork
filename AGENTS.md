# Agent conventions for happy-cowork

These rules apply to any AI agent operating in this repository.

## Repository purpose

This repo is a tool-neutral automation hub for AI coding tools. Its artifacts (skills, rules, hooks, MCP configs) are projected from `core/` into each tool's native home (e.g. `~/.cursor/`, `~/.claude/`) by a per-tool adapter. Treat every file here as production: other machines depend on it.

## Repository layout

- `core/` — the single source of truth. Tool-neutral content.
  - `core/skills/<name>/SKILL.md` — one folder per skill.
  - `core/rules/*.md` — one topic per file.
  - `core/hooks/` — canonical event names (`agent-stop`, `before-shell`, ...).
  - `core/agents/` — persona definitions.
  - `core/mcp/servers.json` — MCP server registry.
- `adapters/<tool>/adapter.sh` — one file per supported tool. Implements `adapter_<tool>::{name,target,detect,install,uninstall,doctor}`.
- `bin/cowork` — CLI dispatcher.
- `bin/lib/` — shared bash helpers (`log.sh`, `link.sh`, `frontmatter.sh`). Source them in adapters; don't reinvent.
- `scripts/`, `templates/`, `docs/` — unchanged by the multi-tool refactor.
- `install.sh` (top-level) — back-compat shim; delegates to `bin/cowork install`.

## Authoring rules

1. **Skills live in `core/skills/<skill-name>/SKILL.md`.** One folder per skill. Never put two skills in one file.
2. **Every `SKILL.md` starts with YAML frontmatter** with at minimum `name` and `description`. The description should begin with "Use when …" so the agent picks it up reliably. An optional `tools: [cursor, claude]` list restricts which adapters install the skill (default: all).
3. **Rules live in `core/rules/*.md`.** Keep each rule under ~50 lines and single-topic. Rules may also use a `tools:` frontmatter list.
4. **Hooks live in `core/hooks/`.** `hooks.json` is the manifest for the Cursor adapter today; future adapters render their own.
5. **Scripts under `hooks/scripts/` and any helper in `bin/` or `adapters/`** must start with `#!/usr/bin/env bash` and `set -euo pipefail`, and must be `chmod +x`.
6. **No secrets.** Use `.env.example` to document required environment variables. Real secrets stay in the user's `~/.env` or a password manager.

## Adapter rules

- Every adapter must implement `adapter_<tool>::{name, target, detect, supports, install, uninstall, doctor}`. Missing any of these is a bug.
- Adapters **must not** modify anything under `core/`. They only read from it.
- Adapters **must** be idempotent. Second run = same state as first.
- Adapters **must** use the helpers in `bin/lib/` for logging, symlinking, and frontmatter parsing.
- If a tool does not support a given category (e.g. Aider has no hooks), the adapter logs a warning and moves on — never fails.

## Commit style

- Imperative subject, 50 chars max (`add daily-standup skill`).
- Body wrapped at 72 chars, explaining *why* not *what*.
- Reference the skill / rule / hook / adapter being changed in the subject when possible.

## PR etiquette

- One logical change per PR.
- Update `README.md`'s "Current skills" or "Supported tools" tables when the set changes.
- If you add a dependency (script, binary), document it in `docs/getting-started.md`.

## Things to avoid

- Don't hard-code absolute paths in skills — use `$HOME` or relative paths from the adapter's target.
- Don't copy files where a symlink works. The MCP template is the one exception, because it will be edited with secrets.
- Don't duplicate content across tools — adapt at install time from a single `core/` file.
- Don't commit machine-specific configs. Parameterize via env vars instead.
