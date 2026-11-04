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
        notify-send -a "School of Athens" \
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
        notify_success "$FILEPATH" "🏛 Tangkapan Layar Area" "Tersimpan: $FILENAME\nDisalin ke papan klip."
        ;;

    "full"|"fullscreen"|"screen")
        sleep 0.15
        grim "$FILEPATH"
        wl-copy --type image/png < "$FILEPATH"
        notify_success "$FILEPATH" "🏛 Tangkapan Layar Penuh" "Tersimpan: $FILENAME\nDisalin ke papan klip."
        ;;

    "window")
        ACTIVE_WINDOW=$(hyprctl activewindow -j 2>/dev/null)
        if [ -n "$ACTIVE_WINDOW" ] && [ "$ACTIVE_WINDOW" != "{}" ]; then
            GEOM=$(echo "$ACTIVE_WINDOW" | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
            grim -g "$GEOM" "$FILEPATH"
            wl-copy --type image/png < "$FILEPATH"
            notify_success "$FILEPATH" "🏛 Tangkapan Jendela Aktif" "Tersimpan: $FILENAME\nDisalin ke papan klip."
        else
            GEOM=$(slurp "${SLURP_ARGS[@]}")
            [ -z "$GEOM" ] && exit 0
            grim -g "$GEOM" "$FILEPATH"
            wl-copy --type image/png < "$FILEPATH"
            notify_success "$FILEPATH" "🏛 Tangkapan Layar Area" "Tersimpan: $FILENAME\nDisalin ke papan klip."
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
            notify_success "$FILEPATH" "🏛 Tangkapan Layar Area" "Tersimpan: $FILENAME\nDisalin ke papan klip."
        fi
        ;;

    "delay")
        SEC="${2:-5}"
        if command -v notify-send >/dev/null 2>&1; then
            notify-send -a "School of Athens" "🏛 Tangkapan Layar Tunda" "Mengambil tangkapan layar dalam $SEC detik..." 2>/dev/null || true
        fi
        sleep "$SEC"
        grim "$FILEPATH"
        wl-copy --type image/png < "$FILEPATH"
        notify_success "$FILEPATH" "🏛 Tangkapan Layar Tunda" "Tersimpan: $FILENAME\nDisalin ke papan klip."
        ;;

    "menu"|*)
        SCRIPT_PATH="$(readlink -f "$0")"
        if [ -f "$HOME/.config/rofi/screenshot_menu.rasi" ]; then
            ROFI_THEME="$HOME/.config/rofi/screenshot_menu.rasi"
        elif [ -f "/usr/share/rinauby/rofi/screenshot_menu.rasi" ]; then
            ROFI_THEME="/usr/share/rinauby/rofi/screenshot_menu.rasi"
        elif [ -f "/home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/dotfiles/rofi/screenshot_menu.rasi" ]; then
            ROFI_THEME="/home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/dotfiles/rofi/screenshot_menu.rasi"
        else
            ROFI_THEME="$(cd "$(dirname "${BASH_SOURCE[0]}")/../rofi" 2>/dev/null && pwd)/screenshot_menu.rasi"
        fi

        OPTIONS="󰒆  Potong Area (Snip Selection)\n󰹑  Layar Penuh (Fullscreen)\n󱂬  Jendela Aktif (Active Window)\n󰏫  Potong & Anotasi (Swappy Editor)\n󱞩  Tunda 5 Detik (5s Delay Fullscreen)\n📁  Buka Folder Screenshots"

        CHOSEN=$(echo -e "$OPTIONS" | rofi -dmenu -theme "$ROFI_THEME" -p "📸" -no-custom)
        case "$CHOSEN" in
            *"Potong Area"*)
                exec "$SCRIPT_PATH" snip
                ;;
            *"Layar Penuh"*)
                exec "$SCRIPT_PATH" full
                ;;
            *"Jendela Aktif"*)
                exec "$SCRIPT_PATH" window
                ;;
            *"Potong & Anotasi"*)
                exec "$SCRIPT_PATH" edit
                ;;
            *"Tunda 5 Detik"*)
                exec "$SCRIPT_PATH" delay 5
                ;;
            *"Buka Folder"*)
                xdg-open "$TARGET_DIR" 2>/dev/null || thunar "$TARGET_DIR" 2>/dev/null &
                ;;
        esac
        ;;
esac
