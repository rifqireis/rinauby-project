#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.jsonc"
STYLE_FILE="$SCRIPT_DIR/style.css"

echo "Launching Renaissance Waybar preview..."
pkill -f "waybar -c $CONFIG_FILE" 2>/dev/null
waybar -c "$CONFIG_FILE" -s "$STYLE_FILE"
