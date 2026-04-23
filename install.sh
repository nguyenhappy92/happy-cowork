#!/usr/bin/env bash
# Symlink skills, rules, and hooks from this repo into ~/.cursor/.
# Idempotent: safe to re-run. Existing symlinks pointing elsewhere are replaced;
# existing regular files/dirs are backed up with a .bak suffix.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURSOR_HOME="${CURSOR_HOME:-$HOME/.cursor}"

log() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m  %s\n' "$*" >&2; }

link_dir_contents() {
  local src_root="$1"
  local dest_root="$2"

  if [[ ! -d "$src_root" ]]; then
    warn "Source $src_root does not exist, skipping."
    return
  fi

  mkdir -p "$dest_root"

  local entry
  for entry in "$src_root"/*; do
    [[ -e "$entry" ]] || continue
    local name
    name="$(basename "$entry")"
    local target="$dest_root/$name"

    if [[ -L "$target" ]]; then
      rm "$target"
    elif [[ -e "$target" ]]; then
      warn "Backing up existing $target -> $target.bak"
      mv "$target" "$target.bak"
    fi

    ln -s "$entry" "$target"
    log "Linked $target -> $entry"
  done
}

log "Repo: $REPO_ROOT"
log "Cursor home: $CURSOR_HOME"

link_dir_contents "$REPO_ROOT/skills" "$CURSOR_HOME/skills"
link_dir_contents "$REPO_ROOT/rules"  "$CURSOR_HOME/rules"

if [[ -f "$REPO_ROOT/hooks/hooks.json" ]]; then
  mkdir -p "$CURSOR_HOME/hooks"
  target="$CURSOR_HOME/hooks/hooks.json"
  if [[ -L "$target" ]]; then rm "$target"
  elif [[ -e "$target" ]]; then mv "$target" "$target.bak"
  fi
  ln -s "$REPO_ROOT/hooks/hooks.json" "$target"
  log "Linked $target -> $REPO_ROOT/hooks/hooks.json"

  if [[ -d "$REPO_ROOT/hooks/scripts" ]]; then
    chmod +x "$REPO_ROOT"/hooks/scripts/*.sh 2>/dev/null || true
    target="$CURSOR_HOME/hooks/scripts"
    if [[ -L "$target" ]]; then rm "$target"
    elif [[ -e "$target" ]]; then mv "$target" "$target.bak"
    fi
    ln -s "$REPO_ROOT/hooks/scripts" "$target"
    log "Linked $target -> $REPO_ROOT/hooks/scripts"
  fi
fi

log "Done. Restart Cursor to pick up hook changes."
