# Agent conventions for happy-cowork

These rules apply to any AI agent operating in this repository.

## Repository purpose

This repo is a personal automation hub. Its artifacts (skills, rules, hooks) are symlinked into `~/.cursor/` and loaded by the Cursor agent on the maintainer's machine. Treat every file here as production: other machines depend on it.

## Authoring rules

1. **Skills live in `skills/<skill-name>/SKILL.md`.** One folder per skill. Never put two skills in one file.
2. **Every `SKILL.md` starts with YAML frontmatter** containing at minimum `name` and `description`. The description should begin with "Use when …" so the agent picks it up reliably.
3. **Rules live in `rules/*.md`.** Keep each rule under ~50 lines and single-topic.
4. **Hooks** go in `hooks/`. `hooks.json` is the manifest; scripts live under `hooks/scripts/` and must be executable (`chmod +x`).
5. **No secrets.** Use `.env.example` to document required environment variables. Real secrets stay in the user's `~/.env` or a password manager.
6. **Shell scripts** must start with `#!/usr/bin/env bash` and `set -euo pipefail`.

## Commit style

- Imperative subject, 50 chars max (`add daily-standup skill`).
- Body wrapped at 72 chars, explaining *why* not *what*.
- Reference the skill/rule/hook being changed in the subject when possible.

## PR etiquette

- One logical change per PR.
- Update `README.md`'s "Current skills" table when adding/removing a skill.
- If you add a dependency (script, binary), document it in `docs/getting-started.md`.

## Things to avoid

- Don't hard-code absolute paths in skills — use `$HOME` or relative paths from `~/.cursor/`.
- Don't copy files in `install.sh`. Symlink only.
- Don't commit machine-specific configs. Parameterize via env vars instead.
