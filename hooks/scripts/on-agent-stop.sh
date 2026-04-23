#!/usr/bin/env bash
# Fired when the Cursor agent finishes a turn.
# Shows a macOS notification; no-ops on other platforms.

set -euo pipefail

title="${CURSOR_HOOK_TITLE:-Cursor agent}"
message="${CURSOR_HOOK_MESSAGE:-Turn complete}"

if [[ "$(uname -s)" == "Darwin" ]] && command -v osascript >/dev/null 2>&1; then
  osascript -e "display notification \"$message\" with title \"$title\""
fi

exit 0
