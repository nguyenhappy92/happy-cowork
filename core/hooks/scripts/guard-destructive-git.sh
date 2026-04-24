#!/usr/bin/env bash
# Block obviously destructive git commands before they run.
# Reads the proposed command from stdin (JSON with a "command" field) or from
# the CURSOR_HOOK_COMMAND env var, whichever the runtime provides.
#
# Exits non-zero to veto the command.

set -euo pipefail

cmd="${CURSOR_HOOK_COMMAND:-}"
if [[ -z "$cmd" ]] && [[ ! -t 0 ]]; then
  payload="$(cat)"
  cmd="$(printf '%s' "$payload" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("command",""))' 2>/dev/null || true)"
fi

deny() {
  printf '\033[1;31mBlocked by guard-destructive-git:\033[0m %s\n' "$1" >&2
  exit 1
}

[[ -z "$cmd" ]] && exit 0

if [[ "$cmd" =~ git[[:space:]]+push[[:space:]].*--force([^-]|$) ]]; then
  if [[ "$cmd" == *"main"* || "$cmd" == *"master"* || "$cmd" == *"dev"* ]]; then
    deny "force-push to a protected branch ($cmd)"
  fi
fi

if [[ "$cmd" =~ git[[:space:]]+reset[[:space:]]+--hard ]]; then
  deny "git reset --hard ($cmd). Use a softer reset or confirm explicitly."
fi

if [[ "$cmd" =~ git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*f[a-zA-Z]*d ]]; then
  deny "git clean -fd ($cmd). Confirm explicitly before wiping untracked files."
fi

exit 0
