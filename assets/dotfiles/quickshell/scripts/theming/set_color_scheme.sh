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
fi

# 6. Kirim notifikasi sistem
LABEL="$([ "$NEW_MODE" = "dark" ] && echo "Dark Mode" || echo "Light Mode")"
notify-send -a "System" "Skema Warna Diubah" "$LABEL aktif untuk GTK, Qt, dan Desktop" -i "preferences-desktop-theme" 2>/dev/null || true

