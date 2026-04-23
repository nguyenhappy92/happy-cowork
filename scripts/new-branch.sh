#!/usr/bin/env bash
# Create a new feature branch from the latest origin/<base>.
# Usage: new-branch.sh <slug> [base]
#   new-branch.sh add-daily-standup       # base defaults to dev (or main)

set -euo pipefail

slug="${1:-}"
base="${2:-}"

if [[ -z "$slug" ]]; then
  echo "usage: $(basename "$0") <slug> [base]" >&2
  exit 1
fi

if [[ -z "$base" ]]; then
  if git ls-remote --exit-code --heads origin dev >/dev/null 2>&1; then
    base="dev"
  else
    base="main"
  fi
fi

git fetch origin "$base"
git checkout -b "feat/$slug" "origin/$base"
echo "Created feat/$slug from origin/$base"
