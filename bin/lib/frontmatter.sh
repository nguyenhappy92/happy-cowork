#!/usr/bin/env bash
# Minimal YAML frontmatter reader for bash. Understands scalar keys
# and bracketed list values (e.g. tools: [cursor, claude]).
# Sufficient for SKILL.md and rule metadata. Not a full YAML parser.

# cowork::frontmatter_field <file> <field>
#   Echo the value of `field` from the --- ... --- block at the top.
#   Prints nothing (and returns 0) if field is missing.
cowork::frontmatter_field() {
  local file="$1"
  local field="$2"
  [[ -f "$file" ]] || return 0

  awk -v F="$field" '
    BEGIN   { in_fm = 0; started = 0 }
    /^---[[:space:]]*$/ {
      if (!started) { started = 1; in_fm = 1; next }
      else          { exit }
    }
    in_fm && started {
      line = $0
      if (match(line, "^[[:space:]]*" F "[[:space:]]*:[[:space:]]*")) {
        val = substr(line, RSTART + RLENGTH)
        sub(/[[:space:]]+$/, "", val)
        sub(/^"/, "", val); sub(/"$/, "", val)
        sub(/^'\''/, "", val); sub(/'\''$/, "", val)
        print val
        exit
      }
    }
  ' "$file"
}

# cowork::frontmatter_list <file> <field>
#   Parse a bracketed list like "[cursor, claude, aider]" into
#   newline-separated tokens. Empty / missing field -> empty output.
cowork::frontmatter_list() {
  local file="$1"
  local field="$2"
  local raw
  raw="$(cowork::frontmatter_field "$file" "$field")"
  [[ -z "$raw" ]] && return 0

  raw="${raw#[}"
  raw="${raw%]}"
  # shellcheck disable=SC2001
  sed 's/,/\n/g' <<<"$raw" \
    | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
    | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//" \
    | grep -v '^$' || true
}

# cowork::targets_tool <file> <tool>
#   Exit 0 if this file's frontmatter `tools:` list is missing or
#   contains <tool>. Exit 1 otherwise.
cowork::targets_tool() {
  local file="$1"
  local tool="$2"
  local tools
  tools="$(cowork::frontmatter_list "$file" "tools")"
  [[ -z "$tools" ]] && return 0
  grep -qx "$tool" <<<"$tools"
}
