# Workflow recipes

Short, copy-pasteable recipes that combine multiple skills.

## Morning routine

1. `/standup` — summarize yesterday, plan today.
2. `/triage` — see what's urgent in the backlog.
3. Pick one item, open a branch: `scripts/new-branch.sh <slug>`.

## Ship a small fix

1. Edit + commit.
2. `/create-pr` — opens PR targeting `dev`.
3. Wait for CI / review.
4. After merge: `scripts/cleanup-branches.sh --apply`.

## Weekly release

1. On `dev`, confirm CI is green.
2. Merge `dev` → `main` via PR.
3. On `main`: `/release-notes v<next>`.
4. Tag and push: `git tag v<next> && git push --tags`.
5. `gh release create v<next> --notes-file CHANGELOG.md`.

## Unfamiliar-repo landing

1. Ask Cursor: "Use the explorer persona to map this repo."
2. Read `README.md` + `AGENTS.md` + any `docs/`.
3. Before editing, write 3 bullets on what you think the repo does and confirm with a teammate.

## Ambiguous task

1. Switch Cursor into **Plan** mode.
2. Use the `planner` persona — produce options + recommended path + ordered steps.
3. Switch back to **Agent** mode and execute one step at a time.
