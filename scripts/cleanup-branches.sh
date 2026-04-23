#!/usr/bin/env bash
# Delete local branches whose upstream has been merged or deleted.
# Dry-run by default; pass --apply to actually delete.

set -euo pipefail

apply=false
for arg in "$@"; do
  case "$arg" in
    --apply) apply=true ;;
    -h|--help)
      echo "usage: $(basename "$0") [--apply]"; exit 0 ;;
  esac
done

git fetch --all --prune

current="$(git branch --show-current)"

gone="$(git for-each-ref --format '%(refname:short) %(upstream:track)' refs/heads \
        | awk '$2 == "[gone]" {print $1}')"

if [[ -z "$gone" ]]; then
  echo "No branches with gone upstreams."
  exit 0
fi

echo "Branches with gone upstreams:"
echo "$gone" | sed 's/^/  /'

if ! $apply; then
  echo
  echo "(dry-run) Re-run with --apply to delete."
  exit 0
fi

while IFS= read -r branch; do
  [[ -z "$branch" ]] && continue
  if [[ "$branch" == "$current" ]]; then
    echo "Skipping current branch: $branch"
    continue
  fi
  git branch -D "$branch"
done <<< "$gone"
