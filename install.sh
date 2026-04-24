#!/usr/bin/env bash
# Compatibility shim — delegates to `bin/cowork install`.
# Kept so the historical `cd ~/code/happy-cowork && ./install.sh` flow
# and the curl-pipe bootstrap continue to work verbatim.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS="${HAPPY_COWORK_TOOLS:-cursor}"
exec "$REPO_ROOT/bin/cowork" install --tool="$TOOLS" "$@"
