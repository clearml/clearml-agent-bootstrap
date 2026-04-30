#!/bin/bash
#
# resolve_bom.sh - Generate bootstrap/bom.yaml with "latest" versions resolved
# to the actual versions downloaded during the build.
#
# Reads: bom.yaml (project root, build input)
# Reads: bootstrap/uv/.resolved_version (written by update_uv_binaries.py)
# Writes: bootstrap/bom.yaml (resolved output, included in wheel and images)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BOM_SRC="$REPO_ROOT/bom.yaml"
BOM_DST="$REPO_ROOT/bootstrap/bom.yaml"

cp "$BOM_SRC" "$BOM_DST"

# Resolve UV_VERSION
UV_RESOLVED_FILE="$REPO_ROOT/bootstrap/uv/.resolved_version"
if [ -f "$UV_RESOLVED_FILE" ]; then
    UV_RESOLVED=$(cat "$UV_RESOLVED_FILE")
    echo "Resolved UV_VERSION: $UV_RESOLVED"
    yq -i ".UV_VERSION = \"$UV_RESOLVED\"" "$BOM_DST"
fi

# Resolve CPYTHON_STANDALONE_VERSION to match UV (sourced from same repo)
CPYTHON_CURRENT=$(yq -r '.CPYTHON_STANDALONE_VERSION' "$BOM_DST")
if [ "$CPYTHON_CURRENT" = "latest" ] && [ -f "$UV_RESOLVED_FILE" ]; then
    echo "Resolved CPYTHON_STANDALONE_VERSION: $UV_RESOLVED (from UV)"
    yq -i ".CPYTHON_STANDALONE_VERSION = \"$UV_RESOLVED\"" "$BOM_DST"
fi

echo ""
echo "=== Resolved BOM written to $BOM_DST ==="
cat "$BOM_DST"
