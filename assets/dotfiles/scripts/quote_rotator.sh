#!/usr/bin/env bash

# ==============================================================================
# SCHOOL OF ATHENS — RENAISSANCE MOTTO & QUOTE ROTATOR
# Rotates iconic Renaissance Humanism mottos periodically & on wallpaper switch
# ==============================================================================

QUOTE_FILE="/tmp/current_renaissance_quote"

QUOTES=(
    "Ad Fontes"
    "Cerca il Vero"
    "Cognoscere Causas"
    "La Rinascita"
    "Sapere Aude"
    "Carpe Diem"
    "L'Uomo Universale"
    "Veritas Vos Liberabit"
    "Cogito Ergo Sum"
    "Ars Longa Vita Brevis"
)

rotate_random() {
    local current=""
    if [ -f "$QUOTE_FILE" ]; then
        current=$(cat "$QUOTE_FILE")
    fi

    local available=()
    for q in "${QUOTES[@]}"; do
        if [ "$q" != "$current" ]; then
            available+=("$q")
        fi
    done

    # Select random from available
    local count=${#available[@]}
    local rand_idx=$((RANDOM % count))
    local next_quote="${available[$rand_idx]}"

    echo "$next_quote" > "$QUOTE_FILE"
    echo "$next_quote"
}

if [ "$1" == "--next" ] || [ "$1" == "--random" ]; then
    rotate_random
    exit 0
fi

# If file exists and not empty, check rotation
if [ ! -f "$QUOTE_FILE" ]; then
    rotate_random
else
    # Default Waybar interval read
    rotate_random
fi
