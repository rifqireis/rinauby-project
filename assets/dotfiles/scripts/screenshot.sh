#!/usr/bin/env bash

# ==============================================================================
# SCHOOL OF ATHENS : SCREENSHOT TOOL
# Filosofi: Digital Humanism & Distraction-Free Classical Aesthetic
# Fitur: Potong Area (Snip), Layar Penuh, Jendela Aktif, Swappy Edit, & Rofi Menu
# ==============================================================================

TARGET_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$TARGET_DIR"

TIMESTAMP=$(date '+%Y-%m-%d_%H.%M.%S')
FILENAME="Screenshot_${TIMESTAMP}.png"
FILEPATH="${TARGET_DIR}/${FILENAME}"

# Warna seleksi Slurp bernuansa Renaissance Gold (#db9c5e) dan Dark Slate (#1c2124)
SLURP_ARGS=(-b "1c212488" -c "db9c5eff" -s "282c3444" -w 2)

notify_success() {
    local file="$1"
    local title="$2"
    local desc="$3"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "System" \
            -i "$file" \
            "$title" \
            "$desc" \
            2>/dev/null || true
    fi
}

case "$1" in
    "snip"|"region"|"area")
        GEOM=$(slurp "${SLURP_ARGS[@]}")
        [ -z "$GEOM" ] && exit 0
        grim -g "$GEOM" "$FILEPATH"
        wl-copy --type image/png < "$FILEPATH"
        notify_success "$FILEPATH" "Area Screenshot Captured" "Saved: $FILENAME\nCopied to clipboard."
        ;;

    "full"|"fullscreen"|"screen")
        sleep 0.15
        grim "$FILEPATH"
        wl-copy --type image/png < "$FILEPATH"
        notify_success "$FILEPATH" "Fullscreen Captured" "Saved: $FILENAME\nCopied to clipboard."
        ;;

    "window")
        ACTIVE_WINDOW=$(hyprctl activewindow -j 2>/dev/null)
        if [ -n "$ACTIVE_WINDOW" ] && [ "$ACTIVE_WINDOW" != "{}" ]; then
            GEOM=$(echo "$ACTIVE_WINDOW" | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
            grim -g "$GEOM" "$FILEPATH"
            wl-copy --type image/png < "$FILEPATH"
            notify_success "$FILEPATH" "Active Window Captured" "Saved: $FILENAME\nCopied to clipboard."
        else
            GEOM=$(slurp "${SLURP_ARGS[@]}")
            [ -z "$GEOM" ] && exit 0
            grim -g "$GEOM" "$FILEPATH"
            wl-copy --type image/png < "$FILEPATH"
            notify_success "$FILEPATH" "Area Screenshot Captured" "Saved: $FILENAME\nCopied to clipboard."
        fi
        ;;

    "edit"|"swappy")
        GEOM=$(slurp "${SLURP_ARGS[@]}")
        [ -z "$GEOM" ] && exit 0
        if command -v swappy >/dev/null 2>&1; then
            grim -g "$GEOM" - | swappy -f -
        else
            grim -g "$GEOM" "$FILEPATH"
            wl-copy --type image/png < "$FILEPATH"
            notify_success "$FILEPATH" "Area Screenshot Captured" "Saved: $FILENAME\nCopied to clipboard."
        fi
        ;;

    "delay"|"delay3"|"delay5")
        if [ "$1" = "delay3" ]; then
            SEC=3
        elif [ "$1" = "delay5" ]; then
            SEC=5
        else
            SEC="${2:-5}"
        fi
        if command -v notify-send >/dev/null 2>&1; then
            notify-send -a "System" "Delayed Screenshot" "Capturing screen in $SEC seconds..." 2>/dev/null || true
        fi
        sleep "$SEC"
        grim "$FILEPATH"
        wl-copy --type image/png < "$FILEPATH"
        notify_success "$FILEPATH" "Delayed Screenshot" "Saved: $FILENAME\nCopied to clipboard."
        ;;

    "menu"|*)
        QS_CFG="$(cd "$(dirname "${BASH_SOURCE[0]}")/../quickshell" 2>/dev/null && pwd)/shell.qml"
        [ -f "$QS_CFG" ] || QS_CFG="$HOME/.config/quickshell/shell.qml"

        if ! pgrep -x quickshell >/dev/null && ! pgrep -x qs >/dev/null; then
            quickshell -p "$QS_CFG" >/dev/null 2>&1 &
            sleep 0.4
        fi

        quickshell -p "$QS_CFG" ipc call launcher toggle "screenshot" >/dev/null 2>&1 || \
        quickshell -p "$HOME/.config/quickshell/shell.qml" ipc call launcher toggle "screenshot" >/dev/null 2>&1 || \
        quickshell ipc call launcher toggle "screenshot" >/dev/null 2>&1
        ;;
esac
