#!/usr/bin/env bash
# Claude Code adapter — STUB.
#
# Claude Code (Anthropic's CLI) reads Agent Skills from ~/.claude/skills/
# with the same SKILL.md format Cursor uses, plus a CLAUDE.md for persistent
# context. This adapter is scaffolded so `cowork list tools` can see it,
# but `install` is intentionally not implemented yet — the multi-tool
# rollout adds real Claude support in a follow-up PR.

set -euo pipefail

adapter_claude::name()     { echo "claude"; }
adapter_claude::target()   { echo "${CLAUDE_HOME:-$HOME/.claude}"; }
adapter_claude::detect()   { [[ -d "$(adapter_claude::target)" ]]; }
adapter_claude::supports() { echo "skills rules agents"; }

adapter_claude::install() {
  cowork::warn "claude adapter: install not yet implemented"
  cowork::warn "   planned: symlink core/skills -> ~/.claude/skills,"
  cowork::warn "            render core/rules/* into ~/.claude/CLAUDE.md,"
  cowork::warn "            render core/agents/* into ~/.claude/agents/*."
  return 0
}

adapter_claude::uninstall() {
  cowork::warn "claude adapter: uninstall not yet implemented"
  return 0
}

adapter_claude::doctor() {
  local target; target="$(adapter_claude::target)"
  cowork::log "claude doctor: target = $target"
  adapter_claude::detect \
    && cowork::info "   target exists (install NYI)" \
    || cowork::warn "   target missing"
}
