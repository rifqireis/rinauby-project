#!/usr/bin/env bash

# ==============================================================================
# RINAUBY : QUICKSHELL WALLPAPER APPLIER (SWWW CIRCULAR GROW ANIMATION)
# ==============================================================================

SELECTED_PATH="$1"
[ -f "$SELECTED_PATH" ] || exit 1

FILENAME="$(basename "$SELECTED_PATH")"
STEM="${FILENAME%.*}"

case "$STEM" in
    apotheosis) CHOSEN="The Apotheosis" ;;
    school_of_athens) CHOSEN="The School of Athens" ;;
    the_creation_of_adam|creation_of_adam) CHOSEN="The Creation of Adam" ;;
    the_last_supper|last_supper) CHOSEN="The Last Supper" ;;
    birth_of_venus) CHOSEN="The Birth of Venus" ;;
    primavera) CHOSEN="Primavera" ;;
    tower_of_babel) CHOSEN="The Tower of Babel" ;;
    annunciation) CHOSEN="The Annunciation" ;;
    *) CHOSEN="$(echo "$STEM" | sed -r 's/(^|_)([a-z])/\U\2/g' | tr '_' ' ')" ;;
esac

echo "$CHOSEN" > /tmp/current_wallpaper_title

# 1. Apply wallpaper via swww (circular grow reveal animation)
if command -v swww &>/dev/null || command -v awww &>/dev/null; then
    WP_CMD=$(command -v swww 2>/dev/null || command -v awww 2>/dev/null)
    WP_DAEMON="${WP_CMD}-daemon"
    WP_NAME="${WP_DAEMON##*/}"

    if ! pgrep -x "$WP_NAME" >/dev/null; then
        "$WP_DAEMON" &>/dev/null &
        sleep 0.3
    fi

    pkill -x swaybg 2>/dev/null || true

    "$WP_CMD" img "$SELECTED_PATH" \
        --transition-type grow \
        --transition-pos center \
        --transition-duration 1.5 \
        --transition-fps 60 \
        --transition-bezier .43,1.19,1,1
elif command -v hyprctl &>/dev/null && pgrep -x hyprpaper >/dev/null; then
    hyprctl hyprpaper preload "$SELECTED_PATH"
    hyprctl hyprpaper wallpaper ",$SELECTED_PATH"
    hyprctl hyprpaper unload all >/dev/null 2>&1
elif command -v swaybg &>/dev/null; then
    pkill -x swaybg 2>/dev/null
    swaybg -i "$SELECTED_PATH" -m fill &
fi

# 2. Rotate quote & update Waybar title
if [ -f "$HOME/.config/waybar/quote_rotator.sh" ]; then
    bash "$HOME/.config/waybar/quote_rotator.sh" --next >/dev/null 2>&1
elif command -v rinauby-quote >/dev/null 2>&1; then
    rinauby-quote --next >/dev/null 2>&1
fi

pkill -RTMIN+8 waybar 2>/dev/null || true
pkill -USR1 -f window_title.py 2>/dev/null || true

notify-send "Renaissance Masterpiece" "Telah dipasang: $CHOSEN" -i "$SELECTED_PATH" 2>/dev/null || true
