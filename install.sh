#!/usr/bin/env bash
# ==============================================================================
# RINAUBY (DIGITAL HUMANISM EDITION) — UBUNTU 26.04 / 24.04 MASTER INSTALLER
# Operating Systems Course Project 2026 (Ubuntu Remastering via Cubic)
# ==============================================================================
# This script is designed to run:
#   1. Inside a Cubic Chroot terminal (as root) during ISO remastering, OR
#   2. Inside an Ubuntu 26.04 / 24.04 virtual machine (via: sudo ./install.sh)
#
# Key Highlights:
#   - Enables essential Ubuntu repositories (universe, multiverse, restricted)
#   - Installs Hyprland, Waybar, Rofi, SwayNC, Hyprlock, Kitty, Fastfetch,
#     and all GTK4/Libadwaita (rinauby-settings) & Layer-Shell (OSD) dependencies
#   - Deploys classical typography (Cinzel, EB Garamond, JetBrains Mono, Symbols Nerd Font)
#   - Installs 8 high-resolution Renaissance masterpieces (1920x1200 + thumbnails)
#   - Deploys binary wrappers `rinauby-*` to /usr/local/bin/
#   - Provisions dotfiles to /etc/skel/.config/ and all active user directories
#   - Configures Ubuntu PAM (/etc/pam.d/hyprlock), Wayland session,
#     anti-black-screen VirtualBox protection, Display Manager, & distro branding
# ==============================================================================

set -uo pipefail

# ------------------------------------------------------------------------------
# 0. LOGGING CONFIGURATION & ANSI COLOR PALETTE (DOTFILES / INDUSTRY STANDARD)
# ------------------------------------------------------------------------------
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_DIM='\033[2m'
C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[1;34m'
C_MAGENTA='\033[1;35m'
C_CYAN='\033[1;36m'
C_GOLD='\033[38;5;214m'

log_step() {
    echo -e "\n${C_BOLD}${C_GOLD}==============================================================================${C_RESET}"
    echo -e "${C_BOLD}${C_GOLD}:: $*${C_RESET}"
    echo -e "${C_BOLD}${C_GOLD}==============================================================================${C_RESET}"
}

log_substep() { echo -e "  ${C_CYAN}::${C_RESET} $*"; }
log_info()    { echo -e "  ${C_BLUE}[INFO]${C_RESET}  $*"; }
log_ok()      { echo -e "  ${C_GREEN}[ OK ]${C_RESET}  $*"; }
log_warn()    { echo -e "  ${C_YELLOW}[WARN]${C_RESET}  $*"; }
log_err()     { echo -e "  ${C_RED}[ERROR]${C_RESET} $*" >&2; }
log_fatal()   { echo -e "  ${C_RED}[FATAL]${C_RESET} $*" >&2; }

echo -e "${C_BOLD}${C_GOLD}==============================================================================${C_RESET}"
echo -e "${C_BOLD}${C_GOLD}  RINAUBY (DIGITAL HUMANISM EDITION) — UBUNTU MASTER PROVISIONER              ${C_RESET}"
echo -e "${C_BOLD}${C_GOLD}  Ubuntu 26.04 / 24.04 LTS Automated Setup for Cubic Chroot & Live ISO        ${C_RESET}"
echo -e "${C_BOLD}${C_GOLD}==============================================================================${C_RESET}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/assets"
DOTFILES_DIR="$ASSETS_DIR/dotfiles"
WALLPAPERS_DIR="$ASSETS_DIR/wallpapers"
FONTS_DIR="$ASSETS_DIR/fonts"
BIN_DIR="$ASSETS_DIR/bin"

HOST_HARDCODED_PREFIX="/home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets"

# ==============================================================================
# ABSOLUTE SAFEGUARD: OS CHECK (DO NOT EXECUTE ON ARCH LINUX HOST SYSTEM!)
# ==============================================================================
if [ -f /etc/os-release ]; then
    OS_ID="$(grep -E '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')"
    OS_LIKE="$(grep -E '^ID_LIKE=' /etc/os-release | cut -d= -f2 | tr -d '"')"
    OS_NAME="$(grep -E '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')"

    if [ "$OS_ID" = "arch" ] || [[ "$OS_LIKE" == *"arch"* ]]; then
        echo -e "${C_RED}==============================================================================${C_RESET}"
        echo -e "${C_RED}[FATAL ERROR] HOST SYSTEM DETECTED AS ARCH LINUX (${OS_NAME})!${C_RESET}"
        echo -e "${C_RED}This script is exclusively designed for Ubuntu remastering inside Cubic or a VM!${C_RESET}"
        echo -e "${C_RED}Execution ABORTED immediately to protect your host dotfiles and system packages.${C_RESET}"
        echo -e "${C_RED}==============================================================================${C_RESET}"
        exit 1
    fi

    if [ "$OS_ID" != "ubuntu" ] && [ "$OS_ID" != "debian" ] && [[ "$OS_LIKE" != *"ubuntu"* ]] && [[ "$OS_LIKE" != *"debian"* ]]; then
        log_err "Unsupported operating system (${OS_NAME:-$OS_ID}). Expected Ubuntu/Debian. Aborting!"
        exit 1
    fi
fi

if ! command -v apt-get >/dev/null 2>&1; then
    log_err "Package manager 'apt-get' not found on this system. Aborting."
    exit 1
fi

# Ensure running with root privileges
if [ "$(id -u)" -ne 0 ]; then
    log_err "This script must be run as root! Use: sudo ./install.sh"
    exit 1
fi

# Ensure assets directory exists
if [ ! -d "$DOTFILES_DIR" ]; then
    log_err "Assets directory '$DOTFILES_DIR' not found. Please run this script from the Rancangan repository root!"
    exit 1
fi

# Detect whether running inside a chroot container (e.g. Cubic)
IS_CHROOT=0
if [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/. 2>/dev/null || echo 0:0)" ]; then
    IS_CHROOT=1
    log_info "Environment detected: Cubic Chroot container."
else
    log_info "Environment detected: Live / Virtual Ubuntu system."
fi

export DEBIAN_FRONTEND=noninteractive

# ------------------------------------------------------------------------------
# 1. CONFIGURE UBUNTU 26.04 / 24.04 REPOSITORIES
# ------------------------------------------------------------------------------
log_step "PHASE 1/11: Configuring Ubuntu Repositories (Universe, Multiverse, Restricted)"

# Disable stale or missing cdrom entries often present in Cubic chroot environments
if [ -f /etc/apt/sources.list ]; then
    sed -i '/cdrom:/s/^/# /' /etc/apt/sources.list 2>/dev/null || true
    sed -i '/file:\/cdrom/s/^/# /' /etc/apt/sources.list 2>/dev/null || true
fi

apt-get update -y || true
apt-get install -y software-properties-common ca-certificates curl wget gnupg lsb-release apt-transport-https

add-apt-repository -y universe || true
add-apt-repository -y multiverse || true
add-apt-repository -y restricted || true
apt-get update -y

UBUNTU_CODENAME="$(lsb_release -cs 2>/dev/null || echo "resolute")"
UBUNTU_RELEASE="$(lsb_release -rs 2>/dev/null || echo "26.04")"
log_info "Target distribution: Ubuntu $UBUNTU_RELEASE ($UBUNTU_CODENAME)"

# Robust package installer helper (prevents batch failure if an optional package is missing)
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
        log_info "Installing packages (${#available_pkgs[@]} total): ${available_pkgs[*]}"
        if ! apt-get install -y --no-install-recommends "${available_pkgs[@]}"; then
            log_warn "Batch installation encountered errors; attempting fallback sequential installation..."
            for pkg in "${available_pkgs[@]}"; do
                apt-get install -y --no-install-recommends "$pkg" || log_warn "Failed to install package: $pkg"
            done
        fi
    fi

    if [ "${#missing_pkgs[@]}" -gt 0 ]; then
        log_warn "The following packages were not found in APT cache (skipped/fallback): ${missing_pkgs[*]}"
    fi
}

# ------------------------------------------------------------------------------
# 2. INSTALL HYPRLAND & WAYLAND COMPOSITOR ECOSYSTEM
# ------------------------------------------------------------------------------
log_step "PHASE 2/11: Installing Hyprland & Wayland Compositor Ecosystem"

# Check hyprland availability in official repositories (Universe is enabled)
if ! apt-cache show hyprland >/dev/null 2>&1; then
    # Only add fallback PPA if running on Ubuntu 24.04 (noble); in 26.04/26.10 hyprland is in universe
    if [ "$UBUNTU_CODENAME" = "noble" ]; then
        log_warn "Hyprland not found in default repositories. Adding fallback PPA for $UBUNTU_CODENAME..."
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
# 3. INSTALL DESKTOP UTILITIES & POLKIT
# ------------------------------------------------------------------------------
log_step "PHASE 3/11: Installing Desktop Utilities & Polkit Authentication Agent"

SHELL_PKGS=(
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

# ------------------------------------------------------------------------------
# 4. INSTALL PYTHON GTK4 / LIBADWAITA (SETTINGS) & GTK3 LAYER-SHELL (OSD)
# ------------------------------------------------------------------------------
log_step "PHASE 4/11: Installing Python GTK4 / Libadwaita & GTK Layer-Shell Dependencies"

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
# 5. INSTALL TERMINAL, SCREENSHOT UTILITIES, AUDIO, MULTIMEDIA & SYSTEM TOOLS
# ------------------------------------------------------------------------------
log_step "PHASE 5/11: Installing Kitty, Fastfetch, Screenshot Tools, Audio & Utilities"

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

# Fallback if fastfetch is not yet available in APT repositories
if ! command -v fastfetch >/dev/null 2>&1; then
    log_info "Downloading official Fastfetch (.deb) release package from GitHub..."
    ARCH_DEB="$(dpkg --print-architecture 2>/dev/null || echo "amd64")"
    FF_URL="https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-${ARCH_DEB}.deb"
    if curl -fsSL "$FF_URL" -o /tmp/fastfetch.deb; then
        dpkg -i /tmp/fastfetch.deb || apt-get install -f -y
        rm -f /tmp/fastfetch.deb
        log_ok "Fastfetch successfully installed from official GitHub release."
    else
        log_warn "Failed to download fastfetch.deb; please verify active internet connectivity."
    fi
fi

# ------------------------------------------------------------------------------
# 6. INSTALL TYPOGRAPHY (CINZEL, EB GARAMOND, INTER, JETBRAINS MONO & NERD FONTS)
# ------------------------------------------------------------------------------
log_step "PHASE 6/11: Installing System Fonts & Rinauby Classical Typography Bundle"

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
    log_ok "Bundled fonts (Cinzel & Symbols Nerd Font Mono) installed to $SYS_FONT_DIR"
fi

# Create Fontconfig alias configuration so requests for 'JetBrainsMono Nerd Font' or
# 'Iosevka Nerd Font' automatically fall back to JetBrains Mono + Symbols Nerd Font Mono
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
log_ok "System font cache refreshed successfully."

# ------------------------------------------------------------------------------
# 7. DEPLOY CLASSICAL WALLPAPERS & GLOBAL SYSTEM ASSETS (/usr/share/backgrounds/rinauby)
# ------------------------------------------------------------------------------
log_step "PHASE 7/11: Deploying Classical Wallpaper Gallery & Global System Assets"

SYS_WALL_DIR="/usr/share/backgrounds/rinauby"
SYS_SHARE_DIR="/usr/share/rinauby"

mkdir -p "$SYS_WALL_DIR/.thumbs"
mkdir -p "$SYS_WALL_DIR/.thumbs_carousel"
mkdir -p "$SYS_SHARE_DIR"

if [ -d "$WALLPAPERS_DIR" ]; then
    cp -f "$WALLPAPERS_DIR"/*.jpg "$SYS_WALL_DIR/" 2>/dev/null || true
    if [ -d "$WALLPAPERS_DIR/.thumbs" ]; then
        cp -f "$WALLPAPERS_DIR/.thumbs"/*.jpg "$SYS_WALL_DIR/.thumbs/" 2>/dev/null || true
    fi
    if [ -d "$WALLPAPERS_DIR/.thumbs_carousel" ]; then
        cp -f "$WALLPAPERS_DIR/.thumbs_carousel"/*.jpg "$SYS_WALL_DIR/.thumbs_carousel/" 2>/dev/null || true
    fi
    chmod -R 755 "$SYS_WALL_DIR"
    log_ok "8 Renaissance masterpieces and thumbnails deployed to $SYS_WALL_DIR"
fi

# Generate missing thumbnails if ImageMagick is installed
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

# Generate classical fallback avatar for Hyprlock
mkdir -p "$SYS_SHARE_DIR/hypr"
if command -v magick >/dev/null 2>&1 || command -v convert >/dev/null 2>&1; then
    IMG_CMD="convert"
    command -v magick >/dev/null 2>&1 && IMG_CMD="magick"
    if [ -f "$SYS_WALL_DIR/apotheosis.jpg" ]; then
        "$IMG_CMD" "$SYS_WALL_DIR/apotheosis.jpg" -gravity center -crop 400x400+0+0 +repage -resize 180x180 "$SYS_SHARE_DIR/hypr/avatar.png" 2>/dev/null || true
    elif [ -f "$SYS_WALL_DIR/school_of_athens.jpg" ]; then
        "$IMG_CMD" "$SYS_WALL_DIR/school_of_athens.jpg" -gravity center -crop 400x400+0+0 +repage -resize 180x180 "$SYS_SHARE_DIR/hypr/avatar.png" 2>/dev/null || true
    fi
fi

# Copy all dotfiles components to /usr/share/rinauby as global system reference
cp -rf "$DOTFILES_DIR"/* "$SYS_SHARE_DIR/"
find "$SYS_SHARE_DIR" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# Sanitize hardcoded host Arch paths inside /usr/share/rinauby
find "$SYS_SHARE_DIR" -type f \( -name "*.conf" -o -name "*.jsonc" -o -name "*.json" -o -name "*.rasi" -o -name "*.sh" -o -name "*.py" -o -name "*.css" \) \
    -exec sed -i \
    -e "s|$HOST_HARDCODED_PREFIX/wallpapers|$SYS_WALL_DIR|g" \
    -e "s|$HOST_HARDCODED_PREFIX/dotfiles|$SYS_SHARE_DIR|g" \
    -e "s|/home/rifqi/.config/hypr/hyprlock/avatar-kde.png|$SYS_SHARE_DIR/hypr/avatar.png|g" \
    {} + 2>/dev/null || true

# ------------------------------------------------------------------------------
# 8. INSTALL BINARY WRAPPERS (rinauby-*) & DESKTOP APPLICATIONS
# ------------------------------------------------------------------------------
log_step "PHASE 8/11: Installing Binary Wrappers (/usr/local/bin/rinauby-*) & Desktop Entry"

mkdir -p /usr/local/bin
if [ -d "$BIN_DIR" ]; then
    cp -f "$BIN_DIR"/rinauby-* /usr/local/bin/
    chmod 755 /usr/local/bin/rinauby-*
    sed -i \
        -e "s|$HOST_HARDCODED_PREFIX/wallpapers|$SYS_WALL_DIR|g" \
        -e "s|$HOST_HARDCODED_PREFIX/dotfiles|$SYS_SHARE_DIR|g" \
        /usr/local/bin/rinauby-* 2>/dev/null || true
    log_ok "All rinauby-* wrapper binaries installed to /usr/local/bin/ (paths sanitized)"
fi

# Ensure all scripts in /usr/share/rinauby are executable
chmod +x "$SYS_SHARE_DIR/scripts/"*.sh 2>/dev/null || true
chmod +x "$SYS_SHARE_DIR/scripts/"*.py 2>/dev/null || true
chmod +x "$SYS_SHARE_DIR/quickshell/scripts/"*.sh 2>/dev/null || true
chmod +x "$SYS_SHARE_DIR/settings-gtk/main.py" 2>/dev/null || true

# Create Desktop Entry for Rinauby Settings so it shows up in launcher and desktop menus
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
Keywords=rinauby;hyprland;settings;wallpaper;appearance;quickshell;
StartupNotify=true
EOF

# ------------------------------------------------------------------------------
# 9. DEPLOY DOTFILES TO /etc/skel & EXISTING USER ACCOUNTS
# ------------------------------------------------------------------------------
log_step "PHASE 9/11: Deploying Dotfiles to /etc/skel & System User Accounts"

sanitize_and_deploy_config() {
    local target_home="$1"
    local target_user="${2:-root}"
    local cfg_dir="$target_home/.config"

    mkdir -p "$cfg_dir"
    mkdir -p "$target_home/.local/share/backgrounds"
    mkdir -p "$target_home/Pictures/Screenshots"

    # Copy primary configuration modules
    for mod in hypr quickshell kitty fastfetch scripts; do
        if [ -d "$SYS_SHARE_DIR/$mod" ]; then
            rm -rf "${cfg_dir:?}/$mod"
            cp -rf "$SYS_SHARE_DIR/$mod" "$cfg_dir/$mod"
        fi
    done

    # Ensure Quickshell profile 'rs' is accessible
    if [ -d "$cfg_dir/quickshell" ]; then
        mkdir -p "$cfg_dir/quickshell"
        [ -e "$cfg_dir/quickshell/rs" ] || ln -sfn "$cfg_dir/quickshell" "$cfg_dir/quickshell/rs"
    fi

    # Copy GTK4 Settings application to ~/.config/rinauby/settings-gtk
    mkdir -p "$cfg_dir/rinauby"
    rm -rf "$cfg_dir/rinauby/settings-gtk"
    cp -rf "$SYS_SHARE_DIR/settings-gtk" "$cfg_dir/rinauby/settings-gtk"

    # Symlink wallpaper collection to ~/.local/share/backgrounds/rinauby
    ln -sfn "$SYS_WALL_DIR" "$target_home/.local/share/backgrounds/rinauby"

    # Create empty rinauby_overrides.conf if absent so Hyprland `source = ...` doesn't error
    touch "$cfg_dir/hypr/rinauby_overrides.conf"

    # Sanitize hardcoded host paths inside target user ~/.config
    # 1. Path for fastfetch temple.txt
    if [ -f "$cfg_dir/fastfetch/config.jsonc" ]; then
        sed -i "s|$HOST_HARDCODED_PREFIX/dotfiles/fastfetch/temple.txt|$SYS_SHARE_DIR/fastfetch/temple.txt|g" "$cfg_dir/fastfetch/config.jsonc"
    fi

    # 2. Path for hyprlock wallpaper, avatar & dynamic username
    if [ -f "$cfg_dir/hypr/hyprlock.conf" ]; then
        sed -i -e "s|$HOST_HARDCODED_PREFIX/wallpapers/apotheosis.jpg|$SYS_WALL_DIR/apotheosis.jpg|g" \
               -e "s|$HOST_HARDCODED_PREFIX/wallpapers/school_of_athens.jpg|$SYS_WALL_DIR/school_of_athens.jpg|g" "$cfg_dir/hypr/hyprlock.conf"
        sed -i "s|/home/rifqi/.config/hypr/hyprlock/avatar-kde.png|$SYS_SHARE_DIR/hypr/avatar.png|g" "$cfg_dir/hypr/hyprlock.conf"
        if [ "$target_user" != "root" ] && [ "$target_user" != "skel" ]; then
            local display_name
            display_name="$(echo "${target_user^}")"
            sed -i "s|text = Rifqi|text = $display_name|g" "$cfg_dir/hypr/hyprlock.conf"
        else
            sed -i 's|text = Rifqi|text = cmd[update:60000] echo "${USER^}"|g' "$cfg_dir/hypr/hyprlock.conf"
        fi
    fi

    # 3. General sanitization for remaining configuration text files
    find "$cfg_dir" -type f \( -name "*.conf" -o -name "*.jsonc" -o -name "*.json" -o -name "*.rasi" -o -name "*.sh" -o -name "*.py" -o -name "*.css" \) \
        -exec sed -i \
        -e "s|$HOST_HARDCODED_PREFIX/wallpapers|$SYS_WALL_DIR|g" \
        -e "s|$HOST_HARDCODED_PREFIX/dotfiles|$SYS_SHARE_DIR|g" \
        {} + 2>/dev/null || true

    # Ensure executable permissions for user scripts
    chmod +x "$cfg_dir/scripts/"*.sh 2>/dev/null || true
    chmod +x "$cfg_dir/scripts/"*.py 2>/dev/null || true
    chmod +x "$cfg_dir/quickshell/scripts/"*.sh 2>/dev/null || true
    chmod +x "$cfg_dir/rinauby/settings-gtk/main.py" 2>/dev/null || true

    # Default Dark Theme configuration for GTK-3.0 & GTK-4.0
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

    # Set ownership for real user homes
    if [ "$target_user" != "root" ] && [ "$target_user" != "skel" ]; then
        chown -R "$target_user:$target_user" "$cfg_dir" "$target_home/.local" "$target_home/Pictures" 2>/dev/null || true
    fi
}

# 9A. Deploy to /etc/skel (Essential for Cubic Live ISO & new user provisioning)
sanitize_and_deploy_config "/etc/skel" "skel"
log_ok "Default configuration successfully deployed to /etc/skel/"

# 9B. Deploy to all existing user accounts in /home/*
for user_home in /home/*; do
    [ -d "$user_home" ] || continue
    u_name="$(basename "$user_home")"
    if id "$u_name" >/dev/null 2>&1; then
        sanitize_and_deploy_config "$user_home" "$u_name"
        log_ok "Rinauby configuration successfully deployed for user: $u_name ($user_home)"
    fi
done

# ------------------------------------------------------------------------------
# 10. CONFIGURE PAM LOCKSCREEN, WAYLAND SESSION & VIRTUAL MACHINE COMPATIBILITY
# ------------------------------------------------------------------------------
log_step "PHASE 10/11: Configuring PAM Lockscreen, Wayland Session, & VM Compatibility"

# 10A. PAM configuration for hyprlock & swaylock on Ubuntu / Debian (using common-auth)
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
log_ok "PAM configurations (/etc/pam.d/hyprlock & swaylock) configured for Ubuntu architecture."

# 10B. Create Anti-Black-Screen Session Wrapper for VirtualBox & VMs
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

# Detect execution inside VirtualBox / VM without full 3D hardware acceleration
VIRT_ENV="$(systemd-detect-virt 2>/dev/null || echo "none")"
DMI_PROD="$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "")"

if [ "$VIRT_ENV" = "oracle" ] || [[ "$DMI_PROD" == *"VirtualBox"* ]] || [ "$VIRT_ENV" != "none" ]; then
    # Software cursor compatibility
    export WLR_NO_HARDWARE_CURSORS=1
    export WLR_RENDERER_ALLOW_SOFTWARE=1
    # Aquamarine backend (Hyprland v0.50+) preventing DRM Atomic & buffer modifier crashes in VMs
    export AQ_NO_ATOMIC=1
    export AQ_NO_MODIFIERS=1
    # Software rendering fallback via Mesa Gallium llvmpipe if 3D acceleration is missing
    if command -v glxinfo >/dev/null 2>&1; then
        if glxinfo 2>/dev/null | grep -qi "llvmpipe"; then
            export LIBGL_ALWAYS_SOFTWARE=1
            export GALLIUM_DRIVER=llvmpipe
            export WLR_RENDERER=pixman
        fi
    fi
fi

# Ensure runtime directories and initial state are ready
[ -f /tmp/current_wallpaper_title ] || echo "The School of Athens" > /tmp/current_wallpaper_title
mkdir -p "$HOME/.config/hypr"
[ -f "$HOME/.config/hypr/rinauby_overrides.conf" ] || touch "$HOME/.config/hypr/rinauby_overrides.conf"

# If a fresh user on Live CD doesn't yet have ~/.config/hypr/hyprland.conf, copy from /etc/skel
if [ ! -f "$HOME/.config/hypr/hyprland.conf" ] && [ -d /etc/skel/.config ]; then
    cp -rn /etc/skel/.config/* "$HOME/.config/" 2>/dev/null || true
fi

exec Hyprland
EOF
chmod 755 /usr/local/bin/start-rinauby-hyprland

# 10C. Register Wayland Session in /usr/share/wayland-sessions/
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

# Also link or copy to hyprland.desktop so choosing "Hyprland" in GDM3 uses the safe launcher
cp -f /usr/share/wayland-sessions/rinauby.desktop /usr/share/wayland-sessions/hyprland.desktop
log_ok "Wayland session 'Rinauby (Digital Humanism)' registered in /usr/share/wayland-sessions/"

# 10D. Display Manager Session Configuration (GDM3 / Wayland)
# NOTE: The default session is not hijacked so Live CD retains standard GNOME and official Ubuntu Installer.
# Users or evaluators can select "Rinauby (Digital Humanism)" via the gear icon on the GDM login screen.
log_ok "Standard GNOME session & Ubuntu Live Installer preserved for default initial boot."
log_ok "Session 'Rinauby (Digital Humanism)' available as an selectable option in Display Manager (GDM3)."

# Ensure Wayland is not disabled in GDM3 configuration
if [ -f /etc/gdm3/custom.conf ]; then
    sed -i 's/^WaylandEnable=false/#WaylandEnable=false/g' /etc/gdm3/custom.conf || true
fi

# Disable systemd user units for hyprpaper/hypridle in standard GNOME session to prevent crashes during Live Installer
rm -f /etc/systemd/user/graphical-session.target.wants/hyprpaper.service 2>/dev/null || true
rm -f /etc/systemd/user/graphical-session.target.wants/hypridle.service 2>/dev/null || true
systemctl --global disable hyprpaper.service 2>/dev/null || true
systemctl --global disable hypridle.service 2>/dev/null || true

# Disable Ubuntu Apport crash popups on Live CD to prevent disruptive dialogs
if [ -f /etc/default/apport ]; then
    sed -i 's/^enabled=.*/enabled=0/' /etc/default/apport || true
fi
systemctl disable apport.service 2>/dev/null || true

# ------------------------------------------------------------------------------
# 11. UPDATE DISTRO IDENTITY (/etc/os-release) & FINAL SYSTEM CLEANUP
# ------------------------------------------------------------------------------
log_step "PHASE 11/11: Updating Distro Identity (/etc/os-release) & Cache Cleanup"

if [ -f /etc/os-release ]; then
    cp -n /etc/os-release /etc/os-release.ubuntu.bak 2>/dev/null || true
    sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="Rinauby (Digital Humanism Edition)"/' /etc/os-release || true
    sed -i 's/^NAME=.*/NAME="Rinauby"/' /etc/os-release || true
    log_ok "Distribution identity in /etc/os-release updated to: Rinauby (Digital Humanism Edition)"
fi

# Enable essential system services (safe for both Chroot and VM environments)
systemctl enable NetworkManager.service 2>/dev/null || true
systemctl enable bluetooth.service 2>/dev/null || true

# Clean APT package cache to minimize remastered Cubic ISO footprint
apt-get autoremove -y >/dev/null 2>&1 || true
apt-get clean >/dev/null 2>&1 || true

log_step "INSTALLATION COMPLETE: RINAUBY (DIGITAL HUMANISM EDITION)"
echo -e "${C_GREEN}All desktop components and configurations are ready:${C_RESET}"
echo -e "  • Compositor & Session : ${C_GOLD}Rinauby (Digital Humanism) / Hyprland${C_RESET}"
echo -e "  • Status Bar           : ${C_GOLD}Waybar (Roman Numerals + Latin Philosophy Quotes)${C_RESET}"
echo -e "  • Application Launcher : ${C_GOLD}rinauby-launcher (Super + Space / Super + D)${C_RESET}"
echo -e "  • System Settings      : ${C_GOLD}rinauby-settings (Super + I)${C_RESET}"
echo -e "  • Wallpaper Selector   : ${C_GOLD}rinauby-wp-selector (Super + K / Super + Alt + W)${C_RESET}"
echo -e "  • Power Menu           : ${C_GOLD}rinauby-powermenu (Super + Backspace / Super + Esc)${C_RESET}"
echo -e "  • Screen Lock          : ${C_GOLD}hyprlock (Super + L)${C_RESET}"
echo -e "  • Screenshot Utility   : ${C_GOLD}rinauby-screenshot (Super + Shift + S / Print)${C_RESET}"
echo -e "  • On-Screen Display    : ${C_GOLD}rinauby-osd (Volume & Brightness Overlays)${C_RESET}"
echo ""
if [ "$IS_CHROOT" -eq 1 ]; then
    echo -e "${C_BLUE}You are running inside a Cubic Chroot container.${C_RESET}"
    echo -e "${C_BLUE}Click 'Next' in Cubic to generate the bootable remastered ISO image.${C_RESET}"
else
    echo -e "${C_BLUE}Please log out or reboot, then select 'Rinauby (Digital Humanism)' on the login screen.${C_RESET}"
fi
