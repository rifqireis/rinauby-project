#!/usr/bin/env bash

# ==============================================================================
# SCHOOL OF ATHENS : ROFI WALLPAPER SELECTOR
# Standardized Classical Art Selector (Faithful Mockup Layout)
# ==============================================================================

if [ -d "$HOME/.local/share/backgrounds/rinauby" ]; then
    WALL_DIR="$HOME/.local/share/backgrounds/rinauby"
elif [ -d "/usr/share/backgrounds/rinauby" ]; then
    WALL_DIR="/usr/share/backgrounds/rinauby"
elif [ -d "/home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/wallpapers" ]; then
    WALL_DIR="/home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/wallpapers"
else
    WALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../wallpapers" 2>/dev/null && pwd)"
fi

THUMB_DIR="$WALL_DIR/.thumbs"

if [ -f "$HOME/.config/rofi/wallpaper_grid.rasi" ]; then
    THEME_RASI="$HOME/.config/rofi/wallpaper_grid.rasi"
else
    THEME_RASI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/wallpaper_grid.rasi"
fi

if [ -f "$HOME/.config/waybar/quote_rotator.sh" ]; then
    QUOTE_ROTATOR="$HOME/.config/waybar/quote_rotator.sh"
elif command -v rinauby-quote >/dev/null 2>&1; then
    QUOTE_ROTATOR="rinauby-quote"
else
    QUOTE_ROTATOR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../waybar" 2>/dev/null && pwd)/quote_rotator.sh"
fi

if [ ! -d "$WALL_DIR" ]; then
    notify-send "Wallpaper Error" "Wallpaper directory not found: $WALL_DIR"
    exit 1
fi

mkdir -p "$THUMB_DIR"

# Definisi 8 karya seni klasik Renaissance persis urutan mockup
ITEMS=(
    "the_creation_of_adam:The Creation of Adam"
    "primavera:Primavera"
    "tower_of_babel:The Tower of Babel"
    "birth_of_venus:The Birth of Venus"
    "annunciation:The Annunciation"
    "the_last_supper:The Last Supper"
    "classical_ruins:Classical Ruins"
    "school_of_athens:The School of Athens"
)

ENTRY_LIST=""
for item in "${ITEMS[@]}"; do
    stem="${item%%:*}"
    title="${item#*:}"
    img="$WALL_DIR/${stem}.jpg"
    thumb="$THUMB_DIR/${stem}.jpg"

    [ -f "$img" ] || continue

    # Buat thumbnail jika belum ada
    if [ ! -f "$thumb" ]; then
        magick "$img" -resize 340x260^ -gravity center -extent 340x260 -quality 95 "$thumb" 2>/dev/null
    fi

    icon_to_use="$thumb"
    [ -f "$icon_to_use" ] || icon_to_use="$img"

    # Format Rofi dmenu: Title\0icon\x1fPath
    ENTRY_LIST+="$title\0icon\x1f$icon_to_use\n"
done

CHOSEN=$(echo -en "$ENTRY_LIST" | rofi -dmenu -theme "$THEME_RASI" -p "󰉋")

if [ -n "$CHOSEN" ]; then
    # Cari stem yang cocok dengan title
    selected_stem=""
    for item in "${ITEMS[@]}"; do
        stem="${item%%:*}"
        title="${item#*:}"
        if [ "$title" = "$CHOSEN" ] || [ "$stem" = "$CHOSEN" ]; then
            selected_stem="$stem"
            break
        fi
    done

    [ -z "$selected_stem" ] && selected_stem=$(echo "$CHOSEN" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
    SELECTED_PATH="$WALL_DIR/${selected_stem}.jpg"

    if [ -f "$SELECTED_PATH" ]; then
        # Simpan judul wallpaper aktif ke file state
        echo "$CHOSEN" > /tmp/current_wallpaper_title

        # Terapkan wallpaper ke Hyprland
        if command -v swww &>/dev/null; then
            swww img "$SELECTED_PATH" --transition-type wipe --transition-duration 1.5
        elif command -v hyprctl &>/dev/null && pgrep -x hyprpaper >/dev/null; then
            hyprctl hyprpaper preload "$SELECTED_PATH"
            hyprctl hyprpaper wallpaper ",$SELECTED_PATH"
            hyprctl hyprpaper unload all >/dev/null 2>&1
        elif command -v swaybg &>/dev/null; then
            pkill -x swaybg 2>/dev/null
            swaybg -i "$SELECTED_PATH" -m fill &
        fi

        # Rotasi semboyan Renaissance secara acak & refresh Waybar
        [ -x "$QUOTE_ROTATOR" ] && "$QUOTE_ROTATOR" --next >/dev/null 2>&1
        pkill -RTMIN+8 waybar 2>/dev/null || true
        pkill -USR1 -f window_title.py 2>/dev/null || true

        notify-send "School of Athens" "Wallpaper applied: $CHOSEN" -i "$SELECTED_PATH" 2>/dev/null || true
    fi
fi
