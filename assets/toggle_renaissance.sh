#!/usr/bin/env bash

# ==============================================================================
# RINAUBY : THEME & KEYBIND TOGGLER
# Mengalihkan desktop host antara mode normal dan Rinauby (Waybar Masterpiece)
# Tanpa merusak file konfigurasi asli apapun!
# ==============================================================================

STATE_FILE="/tmp/renaissance_mode_active"
TITLE_FILE="/tmp/current_wallpaper_title"
ASSETS_DIR="/home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets"
WAYBAR_CONF="$ASSETS_DIR/dotfiles/waybar/config.jsonc"
WAYBAR_STYLE="$ASSETS_DIR/dotfiles/waybar/style.css"
WALLPAPER="$ASSETS_DIR/wallpapers/school_of_athens.jpg"
OSD_SCRIPT="$ASSETS_DIR/dotfiles/scripts/osd.py"

enable_renaissance() {
    echo "🏛 Mengaktifkan Mode Rinauby..."

    # 1. Pasang Flag State Aktif & Judul Wallpaper Awal
    touch "$STATE_FILE"
    echo "The Rinauby" >"$TITLE_FILE"

    # 2. Matikan instance Quickshell & Waybar lama
    killall -9 qs quickshell 2>/dev/null
    pkill -x waybar 2>/dev/null

    # 3. Pasang Wallpaper Klasik Rinauby via swaybg
    pkill -x swaybg 2>/dev/null
    swaybg -i "$WALLPAPER" -m fill &

    # 4. Pastikan Notification Daemon (swaync) aktif untuk notifikasi & screenshot
    if ! pgrep -x swaync >/dev/null; then
        nohup swaync >/dev/null 2>&1 &
    else
        swaync-client -R -rs 2>/dev/null || true
    fi

    # 5. Nyalakan OSD Indicator Daemon (Volume & Brightness Pill Capsules)
    pkill -f "osd.py" 2>/dev/null
    python3 "$OSD_SCRIPT" daemon >/dev/null 2>&1 &

    # 6. Reload Hyprland untuk mengaktifkan keybinds & estetika Rinauby
    hyprctl reload 2>/dev/null

    # 7. Nyalakan Waybar Rinauby Masterpiece
    waybar -c "$WAYBAR_CONF" -s "$WAYBAR_STYLE" &

    # 8. Berikan notifikasi aktivasi
    notify-send "🏛 Rinauby" "Mode Digital Humanism Aktif!\n• Super+Space / Super+D : Application Launcher\n• Super+I : System Settings\n• Super+K / Ctrl+Super+T : Wallpaper Selector\n• Super+Backspace / Super+Esc : Session Controls\n• Super+L : Lock Screen\n• Super+A : Control Center\n• Super+Shift+S : Tangkapan Layar Area\nJalankan script lagi untuk kembali." -i "$WALLPAPER" 2>/dev/null || true
    echo "Mode Rinauby Aktif!"
}

disable_renaissance() {
    echo "🔄 Mengembalikan desktop ke profil semula..."

    # 1. Hapus Flag State & Judul Wallpaper
    rm -f "$STATE_FILE"
    rm -f "$TITLE_FILE"

    # 2. Matikan Waybar, swaybg, swaync, dan OSD daemon
    pkill -x waybar 2>/dev/null
    pkill -x swaybg 2>/dev/null
    pkill -x swaync 2>/dev/null
    python3 "$OSD_SCRIPT" quit 2>/dev/null || true
    pkill -f "osd.py" 2>/dev/null

    # 3. Hidupkan kembali Quickshell bawaan host
    qs -c ii -d &

    # 4. Reload config Hyprland asli
    hyprctl reload

    notify-send "Desktop Normal" "Desktop & keybinds telah dikembalikan ke konfigurasi asli." 2>/dev/null || true
    echo "Desktop telah dikembalikan!"
}

# Toggle Logic
if [ -f "$STATE_FILE" ]; then
    disable_renaissance
else
    enable_renaissance
fi
