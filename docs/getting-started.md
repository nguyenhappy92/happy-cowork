# Getting started

## Prerequisites

- macOS or Linux with `bash` 4+.
- `git` 2.30+.
- [`gh`](https://cli.github.com/) authenticated (`gh auth login`).
- Cursor installed, with `~/.cursor/` existing (any Cursor launch creates it).

Optional but recommended:

- `jq` for JSON wrangling in scripts.
- `direnv` for per-repo env vars.

## Install

```bash
git clone git@github.com:<you>/happy-cowork.git ~/code/happy-cowork
cd ~/code/happy-cowork
./install.sh
```

`install.sh` symlinks:

- `skills/*` → `~/.cursor/skills/`
- `rules/*` → `~/.cursor/rules/`
- `hooks/hooks.json` → `~/.cursor/hooks/hooks.json`
- `hooks/scripts` → `~/.cursor/hooks/scripts`

Because everything is symlinked, editing a file in the repo is instantly picked up by Cursor.

## Verify

Open Cursor, start a new chat, and ask:

> "List the skills you have available."

You should see `create-pr`, `rebase`, `review-pr`, `daily-standup`, `triage-issues`, and `release-notes`.

## Update

```bash
cd ~/code/happy-cowork
git pull --rebase
# No reinstall needed — symlinks already point here.
```

## Uninstall

```bash
cd ~/code/happy-cowork
# Remove the symlinks only; .bak files created during install stay put.
find ~/.cursor/skills ~/.cursor/rules ~/.cursor/hooks -maxdepth 2 -type l \
  -lname "$(pwd)/*" -print -delete
```
