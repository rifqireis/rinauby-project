#!/usr/bin/env bash
# ==============================================================================
# RINAUBY : SYSTEM-WIDE DARK / LIGHT COLOR SCHEME SWITCHER
# Mengatur skema warna GTK, Libadwaita, Qt, dan Matugen secara serentak
# ==============================================================================

TARGET_MODE="$1"

# 1. Tentukan target mode jika "toggle" atau kosong
CURRENT_RAW="$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'")"
if [ "$TARGET_MODE" = "toggle" ] || [ -z "$TARGET_MODE" ]; then
    if [[ "$CURRENT_RAW" =~ "dark" ]]; then
        NEW_MODE="light"
    else
        NEW_MODE="dark"
    fi
else
    if [ "$TARGET_MODE" = "light" ]; then
        NEW_MODE="light"
    else
        NEW_MODE="dark"
    fi
fi

# 2. Terapkan ke FreeDesktop / GNOME / Libadwaita / Qt Portal (gsettings)
if [ "$NEW_MODE" = "dark" ]; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    GTK_THEME="catppuccin-mocha-blue-standard+default"
    ICON_THEME="Colloid-Dark"
    PREFER_DARK=1
else
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
    GTK_THEME="adw-gtk3"
    ICON_THEME="Colloid-Light"
    PREFER_DARK=0
fi

# Terapkan GTK Theme dan Icon Theme jika terpasang
gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null || true

# 3. Terapkan ke GTK 3 dan GTK 4 settings.ini
for CFG in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
    if [ -f "$CFG" ]; then
        sed -i "s/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=$PREFER_DARK/" "$CFG"
        sed -i "s/^gtk-theme-name=.*/gtk-theme-name=$GTK_THEME/" "$CFG"
        sed -i "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=$ICON_THEME/" "$CFG"
    fi
done

# 4. Simpan status ke state directory Quickshell & tmp
STATE_DIR="$HOME/.local/state/serpantinum"
mkdir -p "$STATE_DIR"
echo "$NEW_MODE" > "$STATE_DIR/color_scheme"
echo "$NEW_MODE" > /tmp/current_color_scheme

# 5. Sinkronisasi Tema Desktop Matugen jika dalam mode Modern
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
MATUGEN_SCRIPT="$SCRIPT_DIR/generate_matugen_palette.sh"
[ -x "$MATUGEN_SCRIPT" ] || MATUGEN_SCRIPT="$HOME/.config/quickshell/scripts/theming/generate_matugen_palette.sh"

WP_PATH=""
if [ -f /tmp/current_wallpaper_path ] && [ -s /tmp/current_wallpaper_path ]; then
    WP_PATH="$(cat /tmp/current_wallpaper_path)"
fi
if [ -z "$WP_PATH" ] || [ ! -f "$WP_PATH" ]; then
    WP_PATH="$(awww query 2>/dev/null | grep -o 'image: .*' | cut -d' ' -f2)"
fi
if [ -z "$WP_PATH" ] || [ ! -f "$WP_PATH" ]; then
    WP_PATH="$(swww query 2>/dev/null | grep -o 'image: .*' | cut -d' ' -f2)"
fi

CURRENT_THEME_MODE="$(cat /tmp/current_theme_mode 2>/dev/null || echo "modern")"
if [ "$CURRENT_THEME_MODE" = "modern" ] && [ -n "$WP_PATH" ] && [ -f "$WP_PATH" ] && [ -x "$MATUGEN_SCRIPT" ]; then
    "$MATUGEN_SCRIPT" "$WP_PATH" "$NEW_MODE" "scheme-fidelity" >/dev/null 2>&1 || true
elif [ "$CURRENT_THEME_MODE" = "classic" ]; then
    # Classic Renaissance: Dual-Mode (Light: Antique Parchment / Dark: Charcoal Ochre)
    # Catatan Desain (Aturan 10): Panel bar tetap permanen gelap (#1c2125), warna bar tidak diubah!
    if [ "$NEW_MODE" = "light" ]; then
        cat << 'EOF' > "$STATE_DIR/qs_colors.json"
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
        cat << 'EOF' > "$STATE_DIR/qs_bar_theme.json"
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
        cat << 'EOF' > "$STATE_DIR/qs_colors.json"
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
        cat << 'EOF' > "$STATE_DIR/qs_bar_theme.json"
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

    # Beritahu Quickshell untuk reload tema
    quickshell -p "$HOME/.config/quickshell/shell.qml" ipc call theme reloadColors 2>/dev/null || quickshell ipc call theme reloadColors 2>/dev/null || true
    quickshell -p "$HOME/.config/quickshell/shell.qml" ipc call waybar reload 2>/dev/null || quickshell ipc call waybar reload 2>/dev/null || true
fi

# 6. Kirim notifikasi sistem
LABEL="$([ "$NEW_MODE" = "dark" ] && echo "Dark Mode" || echo "Light Mode")"
notify-send -a "System" "Skema Warna Diubah" "$LABEL aktif untuk GTK, Qt, dan Desktop" -i "preferences-desktop-theme" 2>/dev/null || true

