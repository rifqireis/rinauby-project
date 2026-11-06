#!/usr/bin/env bash

# ==============================================================================
# RINAUBY : DUAL-THEME WALLPAPER & COLOR PALETTE APPLIER
# Digital Humanism Edition: Classic Renaissance vs Modern Renaissance
# ==============================================================================

SELECTED_PATH="$(readlink -f "$1")"
[ -f "$SELECTED_PATH" ] || exit 1

FILENAME="$(basename "$SELECTED_PATH")"
STEM="${FILENAME%.*}"

# 1. Klasifikasi Wallpaper & Judul Karya Seni
case "$STEM" in
    neo_renaissance_nocturne)
        CHOSEN="The Nocturne Citadel"
        THEME_MODE="modern"
        ;;
    midnight_cyber_warrior)
        CHOSEN="Midnight Cyber Warrior"
        THEME_MODE="modern"
        ;;
    starry_night_over_the_rhone|starry_night)
        CHOSEN="Starry Night Over the Rhône"
        THEME_MODE="modern"
        ;;
    apotheosis)
        CHOSEN="The Apotheosis"
        THEME_MODE="classic"
        ;;
    school_of_athens)
        CHOSEN="The School of Athens"
        THEME_MODE="classic"
        ;;
    the_creation_of_adam|creation_of_adam)
        CHOSEN="The Creation of Adam"
        THEME_MODE="classic"
        ;;
    the_last_supper|last_supper)
        CHOSEN="The Last Supper"
        THEME_MODE="classic"
        ;;
    birth_of_venus)
        CHOSEN="The Birth of Venus"
        THEME_MODE="classic"
        ;;
    primavera)
        CHOSEN="Primavera"
        THEME_MODE="classic"
        ;;
    tower_of_babel)
        CHOSEN="The Tower of Babel"
        THEME_MODE="classic"
        ;;
    annunciation)
        CHOSEN="The Annunciation"
        THEME_MODE="classic"
        ;;
    *)
        CHOSEN="$(echo "$STEM" | sed -r 's/(^|_)([a-z])/\U\2/g' | tr '_' ' ')"
        if [[ "$STEM" =~ (modern|cyber|cobalt|neon|midnight) ]]; then
            THEME_MODE="modern"
        else
            THEME_MODE="classic"
        fi
        ;;
esac

echo "$SELECTED_PATH" > /tmp/current_wallpaper_path
echo "$CHOSEN" > /tmp/current_wallpaper_title
echo "$THEME_MODE" > /tmp/current_theme_mode

# 2. Terapkan Wallpaper ke Hyprland dengan Animasi Circular Reveal (swww)
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

# 3. Sinkronisasi Palet Warna (Dynamic Matugen vs Curated Classic)
MATUGEN_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)/theming/generate_matugen_palette.sh"
[ -x "$MATUGEN_SCRIPT" ] || MATUGEN_SCRIPT="$HOME/.config/quickshell/scripts/theming/generate_matugen_palette.sh"

WAYBAR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../waybar" 2>/dev/null && pwd)"
[ -d "$WAYBAR_DIR" ] || WAYBAR_DIR="$HOME/.config/waybar"
mkdir -p "$HOME/.config/waybar" "$HOME/.config/rofi" "$HOME/.local/state/serpantinum"

if [ "$THEME_MODE" = "modern" ]; then
    # Mode Modern Renaissance: Ekstraksi Dinamis Matugen (Monochromatic Harmony)
    if [ -x "$MATUGEN_SCRIPT" ] && [ "${RINAUBY_THEME_GENERATOR:-matugen}" = "matugen" ]; then
        CURRENT_SCHEME="$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'" | grep -o 'light\|dark' || echo 'dark')"
        "$MATUGEN_SCRIPT" "$SELECTED_PATH" "$CURRENT_SCHEME" "scheme-fidelity" || true
    else
        # Fallback Curated Modern Renaissance: Sapphire Cobalt Blue & Cyber Mocha
        hyprctl eval 'hl.config({ general = { col = { active_border = "rgba(89b4faff)", inactive_border = "rgba(242437aa)" } } })' 2>/dev/null || true
        kitty +kitten themes --reload-in=all "Catppuccin-Mocha" 2>/dev/null || true
        cat << 'EOF' > "$HOME/.config/waybar/theme.css"
/* Waybar Theme: Modern Renaissance (Cobalt Blue & Cyber Mocha) */
@define-color bar_bg rgba(17, 17, 27, 0.85);
@define-color bar_fg #cdd6f4;
@define-color bar_fg_bright #ffffff;
@define-color bar_border_side transparent;
@define-color bar_border_bottom transparent;
@define-color accent #89b4fa;
@define-color accent_gold #89b4fa;
@define-color ws_active #11111b;
@define-color ws_inactive #6c7086;
@define-color ws_hover_bg rgba(137, 180, 250, 0.14);
@define-color ws_active_bg #89b4fa;
@define-color sep_color rgba(255, 255, 255, 0.12);
@define-color tooltip_bg rgba(17, 17, 27, 0.95);
@define-color tooltip_border rgba(137, 180, 250, 0.30);
EOF
        cat << 'EOF' > "$HOME/.config/rofi/theme_colors.rasi"
/* Rofi Theme: Modern Renaissance (Cobalt Blue & Cyber Mocha) */
* {
    bg-base: rgba(24, 24, 37, 0.96);
    bg-input: rgba(17, 17, 27, 0.85);
    bg-selected: rgba(137, 180, 250, 0.18);
    border-subtle: rgba(137, 180, 250, 0.18);
    border-hairline: rgba(137, 180, 250, 0.08);
    accent-gold: #89b4fa;
    accent-gold-bright: #74c7ec;
    fg-main: #cdd6f4;
    fg-bright: #ffffff;
    fg-muted: #6c7086;
}
EOF
        cat << 'EOF' > "$HOME/.local/state/serpantinum/qs_colors.json"
{
  "base": "#181825",
  "mantle": "#11111b",
  "crust": "#0e0e16",
  "surface0": "#252739",
  "surface1": "#313244",
  "surface2": "#45475a",
  "overlay0": "#6c7086",
  "overlay1": "#7f849c",
  "overlay2": "#9399b2",
  "text": "#cdd6f4",
  "subtext0": "#a6adc8",
  "subtext1": "#bac2de",
  "blue": "#89b4fa",
  "sapphire": "#74c7ec",
  "peach": "#fab387",
  "green": "#a6e3a1",
  "red": "#f38ba8",
  "mauve": "#cba6f7",
  "pink": "#f5c2e7",
  "yellow": "#f9e2af",
  "maroon": "#eba0ac",
  "teal": "#94e2d5"
}
EOF
    fi

    if [ -f "$WAYBAR_DIR/config-modern.jsonc" ]; then
        cp -f "$WAYBAR_DIR/config-modern.jsonc" "$HOME/.config/waybar/config.jsonc"
    fi
    if [ -f "$WAYBAR_DIR/style-modern.css" ]; then
        cp -f "$WAYBAR_DIR/style-modern.css" "$HOME/.config/waybar/style.css"
    fi
else
    # Mode Classic Renaissance: Curated Warm Ochre Gold & Slate
    hyprctl eval 'hl.config({ general = { col = { active_border = "rgba(db9c5eff)", inactive_border = "rgba(42475399)" } } })' 2>/dev/null || true
    kitty +kitten themes --reload-in=all "Everforest Dark Hard" 2>/dev/null || true
    cat << 'EOF' > "$HOME/.config/waybar/theme.css"
/* Waybar Theme: Classic Renaissance (Ochre Gold & Parchment) */
@define-color bar_bg rgba(28, 33, 37, 0.82);
@define-color bar_fg #d3c6aa;
@define-color bar_fg_bright #fbf2db;
@define-color bar_border_side rgba(184, 134, 78, 0.22);
@define-color bar_border_bottom #db9c5e;
@define-color accent #db9c5e;
@define-color accent_gold #e5c07b;
@define-color ws_active #e5c07b;
@define-color ws_inactive #859289;
@define-color ws_hover_bg rgba(229, 192, 123, 0.10);
@define-color ws_active_bg rgba(229, 192, 123, 0.15);
@define-color sep_color rgba(184, 134, 78, 0.30);
@define-color tooltip_bg rgba(24, 28, 31, 0.95);
@define-color tooltip_border rgba(184, 134, 78, 0.45);
EOF
    cat << 'EOF' > "$HOME/.config/rofi/theme_colors.rasi"
/* Rofi Theme: Classic Renaissance (Ochre Gold & Parchment) */
* {
    bg-base: rgba(22, 26, 30, 0.96);
    bg-input: rgba(14, 17, 20, 0.85);
    bg-selected: rgba(219, 156, 94, 0.14);
    border-subtle: rgba(255, 255, 255, 0.05);
    border-hairline: rgba(255, 255, 255, 0.04);
    accent-gold: #db9c5e;
    accent-gold-bright: #e5c07b;
    fg-main: #d3c6aa;
    fg-bright: #fbf2db;
    fg-muted: #859289;
}
EOF
    cat << 'EOF' > "$HOME/.local/state/serpantinum/qs_colors.json"
{
  "base": "#171a1d",
  "mantle": "#131518",
  "crust": "#0e1012",
  "surface0": "#202429",
  "surface1": "#262a30",
  "surface2": "#30363d",
  "overlay0": "#424a53",
  "overlay1": "#58626e",
  "overlay2": "#6e7a88",
  "text": "#fbf2db",
  "subtext0": "#d3c6aa",
  "subtext1": "#959c9e",
  "blue": "#db9c5e",
  "sapphire": "#e5c07b",
  "peach": "#db9c5e",
  "green": "#a7c080",
  "red": "#e67e80",
  "mauve": "#c87d46",
  "pink": "#e5c07b",
  "yellow": "#e5c07b",
  "maroon": "#c85552",
  "teal": "#879a39"
}
EOF
    if [ -f "$WAYBAR_DIR/config-classic.jsonc" ]; then
        cp -f "$WAYBAR_DIR/config-classic.jsonc" "$HOME/.config/waybar/config.jsonc"
    fi
    if [ -f "$WAYBAR_DIR/style-classic.css" ]; then
        cp -f "$WAYBAR_DIR/style-classic.css" "$HOME/.config/waybar/style.css"
    fi
fi

# 4. Rotasi Kutipan & Motto Waybar
if [ -f "$HOME/.config/waybar/quote_rotator.sh" ]; then
    bash "$HOME/.config/waybar/quote_rotator.sh" --next >/dev/null 2>&1
elif command -v rinauby-quote >/dev/null 2>&1; then
    rinauby-quote --next >/dev/null 2>&1
fi

# 5. Restart Waybar dengan Konfigurasi yang Sesuai
pkill -x waybar 2>/dev/null || true
sleep 0.1
setsid -f waybar -c "$HOME/.config/waybar/config.jsonc" -s "$HOME/.config/waybar/style.css" >/dev/null 2>&1

# 6. Reload Warna Quickshell (IPC & Signal)
quickshell -p "$HOME/.config/quickshell/shell.qml" ipc call theme reloadColors 2>/dev/null || quickshell ipc call theme reloadColors 2>/dev/null || true
pkill -USR1 -f window_title.py 2>/dev/null || true

# 9. Notifikasi Sukses
if [ "$THEME_MODE" = "modern" ]; then
    notify-send -a "System" "Tema Modern Diaktifkan" "$CHOSEN · Monochromatic Matugen Dynamic" -i "$SELECTED_PATH" 2>/dev/null || true
else
    notify-send -a "System" "Tema Klasik Diaktifkan" "$CHOSEN · Ochre Gold & Warm Parchment" -i "$SELECTED_PATH" 2>/dev/null || true
fi
