#!/usr/bin/env bash
# ==============================================================================
# RINAUBY (DIGITAL HUMANISM EDITION) — UBUNTU 26.04 / 24.04 MASTER INSTALLER
# Tugas Besar Praktikum Sistem Operasi 2026 (Remastering Ubuntu via Cubic)
# ==============================================================================
# Script ini dirancang untuk dijalankan:
#   1. Di dalam terminal Chroot Cubic (sebagai root) saat remastering ISO, ATAU
#   2. Di dalam mesin virtual Ubuntu 26.04 / 24.04 (via: sudo ./install.sh)
#
# Fitur Utama:
#   - Mengaktifkan repositori Ubuntu (universe, multiverse, restricted)
#   - Menginstal Hyprland, Waybar, Rofi, SwayNC, Hyprlock, Kitty, Fastfetch,
#     serta seluruh dependensi GTK4/Libadwaita (rinauby-settings) & Layer-Shell (OSD)
#   - Memasang font klasik (Cinzel, EB Garamond, JetBrains Mono, Symbols Nerd Font)
#   - Memasang 8 lukisan klasik Renaissance (1920x1200 + thumbnails)
#   - Memasang binary wrapper `rinauby-*` ke /usr/local/bin/
#   - Menyebarkan dotfiles ke /etc/skel/.config/ dan user aktif dengan sanitasi path
#   - Mengonfigurasi PAM Ubuntu (/etc/pam.d/hyprlock), Wayland session,
#     proteksi anti-black-screen VirtualBox, Display Manager, & identitas distro
# ==============================================================================

set -uo pipefail

# ------------------------------------------------------------------------------
# 0. KONFIGURASI WARNA LOG & LOKASI DIREKTORI
# ------------------------------------------------------------------------------
C_RESET='\033[0m'
C_GOLD='\033[1;33m'
C_GREEN='\033[1;32m'
C_BLUE='\033[1;34m'
C_RED='\033[1;31m'

log_info()  { echo -e "${C_BLUE}[INFO]${C_RESET} $*"; }
log_step()  { echo -e "\n${C_GOLD}==============================================================================${C_RESET}"; echo -e "${C_GOLD}>> $*${C_RESET}"; echo -e "${C_GOLD}==============================================================================${C_RESET}"; }
log_ok()    { echo -e "${C_GREEN}[OK]${C_RESET} $*"; }
log_warn()  { echo -e "${C_GOLD}[WARN]${C_RESET} $*"; }
log_err()   { echo -e "${C_RED}[ERROR]${C_RESET} $*" >&2; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/assets"
DOTFILES_DIR="$ASSETS_DIR/dotfiles"
WALLPAPERS_DIR="$ASSETS_DIR/wallpapers"
FONTS_DIR="$ASSETS_DIR/fonts"
BIN_DIR="$ASSETS_DIR/bin"

HOST_HARDCODED_PREFIX="/home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets"

# ==============================================================================
# SAFEGUARD MUTLAK: CEK DISTRIBUSI (DILARANG BERJALAN DI HOST ARCH LINUX!)
# ==============================================================================
if [ -f /etc/os-release ]; then
    OS_ID="$(grep -E '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')"
    OS_LIKE="$(grep -E '^ID_LIKE=' /etc/os-release | cut -d= -f2 | tr -d '"')"
    OS_NAME="$(grep -E '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')"

    if [ "$OS_ID" = "arch" ] || [[ "$OS_LIKE" == *"arch"* ]]; then
        echo -e "${C_RED}==============================================================================${C_RESET}"
        echo -e "${C_RED}[FATAL ERROR] TERDETEKSI SISTEM OPERASI ARCH LINUX HOST (${OS_NAME})!${C_RESET}"
        echo -e "${C_RED}Script ini KHUSUS untuk remastering Ubuntu di dalam Chroot Cubic atau VM Ubuntu!${C_RESET}"
        echo -e "${C_RED}Eksekusi DIBATALKAN seketika demi melindungi dotfiles & sistem host Anda.${C_RESET}"
        echo -e "${C_RED}==============================================================================${C_RESET}"
        exit 1
    fi

    if [ "$OS_ID" != "ubuntu" ] && [ "$OS_ID" != "debian" ] && [[ "$OS_LIKE" != *"ubuntu"* ]] && [[ "$OS_LIKE" != *"debian"* ]]; then
        echo -e "${C_RED}[FATAL ERROR] Sistem operasi bukan Ubuntu/Debian (${OS_NAME:-$OS_ID}). Dibatalkan!${C_RESET}"
        exit 1
    fi
fi

if ! command -v apt-get >/dev/null 2>&1; then
    echo -e "${C_RED}[FATAL ERROR] Perintah 'apt-get' tidak ditemukan di sistem ini! Dibatalkan.${C_RESET}"
    exit 1
fi

# Pastikan dijalankan sebagai root / sudo
if [ "$(id -u)" -ne 0 ]; then
    log_err "Script ini harus dijalankan sebagai root! Gunakan: sudo ./install.sh"
    exit 1
fi

# Pastikan folder assets ditemukan
if [ ! -d "$DOTFILES_DIR" ]; then
    log_err "Direktori '$DOTFILES_DIR' tidak ditemukan. Jalankan script ini dari root folder proyek Rancangan!"
    exit 1
fi

# Deteksi apakah berjalan di dalam Chroot (seperti Cubic)
IS_CHROOT=0
if [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/. 2>/dev/null || echo 0:0)" ]; then
    IS_CHROOT=1
    log_info "Lingkungan Chroot (Cubic) terdeteksi."
else
    log_info "Lingkungan sistem Ubuntu aktif (VM/Host) terdeteksi."
fi

export DEBIAN_FRONTEND=noninteractive

# ------------------------------------------------------------------------------
# 1. KONFIGURASI REPOSITORI UBUNTU 26.04 / 24.04
# ------------------------------------------------------------------------------
log_step "TAHAP 1: Menyiapkan Repositori Ubuntu (Universe, Multiverse, Restricted)"

apt-get update -y || true
apt-get install -y software-properties-common ca-certificates curl wget gnupg lsb-release apt-transport-https

add-apt-repository -y universe || true
add-apt-repository -y multiverse || true
add-apt-repository -y restricted || true
apt-get update -y

UBUNTU_CODENAME="$(lsb_release -cs 2>/dev/null || echo "resolute")"
UBUNTU_RELEASE="$(lsb_release -rs 2>/dev/null || echo "26.04")"
log_info "Target Distribusi: Ubuntu $UBUNTU_RELEASE ($UBUNTU_CODENAME)"

# Fungsi helper untuk menginstal daftar paket secara tangguh (tidak gagal total jika 1 paket opsional absen)
install_packages() {
    local pkgs=("$@")
    local available_pkgs=()
    local missing_pkgs=()

    for pkg in "${pkgs[@]}"; do
        if apt-cache show "$pkg" >/dev/null 2>&1; then
            available_pkgs+=("$pkg")
        else
            missing_pkgs+=("$pkg")
        fi
    done

    if [ "${#available_pkgs[@]}" -gt 0 ]; then
        log_info "Menginstal paket: ${available_pkgs[*]}"
        if ! apt-get install -y --no-install-recommends "${available_pkgs[@]}"; then
            log_warn "Terjadi kendala batch install, mencoba instalasi satu per satu..."
            for pkg in "${available_pkgs[@]}"; do
                apt-get install -y --no-install-recommends "$pkg" || log_warn "Gagal menginstal paket: $pkg"
            done
        fi
    fi

    if [ "${#missing_pkgs[@]}" -gt 0 ]; then
        log_warn "Paket berikut tidak ditemukan di cache APT saat ini (dilewati/fallback): ${missing_pkgs[*]}"
    fi
}

# ------------------------------------------------------------------------------
# 2. INSTALASI HYPRLAND & KOMPONEN WAYLAND COMPOSITOR
# ------------------------------------------------------------------------------
log_step "TAHAP 2: Menginstal Hyprland & Ekosistem Wayland"

# Cek ketersediaan hyprland di repositori resmi Ubuntu (Universe sudah aktif)
if ! apt-cache show hyprland >/dev/null 2>&1; then
    # Hanya tambahkan PPA fallback jika di Ubuntu 24.04 (noble); di 26.10 hyprland ada di repo universe
    if [ "$UBUNTU_CODENAME" = "noble" ]; then
        log_warn "Hyprland belum ditemukan di repo standar, menambahkan PPA fallback untuk $UBUNTU_CODENAME..."
        add-apt-repository -y ppa:cppiber/hyprland 2>/dev/null || true
        apt-get update -y || true
    fi
fi

WAYLAND_PKGS=(
    hyprland
    hyprlock
    hypridle
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    xdg-desktop-portal
    xwayland
    wl-clipboard
    cliphist
    swaybg
    swaylock
    swayidle
    gtklock
    qtwayland5
    qt6-wayland
    libwayland-client0
    libwayland-cursor0
    libwayland-egl1
    libegl-mesa0
    libgl1-mesa-dri
    mesa-utils
)
install_packages "${WAYLAND_PKGS[@]}"

# ------------------------------------------------------------------------------
# 3. INSTALASI PANEL (WAYBAR), LAUNCHER (ROFI), NOTIFIKASI (SWAYNC) & POLKIT
# ------------------------------------------------------------------------------
log_step "TAHAP 3: Menginstal Waybar, Rofi, SwayNC, & Polkit Agent"

SHELL_PKGS=(
    waybar
    sway-notification-center
    libnotify-bin
    polkit-gnome
    policykit-1-gnome
    polkitd
    dbus-x11
    network-manager
    network-manager-gnome
    bluez
    blueman
    upower
)
install_packages "${SHELL_PKGS[@]}"

# Rofi di Ubuntu 26.04 sudah mendukung Wayland secara bawaan (atau lewat paket rofi-wayland)
if apt-cache show rofi-wayland >/dev/null 2>&1; then
    install_packages rofi-wayland
else
    install_packages rofi
fi

# ------------------------------------------------------------------------------
# 4. INSTALASI PYTHON GTK4 / LIBADWAITA (SETTINGS) & GTK3 LAYER-SHELL (OSD)
# ------------------------------------------------------------------------------
log_step "TAHAP 4: Menginstal Dependensi Python GTK4/Libadwaita & GTK Layer-Shell"

GTK_PYTHON_PKGS=(
    python3
    python3-gi
    python3-gi-cairo
    python3-cairo
    python3-dbus
    gir1.2-gtk-4.0
    gir1.2-adw-1
    libadwaita-1-0
    gir1.2-gtk-3.0
    gir1.2-gtklayershell-0.1
    libgtk-layer-shell0
    gir1.2-gdkpixbuf-2.0
    gir1.2-pango-1.0
    gir1.2-glib-2.0
    gir1.2-nm-1.0
    gsettings-desktop-schemas
    dconf-cli
    libglib2.0-bin
)
install_packages "${GTK_PYTHON_PKGS[@]}"

# ------------------------------------------------------------------------------
# 5. INSTALASI TERMINAL, SCREENSHOT, AUDIO, MULTIMEDIA & UTILITAS SISTEM
# ------------------------------------------------------------------------------
log_step "TAHAP 5: Menginstal Kitty, Fastfetch, Screenshot Tools, Audio & Aplikasi Pendukung"

UTILITY_PKGS=(
    kitty
    fastfetch
    grim
    slurp
    swappy
    jq
    imagemagick
    brightnessctl
    pamixer
    playerctl
    pavucontrol
    pulseaudio-utils
    wireplumber
    pipewire-pulse
    alsa-utils
    thunar
    thunar-archive-plugin
    file-roller
    imv
    zathura
    papirus-icon-theme
    adwaita-icon-theme
    bibata-cursor-theme
    fontconfig
    unzip
    git
    pciutils
    psmisc
    procps
    virtualbox-guest-utils
    virtualbox-guest-x11
    xdg-utils
    lua5.4
    plymouth
    plymouth-themes
)
install_packages "${UTILITY_PKGS[@]}"

# Fallback jika fastfetch belum ada di repositori APT
if ! command -v fastfetch >/dev/null 2>&1; then
    log_info "Mengunduh paket Fastfetch (.deb) resmi dari GitHub Releases..."
    ARCH_DEB="$(dpkg --print-architecture 2>/dev/null || echo "amd64")"
    FF_URL="https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-${ARCH_DEB}.deb"
    if curl -fsSL "$FF_URL" -o /tmp/fastfetch.deb; then
        dpkg -i /tmp/fastfetch.deb || apt-get install -f -y
        rm -f /tmp/fastfetch.deb
        log_ok "Fastfetch berhasil dipasang dari rilis resmi."
    else
        log_warn "Gagal mengunduh fastfetch.deb; pastikan koneksi internet aktif."
    fi
fi

# ------------------------------------------------------------------------------
# 6. INSTALASI TIPOGRAFI (CINZEL, EB GARAMOND, INTER, JETBRAINS MONO & NERD FONT)
# ------------------------------------------------------------------------------
log_step "TAHAP 6: Memasang Font Sistem & Bundel Font Klasik Rinauby"

FONT_PKGS=(
    fonts-ebgaramond
    fonts-ebgaramond-extra
    fonts-jetbrains-mono
    fonts-inter
    fonts-font-awesome
    fonts-dejavu-core
)
install_packages "${FONT_PKGS[@]}"

SYS_FONT_DIR="/usr/local/share/fonts/rinauby"
mkdir -p "$SYS_FONT_DIR"

if [ -d "$FONTS_DIR" ]; then
    cp -rf "$FONTS_DIR"/*.ttf "$SYS_FONT_DIR/" 2>/dev/null || true
    cp -rf "$FONTS_DIR"/*.otf "$SYS_FONT_DIR/" 2>/dev/null || true
    chmod 644 "$SYS_FONT_DIR"/* 2>/dev/null || true
    log_ok "Font bundel (Cinzel & Symbols Nerd Font Mono) disalin ke $SYS_FONT_DIR"
fi

# Buat konfigurasi alias Fontconfig agar permintaan 'JetBrainsMono Nerd Font' atau
# 'Iosevka Nerd Font' otomatis memadukan JetBrains Mono + Symbols Nerd Font Mono
cat << 'EOF' > /etc/fonts/conf.d/60-rinauby-fonts.conf
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <alias>
    <family>JetBrainsMono Nerd Font</family>
    <prefer>
      <family>JetBrains Mono</family>
      <family>Symbols Nerd Font Mono</family>
      <family>Symbols Nerd Font</family>
    </prefer>
  </alias>
  <alias>
    <family>Iosevka Nerd Font</family>
    <prefer>
      <family>JetBrains Mono</family>
      <family>Symbols Nerd Font Mono</family>
      <family>Symbols Nerd Font</family>
    </prefer>
  </alias>
  <alias>
    <family>monospace</family>
    <prefer>
      <family>JetBrains Mono</family>
      <family>Symbols Nerd Font Mono</family>
    </prefer>
  </alias>
</fontconfig>
EOF

fc-cache -fv >/dev/null 2>&1 || true
log_ok "Cache font sistem berhasil diperbarui."

# ------------------------------------------------------------------------------
# 7. DEPLOYMENT WALLPAPER KLASIK & ASET GLOBAL (/usr/share/backgrounds/rinauby)
# ------------------------------------------------------------------------------
log_step "TAHAP 7: Memasang Galeri Wallpaper Klasik & Aset Sistem Rinauby"

SYS_WALL_DIR="/usr/share/backgrounds/rinauby"
SYS_SHARE_DIR="/usr/share/rinauby"

mkdir -p "$SYS_WALL_DIR/.thumbs"
mkdir -p "$SYS_SHARE_DIR"

if [ -d "$WALLPAPERS_DIR" ]; then
    cp -f "$WALLPAPERS_DIR"/*.jpg "$SYS_WALL_DIR/" 2>/dev/null || true
    if [ -d "$WALLPAPERS_DIR/.thumbs" ]; then
        cp -f "$WALLPAPERS_DIR/.thumbs"/*.jpg "$SYS_WALL_DIR/.thumbs/" 2>/dev/null || true
    fi
    chmod -R 755 "$SYS_WALL_DIR"
    log_ok "8 Lukisan klasik Renaissance + thumbnails terpasang di $SYS_WALL_DIR"
fi

# Generate thumbnail yang belum ada jika imagemagick tersedia
if command -v magick >/dev/null 2>&1 || command -v convert >/dev/null 2>&1; then
    IMG_CMD="convert"
    command -v magick >/dev/null 2>&1 && IMG_CMD="magick"
    for img in "$SYS_WALL_DIR"/*.jpg; do
        [ -f "$img" ] || continue
        base="$(basename "$img")"
        thumb="$SYS_WALL_DIR/.thumbs/$base"
        if [ ! -f "$thumb" ]; then
            "$IMG_CMD" "$img" -resize 340x260^ -gravity center -extent 340x260 -quality 92 "$thumb" 2>/dev/null || true
        fi
    done
fi

# Buat avatar fallback klasik untuk Hyprlock
mkdir -p "$SYS_SHARE_DIR/hypr"
if command -v magick >/dev/null 2>&1 || command -v convert >/dev/null 2>&1; then
    IMG_CMD="convert"
    command -v magick >/dev/null 2>&1 && IMG_CMD="magick"
    if [ -f "$SYS_WALL_DIR/school_of_athens.jpg" ]; then
        "$IMG_CMD" "$SYS_WALL_DIR/school_of_athens.jpg" -gravity center -crop 400x400+0+0 +repage -resize 180x180 "$SYS_SHARE_DIR/hypr/avatar.png" 2>/dev/null || true
    fi
fi

# Salin seluruh komponen dotfiles ke /usr/share/rinauby sebagai referensi global
cp -rf "$DOTFILES_DIR"/* "$SYS_SHARE_DIR/"
find "$SYS_SHARE_DIR" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# Sanitasi path hardcoded host Arch di dalam /usr/share/rinauby
find "$SYS_SHARE_DIR" -type f \( -name "*.conf" -o -name "*.jsonc" -o -name "*.json" -o -name "*.rasi" -o -name "*.sh" -o -name "*.py" -o -name "*.css" \) \
    -exec sed -i \
    -e "s|$HOST_HARDCODED_PREFIX/wallpapers|$SYS_WALL_DIR|g" \
    -e "s|$HOST_HARDCODED_PREFIX/dotfiles|$SYS_SHARE_DIR|g" \
    -e "s|/home/rifqi/.config/hypr/hyprlock/avatar-kde.png|$SYS_SHARE_DIR/hypr/avatar.png|g" \
    {} + 2>/dev/null || true

# ------------------------------------------------------------------------------
# 8. PEMASANGAN BINARY WRAPPER (rinauby-*) & DESKTOP ENTRY
# ------------------------------------------------------------------------------
log_step "TAHAP 8: Memasang Binary Wrapper (/usr/local/bin/rinauby-*) & Aplikasi Desktop"

mkdir -p /usr/local/bin
if [ -d "$BIN_DIR" ]; then
    cp -f "$BIN_DIR"/rinauby-* /usr/local/bin/
    chmod 755 /usr/local/bin/rinauby-*
    sed -i \
        -e "s|$HOST_HARDCODED_PREFIX/wallpapers|$SYS_WALL_DIR|g" \
        -e "s|$HOST_HARDCODED_PREFIX/dotfiles|$SYS_SHARE_DIR|g" \
        /usr/local/bin/rinauby-* 2>/dev/null || true
    log_ok "Seluruh wrapper rinauby-* terpasang di /usr/local/bin/ (path disanitasi)"
fi

# Pastikan seluruh script eksekusi di /usr/share/rinauby memiliki izin +x
chmod +x "$SYS_SHARE_DIR/waybar/quote_rotator.sh" 2>/dev/null || true
chmod +x "$SYS_SHARE_DIR/waybar/window_title.py" 2>/dev/null || true
chmod +x "$SYS_SHARE_DIR/rofi/wp_selector.sh" 2>/dev/null || true
chmod +x "$SYS_SHARE_DIR/scripts/"*.sh 2>/dev/null || true
chmod +x "$SYS_SHARE_DIR/scripts/"*.py 2>/dev/null || true
chmod +x "$SYS_SHARE_DIR/settings-gtk/main.py" 2>/dev/null || true

# Buat Desktop Entry untuk Rinauby Settings agar muncul di Rofi Launcher
mkdir -p /usr/share/applications
cat << 'EOF' > /usr/share/applications/rinauby-settings.desktop
[Desktop Entry]
Name=Rinauby Settings
Comment=Digital Humanism Desktop & System Configuration
Exec=/usr/local/bin/rinauby-settings
Icon=preferences-system
Terminal=false
Type=Application
Categories=Settings;DesktopSettings;System;GTK;
Keywords=rinauby;hyprland;settings;wallpaper;appearance;waybar;
StartupNotify=true
EOF

# ------------------------------------------------------------------------------
# 9. FUNGSI DEPLOYMENT DOTFILES KE /etc/skel & PENGGUNA AKTIF
# ------------------------------------------------------------------------------
log_step "TAHAP 9: Menyebarkan Dotfiles ke /etc/skel & Pengguna Sistem"

sanitize_and_deploy_config() {
    local target_home="$1"
    local target_user="${2:-root}"
    local cfg_dir="$target_home/.config"

    mkdir -p "$cfg_dir"
    mkdir -p "$target_home/.local/share/backgrounds"
    mkdir -p "$target_home/Pictures/Screenshots"

    # Salin modul konfigurasi utama
    for mod in hypr waybar rofi swaync kitty fastfetch scripts; do
        if [ -d "$SYS_SHARE_DIR/$mod" ]; then
            rm -rf "${cfg_dir:?}/$mod"
            cp -rf "$SYS_SHARE_DIR/$mod" "$cfg_dir/$mod"
        fi
    done

    # Salin aplikasi pengaturan GTK4 ke ~/.config/rinauby/settings-gtk
    mkdir -p "$cfg_dir/rinauby"
    rm -rf "$cfg_dir/rinauby/settings-gtk"
    cp -rf "$SYS_SHARE_DIR/settings-gtk" "$cfg_dir/rinauby/settings-gtk"

    # Symlink koleksi wallpaper ke ~/.local/share/backgrounds/rinauby
    ln -sfn "$SYS_WALL_DIR" "$target_home/.local/share/backgrounds/rinauby"

    # Buat file rinauby_overrides.conf kosong jika belum ada agar `source = ...` di hyprland.conf tidak error
    touch "$cfg_dir/hypr/rinauby_overrides.conf"

    # Sanitasi seluruh path hardcoded host Arch di dalam ~/.config target
    # 1. Path fastfetch temple.txt
    if [ -f "$cfg_dir/fastfetch/config.jsonc" ]; then
        sed -i "s|$HOST_HARDCODED_PREFIX/dotfiles/fastfetch/temple.txt|$SYS_SHARE_DIR/fastfetch/temple.txt|g" "$cfg_dir/fastfetch/config.jsonc"
    fi

    # 2. Path hyprlock wallpaper, avatar & username
    if [ -f "$cfg_dir/hypr/hyprlock.conf" ]; then
        sed -i "s|$HOST_HARDCODED_PREFIX/wallpapers/school_of_athens.jpg|$SYS_WALL_DIR/school_of_athens.jpg|g" "$cfg_dir/hypr/hyprlock.conf"
        sed -i "s|/home/rifqi/.config/hypr/hyprlock/avatar-kde.png|$SYS_SHARE_DIR/hypr/avatar.png|g" "$cfg_dir/hypr/hyprlock.conf"
        if [ "$target_user" != "root" ] && [ "$target_user" != "skel" ]; then
            local display_name
            display_name="$(echo "${target_user^}")"
            sed -i "s|text = Rifqi|text = $display_name|g" "$cfg_dir/hypr/hyprlock.conf"
        else
            sed -i 's|text = Rifqi|text = cmd[update:60000] echo "${USER^}"|g' "$cfg_dir/hypr/hyprlock.conf"
        fi
    fi

    # 3. Sanitasi umum path tersisa di file teks konfigurasi
    find "$cfg_dir" -type f \( -name "*.conf" -o -name "*.jsonc" -o -name "*.json" -o -name "*.rasi" -o -name "*.sh" -o -name "*.py" -o -name "*.css" \) \
        -exec sed -i \
        -e "s|$HOST_HARDCODED_PREFIX/wallpapers|$SYS_WALL_DIR|g" \
        -e "s|$HOST_HARDCODED_PREFIX/dotfiles|$SYS_SHARE_DIR|g" \
        {} + 2>/dev/null || true

    # Pastikan script executable
    chmod +x "$cfg_dir/waybar/quote_rotator.sh" 2>/dev/null || true
    chmod +x "$cfg_dir/waybar/window_title.py" 2>/dev/null || true
    chmod +x "$cfg_dir/rofi/wp_selector.sh" 2>/dev/null || true
    chmod +x "$cfg_dir/scripts/"*.sh 2>/dev/null || true
    chmod +x "$cfg_dir/scripts/"*.py 2>/dev/null || true
    chmod +x "$cfg_dir/rinauby/settings-gtk/main.py" 2>/dev/null || true

    # Konfigurasi Tema Gelap Default GTK-3.0 & GTK-4.0
    mkdir -p "$cfg_dir/gtk-3.0" "$cfg_dir/gtk-4.0"
    cat << 'EOF' > "$cfg_dir/gtk-3.0/settings.ini"
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Inter 10
gtk-cursor-theme-name=Bibata-Modern-Classic
gtk-cursor-theme-size=24
EOF
    cp -f "$cfg_dir/gtk-3.0/settings.ini" "$cfg_dir/gtk-4.0/settings.ini"

    # Atur kepemilikan file jika untuk user spesifik
    if [ "$target_user" != "root" ] && [ "$target_user" != "skel" ]; then
        chown -R "$target_user:$target_user" "$cfg_dir" "$target_home/.local" "$target_home/Pictures" 2>/dev/null || true
    fi
}

# 9A. Sebarkan ke /etc/skel (Wajib untuk Live ISO Cubic & pembuatan user baru)
sanitize_and_deploy_config "/etc/skel" "skel"
log_ok "Konfigurasi default berhasil dipasang ke /etc/skel/"

# 9B. Sebarkan juga ke seluruh user yang sudah ada di /home/*
for user_home in /home/*; do
    [ -d "$user_home" ] || continue
    u_name="$(basename "$user_home")"
    if id "$u_name" >/dev/null 2>&1; then
        sanitize_and_deploy_config "$user_home" "$u_name"
        log_ok "Konfigurasi Rinauby berhasil dipasang untuk user: $u_name ($user_home)"
    fi
done

# ------------------------------------------------------------------------------
# 10. KONFIGURASI PAM LOCKSCREEN, WAYLAND SESSION & ANTI-BLACK-SCREEN VIRTUALBOX
# ------------------------------------------------------------------------------
log_step "TAHAP 10: Mengonfigurasi PAM Lockscreen, Sesi Wayland, & Proteksi VirtualBox"

# 10A. Konfigurasi PAM Ubuntu untuk hyprlock & swaylock (menggunakan common-auth)
mkdir -p /etc/pam.d
cat << 'EOF' > /etc/pam.d/hyprlock
#%PAM-1.0
# PAM configuration for hyprlock on Ubuntu / Debian (Rinauby)
auth        include     common-auth
account     include     common-account
password    include     common-password
session     include     common-session
EOF
cp -f /etc/pam.d/hyprlock /etc/pam.d/swaylock
log_ok "Konfigurasi PAM (/etc/pam.d/hyprlock & swaylock) disesuaikan untuk arsitektur Ubuntu."

# 10B. Buat Session Wrapper Anti-Black-Screen untuk VirtualBox & VM
cat << 'EOF' > /usr/local/bin/start-rinauby-hyprland
#!/usr/bin/env bash
# ==============================================================================
# RINAUBY — HYPRLAND SESSION LAUNCHER (WITH VIRTUALBOX / VM SAFETY FALLBACK)
# ==============================================================================

export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=Hyprland
export QT_QPA_PLATFORM="wayland;xcb"
export GDK_BACKEND="wayland,x11"
export MOZ_ENABLE_WAYLAND=1
export ELECTRON_OZONE_PLATFORM_HINT=auto

# Deteksi apakah berjalan di dalam VirtualBox / VM tanpa akselerasi 3D penuh
VIRT_ENV="$(systemd-detect-virt 2>/dev/null || echo "none")"
DMI_PROD="$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "")"

if [ "$VIRT_ENV" = "oracle" ] || [[ "$DMI_PROD" == *"VirtualBox"* ]] || [ "$VIRT_ENV" != "none" ]; then
    # Kompatibilitas kursor software
    export WLR_NO_HARDWARE_CURSORS=1
    export WLR_RENDERER_ALLOW_SOFTWARE=1
    # Backend Aquamarine (Hyprland v0.50+) pencegah crash DRM Atomic & buffer modifiers di VM
    export AQ_NO_ATOMIC=1
    export AQ_NO_MODIFIERS=1
    # Software rendering fallback via Mesa Gallium llvmpipe jika akselerasi 3D mati
    if command -v glxinfo >/dev/null 2>&1; then
        if glxinfo 2>/dev/null | grep -qi "llvmpipe"; then
            export LIBGL_ALWAYS_SOFTWARE=1
            export GALLIUM_DRIVER=llvmpipe
            export WLR_RENDERER=pixman
        fi
    fi
fi

# Pastikan direktori runtime dan state awal tersedia
[ -f /tmp/current_wallpaper_title ] || echo "The School of Athens" > /tmp/current_wallpaper_title
mkdir -p "$HOME/.config/hypr"
[ -f "$HOME/.config/hypr/rinauby_overrides.conf" ] || touch "$HOME/.config/hypr/rinauby_overrides.conf"

# Jika user baru pada Live CD belum memiliki ~/.config/hypr/hyprland.conf, salin dari /etc/skel
if [ ! -f "$HOME/.config/hypr/hyprland.conf" ] && [ -d /etc/skel/.config ]; then
    cp -rn /etc/skel/.config/* "$HOME/.config/" 2>/dev/null || true
fi

exec Hyprland
EOF
chmod 755 /usr/local/bin/start-rinauby-hyprland

# 10C. Daftarkan Sesi Wayland di /usr/share/wayland-sessions/
mkdir -p /usr/share/wayland-sessions
cat << 'EOF' > /usr/share/wayland-sessions/rinauby.desktop
[Desktop Entry]
Name=Rinauby (Digital Humanism)
Comment=Rinauby Hyprland Wayland Compositor
Exec=/usr/local/bin/start-rinauby-hyprland
Type=Application
DesktopNames=Hyprland
Keywords=wayland;compositor;tiling;rinauby;hyprland;
EOF

# Timpa atau buat juga hyprland.desktop agar memilih "Hyprland" di GDM3 juga menggunakan wrapper aman
cp -f /usr/share/wayland-sessions/rinauby.desktop /usr/share/wayland-sessions/hyprland.desktop
log_ok "Wayland session 'Rinauby (Digital Humanism)' terdaftar di /usr/share/wayland-sessions/"

# 10D. Konfigurasi Sesi Display Manager (GDM3 / Wayland)
# CATATAN: Sesi default tidak dibajak agar Live CD tetap menjalankan GNOME & Installer Ubuntu resmi.
# Pengguna/dosen dapat memilih "Rinauby (Digital Humanism)" melalui menu roda gigi (gear) di GDM.
log_ok "Sesi GNOME bawaan & Installer Ubuntu tetap utuh untuk boot awal."
log_ok "Sesi 'Rinauby (Digital Humanism)' tersedia sebagai pilihan di Display Manager (GDM3)."

# Pastikan opsi Wayland tidak dinonaktifkan di GDM3
if [ -f /etc/gdm3/custom.conf ]; then
    sed -i 's/^WaylandEnable=false/#WaylandEnable=false/g' /etc/gdm3/custom.conf || true
fi

# Nonaktifkan autostart systemd user service hyprpaper/hypridle di sesi GNOME agar tidak crash di Live Installer
rm -f /etc/systemd/user/graphical-session.target.wants/hyprpaper.service 2>/dev/null || true
rm -f /etc/systemd/user/graphical-session.target.wants/hypridle.service 2>/dev/null || true
systemctl --global disable hyprpaper.service 2>/dev/null || true
systemctl --global disable hypridle.service 2>/dev/null || true

# Matikan crash popup Apport pada Live CD agar tidak memunculkan dialog internal error saat demo
if [ -f /etc/default/apport ]; then
    sed -i 's/^enabled=.*/enabled=0/' /etc/default/apport || true
fi
systemctl disable apport.service 2>/dev/null || true

# ------------------------------------------------------------------------------
# 11. IDENTITAS DISTRO (/etc/os-release) & PEMBERSIHAN AKHIR
# ------------------------------------------------------------------------------
log_step "TAHAP 11: Memperbarui Identitas Distro Rinauby & Pembersihan Cache"

if [ -f /etc/os-release ]; then
    cp -n /etc/os-release /etc/os-release.ubuntu.bak 2>/dev/null || true
    sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="Rinauby (Digital Humanism Edition)"/' /etc/os-release || true
    sed -i 's/^NAME=.*/NAME="Rinauby"/' /etc/os-release || true
    log_ok "Identitas /etc/os-release diperbarui menjadi: Rinauby (Digital Humanism Edition)"
fi

# Aktifkan layanan sistem esensial (aman untuk Chroot maupun VM)
systemctl enable NetworkManager.service 2>/dev/null || true
systemctl enable bluetooth.service 2>/dev/null || true

# Bersihkan cache paket APT agar ukuran ISO hasil Cubic tetap ramping
apt-get autoremove -y >/dev/null 2>&1 || true
apt-get clean >/dev/null 2>&1 || true

log_step "INSTALASI RINAUBY (DIGITAL HUMANISM EDITION) SELESAI!"
echo -e "${C_GREEN}Seluruh komponen telah siap digunakan:${C_RESET}"
echo -e "  • Compositor & Sesi : ${C_GOLD}Rinauby (Digital Humanism) / Hyprland${C_RESET}"
echo -e "  • Top Status Bar    : ${C_GOLD}Waybar (Angka Romawi + Kutipan Latin Humanisme)${C_RESET}"
echo -e "  • App Launcher      : ${C_GOLD}rinauby-launcher (Super + Space / Super + D)${C_RESET}"
echo -e "  • System Settings   : ${C_GOLD}rinauby-settings (Super + I)${C_RESET}"
echo -e "  • Wallpaper Picker  : ${C_GOLD}rinauby-wp-selector (Super + K / Super + Alt + W)${C_RESET}"
echo -e "  • Session Controls  : ${C_GOLD}rinauby-powermenu (Super + Backspace / Super + Esc)${C_RESET}"
echo -e "  • Screen Lock       : ${C_GOLD}hyprlock (Super + L)${C_RESET}"
echo -e "  • Screenshot Tool   : ${C_GOLD}rinauby-screenshot (Super + Shift + S / Print)${C_RESET}"
echo -e "  • OSD Daemon        : ${C_GOLD}rinauby-osd (Tombol Volume & Kecerahan)${C_RESET}"
echo ""
if [ "$IS_CHROOT" -eq 1 ]; then
    echo -e "${C_BLUE}Anda berada di dalam Cubic Chroot. Silakan lanjutkan menekan 'Next' di Cubic untuk memaketkan ISO.${C_RESET}"
else
    echo -e "${C_BLUE}Silakan Logout atau Reboot, lalu pilih sesi 'Rinauby (Digital Humanism)' pada layar login.${C_RESET}"
fi
