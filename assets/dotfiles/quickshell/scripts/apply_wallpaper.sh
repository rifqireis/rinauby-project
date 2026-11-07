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

mkdir -p "$HOME/.local/state/serpantinum"

if [ "$THEME_MODE" = "modern" ]; then
    # Mode Modern Renaissance: Ekstraksi Dinamis Matugen (Monochromatic Harmony)
    if [ -x "$MATUGEN_SCRIPT" ] && [ "${RINAUBY_THEME_GENERATOR:-matugen}" = "matugen" ]; then
        CURRENT_SCHEME="$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'" | grep -o 'light\|dark' || echo 'dark')"
        "$MATUGEN_SCRIPT" "$SELECTED_PATH" "$CURRENT_SCHEME" "scheme-fidelity" || true
    else
        # Fallback Curated Modern Renaissance: Sapphire Cobalt Blue & Cyber Mocha
        hyprctl eval 'hl.config({ general = { col = { active_border = "rgba(89b4faff)", inactive_border = "rgba(242437aa)" } } })' 2>/dev/null || true
        kitty +kitten themes --reload-in=all "Catppuccin-Mocha" 2>/dev/null || true
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
        cat << 'EOF' > "$HOME/.local/state/serpantinum/qs_bar_theme.json"
{
  "themeMode": "modern",
  "barBg": "#11111b",
  "barBgAlpha": 0.85,
  "barFg": "#cdd6f4",
  "barFgBright": "#ffffff",
  "barBorderSide": "transparent",
  "barBorderBottom": "transparent",
  "accent": "#89b4fa",
  "accentGold": "#89b4fa",
  "wsActive": "#11111b",
  "wsInactive": "#6c7086",
  "wsHoverBg": "#89b4fa",
  "wsHoverBgAlpha": 0.14,
  "wsActiveBg": "#89b4fa",
  "wsActiveBgAlpha": 1.0,
  "sepColor": "#1fffffff",
  "tooltipBg": "#11111b",
  "tooltipBgAlpha": 0.95,
  "tooltipBorder": "#89b4fa",
  "tooltipBorderAlpha": 0.30,
  "windowTitleAppColor": "#ffffff",
  "mutedColor": "#f38ba8",
  "criticalColor": "#f38ba8",
  "rofiBgBase": "#181825",
  "rofiBgBaseAlpha": 0.96,
  "rofiBgInput": "#11111b",
  "rofiBgInputAlpha": 0.85,
  "rofiBgSelected": "#89b4fa",
  "rofiBgSelectedAlpha": 0.18,
  "rofiBorderSubtle": "#89b4fa",
  "rofiBorderSubtleAlpha": 0.18,
  "rofiBorderHairline": "#89b4fa",
  "rofiBorderHairlineAlpha": 0.08,
  "rofiAccent": "#89b4fa",
  "rofiAccentBright": "#74c7ec",
  "rofiFgMain": "#cdd6f4",
  "rofiFgBright": "#ffffff",
  "rofiFgMuted": "#6c7086"
}
EOF
    fi
else
    # Mode Classic Renaissance: Curated Warm Ochre Gold & Slate
    hyprctl eval 'hl.config({ general = { col = { active_border = "rgba(db9c5eff)", inactive_border = "rgba(42475399)" } } })' 2>/dev/null || true
    kitty +kitten themes --reload-in=all "Everforest Dark Hard" 2>/dev/null || true
    CURRENT_SCHEME="$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'" | grep -o 'light\|dark' || echo 'dark')"
    if [ "$CURRENT_SCHEME" = "light" ]; then
        cat << 'EOF' > "$HOME/.local/state/serpantinum/qs_colors.json"
{
  "base": "#fbf8f1",
  "mantle": "#f4ede0",
  "crust": "#eae1d0",
  "surface0": "#f3ede2",
  "surface1": "#ede5d6",
  "surface2": "#e2d8c5",
  "overlay0": "#baa990",
  "overlay1": "#8c7b64",
  "overlay2": "#6d5f4c",
  "text": "#2c2825",
  "subtext0": "#544c45",
  "subtext1": "#786d63",
  "blue": "#b87732",
  "sapphire": "#c98a44",
  "peach": "#b87732",
  "green": "#587c47",
  "red": "#b83a3a",
  "mauve": "#8f5832",
  "pink": "#c98a44",
  "yellow": "#c98a44",
  "maroon": "#8f3232",
  "teal": "#4d7c6e"
}
EOF
        cat << 'EOF' > "$HOME/.local/state/serpantinum/qs_bar_theme.json"
{
  "themeMode": "classic",
  "barBg": "#1c2125",
  "barBgAlpha": 0.82,
  "barFg": "#d3c6aa",
  "barFgBright": "#fbf2db",
  "barBorderSide": "#38b8864e",
  "barBorderBottom": "#db9c5e",
  "accent": "#db9c5e",
  "accentGold": "#e5c07b",
  "wsActive": "#e5c07b",
  "wsInactive": "#859289",
  "wsHoverBg": "#e5c07b",
  "wsHoverBgAlpha": 0.10,
  "wsActiveBg": "#e5c07b",
  "wsActiveBgAlpha": 0.15,
  "sepColor": "#4db8864e",
  "tooltipBg": "#181c1f",
  "tooltipBgAlpha": 0.95,
  "tooltipBorder": "#b8864e",
  "tooltipBorderAlpha": 0.45,
  "windowTitleAppColor": "#a7c080",
  "mutedColor": "#e67e80",
  "criticalColor": "#e67e80",
  "rofiBgBase": "#fbf8f1",
  "rofiBgBaseAlpha": 0.96,
  "rofiBgInput": "#f3ede2",
  "rofiBgInputAlpha": 0.85,
  "rofiBgSelected": "#b87732",
  "rofiBgSelectedAlpha": 0.15,
  "rofiBorderSubtle": "#baa990",
  "rofiBorderSubtleAlpha": 0.35,
  "rofiBorderHairline": "#baa990",
  "rofiBorderHairlineAlpha": 0.15,
  "rofiAccent": "#b87732",
  "rofiAccentBright": "#c98a44",
  "rofiFgMain": "#2c2825",
  "rofiFgBright": "#1f1c1a",
  "rofiFgMuted": "#786d63"
}
EOF
    else
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
        cat << 'EOF' > "$HOME/.local/state/serpantinum/qs_bar_theme.json"
{
  "themeMode": "classic",
  "barBg": "#1c2125",
  "barBgAlpha": 0.82,
  "barFg": "#d3c6aa",
  "barFgBright": "#fbf2db",
  "barBorderSide": "#38b8864e",
  "barBorderBottom": "#db9c5e",
  "accent": "#db9c5e",
  "accentGold": "#e5c07b",
  "wsActive": "#e5c07b",
  "wsInactive": "#859289",
  "wsHoverBg": "#e5c07b",
  "wsHoverBgAlpha": 0.10,
  "wsActiveBg": "#e5c07b",
  "wsActiveBgAlpha": 0.15,
  "sepColor": "#4db8864e",
  "tooltipBg": "#181c1f",
  "tooltipBgAlpha": 0.95,
  "tooltipBorder": "#b8864e",
  "tooltipBorderAlpha": 0.45,
  "windowTitleAppColor": "#a7c080",
  "mutedColor": "#e67e80",
  "criticalColor": "#e67e80",
  "rofiBgBase": "#161a1e",
  "rofiBgBaseAlpha": 0.96,
  "rofiBgInput": "#0e1114",
  "rofiBgInputAlpha": 0.85,
  "rofiBgSelected": "#db9c5e",
  "rofiBgSelectedAlpha": 0.14,
  "rofiBorderSubtle": "#ffffff",
  "rofiBorderSubtleAlpha": 0.05,
  "rofiBorderHairline": "#ffffff",
  "rofiBorderHairlineAlpha": 0.04,
  "rofiAccent": "#db9c5e",
  "rofiAccentBright": "#e5c07b",
  "rofiFgMain": "#d3c6aa",
  "rofiFgBright": "#fbf2db",
  "rofiFgMuted": "#859289"
}
EOF
    fi
fi

# 4. Rotasi Kutipan & Motto
if [ -f "$HOME/.config/scripts/quote_rotator.sh" ]; then
    bash "$HOME/.config/scripts/quote_rotator.sh" --next >/dev/null 2>&1
elif command -v rinauby-quote >/dev/null 2>&1; then
    rinauby-quote --next >/dev/null 2>&1
elif [ -f "$(dirname "${BASH_SOURCE[0]}")/../../scripts/quote_rotator.sh" ]; then
    bash "$(dirname "${BASH_SOURCE[0]}")/../../scripts/quote_rotator.sh" --next >/dev/null 2>&1
fi

# 5. Reload Warna & TopBar Quickshell (IPC)
quickshell -c rs ipc call theme reloadColors 2>/dev/null || quickshell -p "$HOME/.config/quickshell/shell.qml" ipc call theme reloadColors 2>/dev/null || quickshell ipc call theme reloadColors 2>/dev/null || true
quickshell -c rs ipc call rinaubybar reload 2>/dev/null || quickshell -c rs ipc call waybar reload 2>/dev/null || quickshell -p "$HOME/.config/quickshell/shell.qml" ipc call waybar reload 2>/dev/null || quickshell ipc call waybar reload 2>/dev/null || true

# 6. Notifikasi Sukses
if [ "$THEME_MODE" = "modern" ]; then
    notify-send -a "System" "Tema Modern Diaktifkan" "$CHOSEN · Monochromatic Matugen Dynamic" -i "$SELECTED_PATH" 2>/dev/null || true
else
    notify-send -a "System" "Tema Klasik Diaktifkan" "$CHOSEN · Ochre Gold & Warm Parchment" -i "$SELECTED_PATH" 2>/dev/null || true
fi
