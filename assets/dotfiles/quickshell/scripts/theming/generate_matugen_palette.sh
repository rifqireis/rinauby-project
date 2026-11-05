#!/usr/bin/env bash
# ==============================================================================
# Rinauby Monochromatic Matugen Palette Generator Wrapper
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/generate_matugen_palette.py"

if [ ! -f "$PYTHON_SCRIPT" ]; then
    echo "Error: Python generator script not found at $PYTHON_SCRIPT" >&2
    exit 1
fi

exec python3 "$PYTHON_SCRIPT" "$@"

