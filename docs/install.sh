#!/usr/bin/env bash
# Happy Cowork bootstrap installer.
#
# Usage:
#   curl -fsSL https://ai.happynguyen.name.vn/install.sh | bash
#
#   # Select tools explicitly:
#   curl -fsSL https://ai.happynguyen.name.vn/install.sh | bash -s -- --tool=cursor,claude
#
# Inspect-then-run (recommended):
#   curl -fsSL https://ai.happynguyen.name.vn/install.sh -o happy-cowork.sh
#   less happy-cowork.sh
#   bash happy-cowork.sh
#
# Environment overrides:
#   HAPPY_COWORK_DIR    Where to clone the repo  (default: $HOME/code/happy-cowork)
#   HAPPY_COWORK_REPO   Git URL                  (default: https://github.com/nguyenhappy92/happy-cowork.git)
#   HAPPY_COWORK_REF    Branch / tag / SHA       (default: main)
#   HAPPY_COWORK_TOOLS  Comma list of tools      (default: cursor)
#   CURSOR_HOME         Forwarded to cowork      (default: $HOME/.cursor)
#   CLAUDE_HOME         Forwarded to cowork      (default: $HOME/.claude)

set -euo pipefail

REPO_DIR="${HAPPY_COWORK_DIR:-$HOME/code/happy-cowork}"
REPO_URL="${HAPPY_COWORK_REPO:-https://github.com/nguyenhappy92/happy-cowork.git}"
REPO_REF="${HAPPY_COWORK_REF:-main}"

if [[ -t 2 ]]; then
  C_G=$'\033[1;32m'; C_Y=$'\033[1;33m'; C_R=$'\033[1;31m'; C_B=$'\033[1;34m'; C_X=$'\033[0m'
else
  C_G=""; C_Y=""; C_R=""; C_B=""; C_X=""
fi

log()  { printf '%s==>%s %s\n' "$C_G" "$C_X" "$*" >&2; }
warn() { printf '%s!!%s  %s\n' "$C_Y" "$C_X" "$*" >&2; }
die()  { printf '%sxx%s  %s\n' "$C_R" "$C_X" "$*" >&2; exit 1; }

banner() {
  printf '%s' "$C_B" >&2
  cat >&2 <<'EOF'
    _                            _
   | |_   ___   ___  ___  _  _  | |
   | ' \ / _ \ (_-< (_-<| || |  |_|
   |_||_|\___/ /__/ /__/ \_, |  (_)
                         |__/
   cowork  —  cursor skills · rules · hooks
EOF
  printf '%s\n' "$C_X" >&2
}

require() {
  command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"
}

main() {
  banner

  log "Repo:   $REPO_URL"
  log "Ref:    $REPO_REF"
  log "Target: $REPO_DIR"

  require bash
  require git

  local bv="${BASH_VERSINFO[0]:-0}"
  [[ "$bv" -ge 3 ]] || die "bash >= 3.2 required, found $BASH_VERSION"

  local cursor_home="${CURSOR_HOME:-$HOME/.cursor}"
  if [[ ! -d "$cursor_home" ]]; then
    warn "Cursor home not found at $cursor_home."
    warn "Launch Cursor once to create it, then re-run this installer."
  fi

  if [[ -d "$REPO_DIR/.git" ]]; then
    log "Repo already exists — syncing to $REPO_REF."
    git -C "$REPO_DIR" fetch --depth 1 origin "$REPO_REF"
    git -C "$REPO_DIR" checkout --quiet "$REPO_REF"
    git -C "$REPO_DIR" pull --ff-only origin "$REPO_REF"
  elif [[ -e "$REPO_DIR" ]]; then
    die "$REPO_DIR exists and is not a git repo. Move it aside and re-run."
  else
    log "Cloning into $REPO_DIR ..."
    mkdir -p "$(dirname "$REPO_DIR")"
    git clone --depth 1 --branch "$REPO_REF" "$REPO_URL" "$REPO_DIR"
  fi

  chmod +x "$REPO_DIR/bin/cowork" 2>/dev/null || true
  chmod +x "$REPO_DIR/install.sh" 2>/dev/null || true

  log "Running cowork install ..."
  if [[ -x "$REPO_DIR/bin/cowork" ]]; then
    "$REPO_DIR/bin/cowork" install "$@"
  else
    # Fallback for older checkouts before the multi-tool refactor.
    "$REPO_DIR/install.sh" "$@"
  fi

  cat >&2 <<EOF

${C_G}==>${C_X} Done.

  Repo:   $REPO_DIR
  Cursor: $cursor_home

  Next steps:
    1. Restart Cursor.
    2. In any chat, ask:  "List the skills you have available."
    3. Update later with: cd "$REPO_DIR" && git pull

  Docs: https://ai.happynguyen.name.vn/install/
EOF
}

main "$@"
