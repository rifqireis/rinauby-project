#!/usr/bin/env bash

# ==============================================================================
# RENAISSANCE OS : TEST LAUNCHER DALAM SESI HYPRLAND AKTIF
# Meluncurkan satu jendela nested Hyprland baru yang terisolasi total
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HYPR_CONF="$SCRIPT_DIR/hyprland.conf"

echo "=========================================================="
echo "Meluncurkan Renaissance Hyprland (Nested Mode)..."
echo "Config: $HYPR_CONF"
echo "=========================================================="

# Unset signature agar hyprland baru membuat instance terpisah
env -u HYPRLAND_INSTANCE_SIGNATURE Hyprland -c "$HYPR_CONF"
