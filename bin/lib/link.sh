#!/usr/bin/env bash
# Symlink helpers shared across adapters. Idempotent and safe.
# Source `log.sh` before this file so cowork::warn is available.

# cowork::link src dest
#   Ensure `dest` is a symlink to `src`.
#   - If dest is already a symlink, replace it.
#   - If dest is a regular file/dir, move it to dest.bak.
#   - Returns 0 on success.
cowork::link() {
  local src="$1"
  local dest="$2"
  [[ -e "$src" ]] || { cowork::warn "missing source: $src"; return 1; }

  mkdir -p "$(dirname "$dest")"

  if [[ -L "$dest" ]]; then
    rm "$dest"
  elif [[ -e "$dest" ]]; then
    cowork::warn "backing up existing $dest -> $dest.bak"
    mv "$dest" "$dest.bak"
  fi

  ln -s "$src" "$dest"
  cowork::dim "   linked $dest"
  return 0
}

# cowork::link_children src_dir dest_dir
#   Symlink every child of src_dir into dest_dir.
cowork::link_children() {
  local src_root="$1"
  local dest_root="$2"

  if [[ ! -d "$src_root" ]]; then
    cowork::warn "source dir not found: $src_root"
    return 0
  fi

  mkdir -p "$dest_root"
  local entry
  for entry in "$src_root"/*; do
    [[ -e "$entry" ]] || continue
    local name
    name="$(basename "$entry")"
    cowork::link "$entry" "$dest_root/$name"
  done
}

# cowork::unlink_if_ours dest src_prefix
#   Remove dest if it's a symlink pointing into src_prefix.
cowork::unlink_if_ours() {
  local dest="$1"
  local prefix="$2"

  if [[ -L "$dest" ]]; then
    local target
    target="$(readlink "$dest")"
    if [[ "$target" == "$prefix"* ]]; then
      rm "$dest"
      cowork::dim "   removed $dest"
      return 0
    fi
  fi
  return 1
}
