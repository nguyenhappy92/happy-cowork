#!/usr/bin/env bash
# Cursor adapter — installs core/ content into ~/.cursor/.
#
# Skills:  core/skills/<name>/SKILL.md     -> ~/.cursor/skills/<name>      (symlink)
# Rules:   core/rules/*.md                 -> ~/.cursor/rules/*.md         (symlink)
# Hooks:   core/hooks/hooks.json           -> ~/.cursor/hooks/hooks.json   (symlink)
#          core/hooks/scripts/             -> ~/.cursor/hooks/scripts      (symlink)
# MCP:     core/mcp/servers.json           -> ~/.cursor/mcp.template.json  (copy, not symlink)
#
# The MCP file is copied (not symlinked) because users typically hand-edit
# ~/.cursor/mcp.json with secrets. We never overwrite mcp.json; we drop
# a template next to it so users can diff.

set -euo pipefail

adapter_cursor::name()     { echo "cursor"; }
adapter_cursor::target()   { echo "${CURSOR_HOME:-$HOME/.cursor}"; }
adapter_cursor::detect()   { [[ -d "$(adapter_cursor::target)" ]]; }
adapter_cursor::supports() { echo "skills rules hooks mcp"; }

adapter_cursor::install_skills() {
  local target; target="$(adapter_cursor::target)/skills"
  local src="$COWORK_ROOT/core/skills"
  [[ -d "$src" ]] || { cowork::warn "no core/skills dir"; return 0; }

  cowork::log "cursor: installing skills -> $target"
  mkdir -p "$target"
  local entry
  for entry in "$src"/*; do
    [[ -d "$entry" ]] || continue
    local name skill_md
    name="$(basename "$entry")"
    skill_md="$entry/SKILL.md"
    if [[ -f "$skill_md" ]] && ! cowork::targets_tool "$skill_md" "cursor"; then
      cowork::dim "   skipping $name (tools: excludes cursor)"
      continue
    fi
    cowork::link "$entry" "$target/$name"
  done
}

adapter_cursor::install_rules() {
  local target; target="$(adapter_cursor::target)/rules"
  local src="$COWORK_ROOT/core/rules"
  [[ -d "$src" ]] || { cowork::warn "no core/rules dir"; return 0; }

  cowork::log "cursor: installing rules -> $target"
  mkdir -p "$target"
  local entry
  for entry in "$src"/*.md; do
    [[ -f "$entry" ]] || continue
    if ! cowork::targets_tool "$entry" "cursor"; then
      cowork::dim "   skipping $(basename "$entry") (tools: excludes cursor)"
      continue
    fi
    cowork::link "$entry" "$target/$(basename "$entry")"
  done
}

adapter_cursor::install_hooks() {
  local target_dir; target_dir="$(adapter_cursor::target)/hooks"
  local src="$COWORK_ROOT/core/hooks"
  [[ -f "$src/hooks.json" ]] || { cowork::warn "no core/hooks/hooks.json"; return 0; }

  cowork::log "cursor: installing hooks -> $target_dir"
  mkdir -p "$target_dir"
  cowork::link "$src/hooks.json" "$target_dir/hooks.json"

  if [[ -d "$src/scripts" ]]; then
    chmod +x "$src"/scripts/*.sh 2>/dev/null || true
    cowork::link "$src/scripts" "$target_dir/scripts"
  fi
}

adapter_cursor::install_mcp() {
  local target_dir; target_dir="$(adapter_cursor::target)"
  local src="$COWORK_ROOT/core/mcp/servers.json"
  [[ -f "$src" ]] || { cowork::warn "no core/mcp/servers.json"; return 0; }

  local target_file="$target_dir/mcp.template.json"
  cowork::log "cursor: copying MCP template -> $target_file"
  cp "$src" "$target_file"
  if [[ -f "$target_dir/mcp.json" ]]; then
    cowork::dim "   note: ~/.cursor/mcp.json exists; template written alongside as mcp.template.json"
  else
    cowork::dim "   note: merge interesting servers into ~/.cursor/mcp.json manually"
  fi
}

adapter_cursor::install() {
  local categories="${1:-all}"

  cowork::log "cursor: target = $(adapter_cursor::target)"
  if ! adapter_cursor::detect; then
    cowork::warn "cursor home not found at $(adapter_cursor::target)"
    cowork::warn "launch Cursor once to create it, then re-run."
  fi

  if [[ "$categories" == "all" || "$categories" == *skills* ]]; then
    adapter_cursor::install_skills
  fi
  if [[ "$categories" == "all" || "$categories" == *rules* ]]; then
    adapter_cursor::install_rules
  fi
  if [[ "$categories" == "all" || "$categories" == *hooks* ]]; then
    adapter_cursor::install_hooks
  fi
  if [[ "$categories" == "all" || "$categories" == *mcp* ]]; then
    adapter_cursor::install_mcp
  fi
}

adapter_cursor::uninstall() {
  local target; target="$(adapter_cursor::target)"
  cowork::log "cursor: removing symlinks pointing at $COWORK_ROOT"
  local dir
  for dir in "$target/skills" "$target/rules" "$target/hooks"; do
    [[ -d "$dir" ]] || continue
    local entry
    for entry in "$dir"/* "$dir"/hooks.json "$dir"/scripts; do
      [[ -e "$entry" || -L "$entry" ]] || continue
      cowork::unlink_if_ours "$entry" "$COWORK_ROOT" || true
    done
  done
  if [[ -f "$target/mcp.template.json" ]]; then
    rm "$target/mcp.template.json"
    cowork::dim "   removed $target/mcp.template.json"
  fi
}

adapter_cursor::doctor() {
  local target; target="$(adapter_cursor::target)"
  cowork::log "cursor doctor: target = $target"
  if ! adapter_cursor::detect; then
    cowork::warn "   target directory does not exist"
    return 1
  fi

  local ok=0 fail=0
  local entry target_path
  for entry in "$COWORK_ROOT"/core/skills/*/; do
    [[ -d "$entry" ]] || continue
    target_path="$target/skills/$(basename "${entry%/}")"
    if [[ -L "$target_path" ]]; then ok=$((ok + 1)); else fail=$((fail + 1)); fi
  done
  cowork::info "   skills: $ok linked, $fail missing"

  ok=0; fail=0
  for entry in "$COWORK_ROOT"/core/rules/*.md; do
    [[ -f "$entry" ]] || continue
    target_path="$target/rules/$(basename "$entry")"
    if [[ -L "$target_path" ]]; then ok=$((ok + 1)); else fail=$((fail + 1)); fi
  done
  cowork::info "   rules:  $ok linked, $fail missing"

  [[ -L "$target/hooks/hooks.json" ]] && cowork::info "   hooks:  linked" || cowork::info "   hooks:  not linked"
  [[ -f "$target/mcp.template.json" ]] && cowork::info "   mcp:    template present" || cowork::info "   mcp:    no template"
}
