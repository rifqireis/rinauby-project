#!/usr/bin/env bash
# ==============================================================================
# RINAUBY (DIGITAL HUMANISM) — THEMING & CUSTOMIZATION MASTER DEPLOYER
# Operating Systems Course Project 2026 (Ubuntu 26.10 / 26.04 / 24.04 Remastering)
# ==============================================================================
# This script applies all curated customizations that require pre-configured assets:
#   1. Plymouth Bootscreen Pack 3 "Pixels"
#   2. SDDM Sugar-Candy with Mona Lisa (Louvre C2RMF) & PartialBlur Layout
#   3. Starship Shell Prompt (rccyx/osyx 4-segment pill capsules)
#   4. Papirus Folders Colorizer (Gold / Cat-Mocha)
#   5. Default GTK Applications & MIME Associations (Nautilus, Editor, Evince, Celluloid)
#   6. Kitty Terminal Presets & Dual-Theme Engine (rinauby-theme-switch)
#   7. Comprehensive Diagnostics & Healthcheck Engine (--check)
# ==============================================================================

set -uo pipefail

# ANSI Color Palette
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

log_step()    { echo -e "\n${C_BOLD}${C_GOLD}:: $*${C_RESET}"; }
log_substep() { echo -e "  ${C_CYAN}::${C_RESET} $*"; }
log_ok()      { echo -e "  ${C_GREEN}[PASS]${C_RESET} $*"; }
log_fail()    { echo -e "  ${C_RED}[FAIL]${C_RESET} $*"; }
log_warn()    { echo -e "  ${C_YELLOW}[WARN]${C_RESET} $*"; }
log_info()    { echo -e "  ${C_BLUE}[INFO]${C_RESET} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/assets"
DOTFILES_DIR="$ASSETS_DIR/dotfiles"
WALLPAPERS_DIR="$ASSETS_DIR/wallpapers"
SDDM_DIR="$ASSETS_DIR/sddm"
PLYMOUTH_DIR="$ASSETS_DIR/plymouth"
BIN_DIR="$ASSETS_DIR/bin"

SYS_WALL_DIR="/usr/share/backgrounds/rinauby"
SYS_SHARE_DIR="/usr/share/rinauby"

# ------------------------------------------------------------------------------
# 1. DEPLOY PLYMOUTH BOOT SCREEN (PACK 3 "PIXELS")
# ------------------------------------------------------------------------------
deploy_plymouth_pixels() {
    log_step "1. Deploying Plymouth Boot Screen (Pack 3 'Pixels')"
    
    local target_dir="/usr/share/plymouth/themes/pixels"
    mkdir -p "$target_dir"
    mkdir -p /etc/plymouth
    
    if [ -d "$PLYMOUTH_DIR/pixels" ]; then
        cp -rf "$PLYMOUTH_DIR/pixels"/* "$target_dir/" 2>/dev/null || true
        chmod 644 "$target_dir"/*.png 2>/dev/null || true
        chmod 755 "$target_dir"/pixels.* 2>/dev/null || true
        log_ok "Plymouth theme 'pixels' copied to $target_dir"
    else
        log_warn "Plymouth source directory '$PLYMOUTH_DIR/pixels' not found."
    fi

    # Daftarkan alternatif Debian & set default theme
    if command -v update-alternatives >/dev/null 2>&1 && [ -f "$target_dir/pixels.plymouth" ]; then
        update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth "$target_dir/pixels.plymouth" 200 2>/dev/null || true
        update-alternatives --set default.plymouth "$target_dir/pixels.plymouth" 2>/dev/null || true
    fi

    cat << 'EOF' > /etc/plymouth/plymouthd.conf
[Daemon]
Theme=pixels
ShowDelay=0
EOF

    if command -v plymouth-set-default-theme >/dev/null 2>&1; then
        plymouth-set-default-theme pixels 2>/dev/null || true
        log_ok "Default Plymouth theme set to 'pixels'"
    fi

    # Pastikan kernel command line memuat quiet splash
    if [ -f /etc/default/grub ]; then
        if ! grep -q "quiet splash" /etc/default/grub; then
            sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 quiet splash"/' /etc/default/grub
            sed -i 's/""/"quiet splash"/g' /etc/default/grub
        fi
        command -v update-grub >/dev/null 2>&1 && update-grub >/dev/null 2>&1 || true
    fi

    # Update initramfs untuk memuat tema pixels ke dalam ramdisk kernel
    if command -v update-initramfs >/dev/null 2>&1; then
        log_info "Updating kernel initramfs for Plymouth 'pixels' boot splash..."
        update-initramfs -u -k all >/dev/null 2>&1 || update-initramfs -u >/dev/null 2>&1 || true
        log_ok "Kernel initramfs updated with Plymouth 'pixels'"
    fi
}

# ------------------------------------------------------------------------------
# 2. DEPLOY SDDM SUGAR-CANDY (MONA LISA & PARTIAL BLUR)
# ------------------------------------------------------------------------------
deploy_sddm_sugar_candy() {
    log_step "2. Deploying SDDM Sugar-Candy (Mona Lisa & Default DM Activation)"
    
    local theme_target="/usr/share/sddm/themes/sugar-candy"
    mkdir -p "$theme_target"
    mkdir -p /etc/sddm.conf.d

    if [ -d "$SDDM_DIR/themes/sugar-candy" ]; then
        cp -rf "$SDDM_DIR/themes/sugar-candy"/* "$theme_target/" 2>/dev/null || true
        log_ok "SDDM Sugar-Candy theme files deployed to $theme_target"
    else
        log_warn "SDDM source directory '$SDDM_DIR/themes/sugar-candy' not found."
    fi

    # Copy Mona Lisa to system backgrounds if present
    if [ -f "$ASSETS_DIR/sddm/themes/sugar-candy/Backgrounds/mona_lisa.jpg" ]; then
        mkdir -p "$SYS_WALL_DIR"
        cp -f "$ASSETS_DIR/sddm/themes/sugar-candy/Backgrounds/mona_lisa.jpg" "$SYS_WALL_DIR/mona_lisa.jpg" 2>/dev/null || true
        mkdir -p "$theme_target/Backgrounds"
        cp -f "$ASSETS_DIR/sddm/themes/sugar-candy/Backgrounds/mona_lisa.jpg" "$theme_target/Backgrounds/mona_lisa.jpg" 2>/dev/null || true
        log_ok "Mona Lisa Louvre C2RMF widescreen background installed."
    fi

    # Configure SDDM to use Sugar-Candy and default to hyprland.desktop session
    cat << 'EOF' > /etc/sddm.conf.d/rinauby.conf
[Theme]
Current=sugar-candy

[Users]
DefaultSession=hyprland.desktop

[General]
InputMethod=
Numlock=none
EOF
    log_ok "SDDM configuration registered in /etc/sddm.conf.d/rinauby.conf"

    # Set SDDM as the primary Display Manager on Debian/Ubuntu
    mkdir -p /etc/X11
    echo "/usr/bin/sddm" > /etc/X11/default-display-manager
    if command -v debconf-set-selections >/dev/null 2>&1; then
        echo "sddm shared/default-x-display-manager select sddm" | debconf-set-selections 2>/dev/null || true
        echo "gdm3 shared/default-x-display-manager select sddm" | debconf-set-selections 2>/dev/null || true
    fi

    # Explicitly configure systemd symlinks (essential for chroot / Cubic ISO remastering where systemd is not PID 1)
    rm -f /etc/systemd/system/display-manager.service 2>/dev/null || true
    for sddm_unit in /usr/lib/systemd/system/sddm.service /lib/systemd/system/sddm.service; do
        if [ -f "$sddm_unit" ]; then
            ln -sfn "$sddm_unit" /etc/systemd/system/display-manager.service
            mkdir -p /etc/systemd/system/graphical.target.wants
            ln -sfn "$sddm_unit" /etc/systemd/system/graphical.target.wants/sddm.service
            break
        fi
    done
    rm -f /etc/systemd/system/graphical.target.wants/gdm3.service /etc/systemd/system/graphical.target.wants/gdm.service 2>/dev/null || true
    rm -f /etc/systemd/system/multi-user.target.wants/gdm3.service /etc/systemd/system/multi-user.target.wants/gdm.service 2>/dev/null || true

    # Enable SDDM service and disable GDM3 if systemctl is available
    if command -v systemctl >/dev/null 2>&1; then
        systemctl disable gdm3.service gdm.service 2>/dev/null || true
        systemctl enable sddm.service 2>/dev/null || true
    fi
    log_ok "SDDM display manager enabled as default system greeter (GDM3 disabled and symlinks pinned)."
}

# ------------------------------------------------------------------------------
# 3. DEPLOY STARSHIP PROMPT (RCCYX/OSYX 4-SEGMENT PILL CAPSULES)
# ------------------------------------------------------------------------------
deploy_starship_prompt() {
    log_step "3. Deploying Starship Shell Prompt (rccyx/osyx 4-segment pill design)"
    
    # 1. Ensure starship binary exists (install via official script if missing from APT)
    if ! command -v starship >/dev/null 2>&1; then
        log_info "Installing official Starship binary..."
        if curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b /usr/local/bin >/dev/null 2>&1; then
            log_ok "Starship binary installed to /usr/local/bin/starship"
        else
            log_warn "Failed to download Starship binary automatically; check internet connection."
        fi
    fi

    # 2. Deploy starship.toml to /etc/skel and all existing homes
    local starship_src="$DOTFILES_DIR/starship/starship.toml"
    if [ -f "$starship_src" ]; then
        mkdir -p /etc/skel/.config
        cp -f "$starship_src" /etc/skel/.config/starship.toml
        
        for uhome in /home/*; do
            [ -d "$uhome" ] || continue
            local uname="$(basename "$uhome")"
            if id "$uname" >/dev/null 2>&1; then
                mkdir -p "$uhome/.config"
                cp -f "$starship_src" "$uhome/.config/starship.toml"
                chown -R "$uname:$uname" "$uhome/.config/starship.toml" 2>/dev/null || true
            fi
        done
        log_ok "Starship configuration (starship.toml) deployed to /etc/skel and user directories."
    fi

    # 3. Hook Starship init into system and user bashrc
    local bash_hook='if command -v starship >/dev/null 2>&1; then eval "$(starship init bash)"; fi'
    
    if [ -f /etc/bash.bashrc ] && ! grep -q "starship init bash" /etc/bash.bashrc; then
        echo -e "\n# Rinauby Digital Humanism Starship Prompt\n$bash_hook" >> /etc/bash.bashrc
        log_ok "Starship bash initialization hooked into /etc/bash.bashrc"
    fi

    if [ -f /etc/skel/.bashrc ] && ! grep -q "starship init bash" /etc/skel/.bashrc; then
        echo -e "\n# Rinauby Digital Humanism Starship Prompt\n$bash_hook" >> /etc/skel/.bashrc
    fi
}

# ------------------------------------------------------------------------------
# 4. DEPLOY PAPIRUS-FOLDERS & ICON PALETTES
# ------------------------------------------------------------------------------
deploy_papirus_folders() {
    log_step "4. Deploying Papirus Folders Colorizer & Presets"

    mkdir -p /usr/local/bin
    if [ -f "$BIN_DIR/papirus-folders" ]; then
        cp -f "$BIN_DIR/papirus-folders" /usr/local/bin/papirus-folders
        chmod 755 /usr/local/bin/papirus-folders
        log_ok "papirus-folders utility installed to /usr/local/bin/papirus-folders"
    elif ! command -v papirus-folders >/dev/null 2>&1; then
        curl -fsSL https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/papirus-folders -o /usr/local/bin/papirus-folders 2>/dev/null || true
        chmod 755 /usr/local/bin/papirus-folders 2>/dev/null || true
    fi

    # Set default folder color to gold (Renaissance Classical palette)
    if command -v papirus-folders >/dev/null 2>&1; then
        papirus-folders -C gold --theme Papirus-Dark 2>/dev/null || true
        log_ok "Default Papirus folder color set to: Gold (Renaissance Classical)"
    fi
}

# ------------------------------------------------------------------------------
# 5. DEPLOY DEFAULT GTK APPLICATIONS & MIME ASSOCIATIONS
# ------------------------------------------------------------------------------
deploy_default_apps_and_mime() {
    log_step "5. Deploying Default GTK Applications & MIME Associations"

    local mime_src="$DOTFILES_DIR/mime/mimeapps.list"
    if [ -f "$mime_src" ]; then
        mkdir -p /usr/share/applications /etc/skel/.config
        cp -f "$mime_src" /usr/share/applications/defaults.list 2>/dev/null || true
        cp -f "$mime_src" /etc/skel/.config/mimeapps.list 2>/dev/null || true

        for uhome in /home/*; do
            [ -d "$uhome" ] || continue
            local uname="$(basename "$uhome")"
            if id "$uname" >/dev/null 2>&1; then
                mkdir -p "$uhome/.config"
                cp -f "$mime_src" "$uhome/.config/mimeapps.list"
                chown "$uname:$uname" "$uhome/.config/mimeapps.list" 2>/dev/null || true
            fi
        done
        log_ok "Default MIME associations registered (Nautilus, GNOME Text Editor, Evince, Celluloid)."
    fi
}

# ------------------------------------------------------------------------------
# 6. DEPLOY KITTY PRESETS & DUAL-THEME SWITCHER CLI
# ------------------------------------------------------------------------------
deploy_dual_theme_engine() {
    log_step "6. Deploying Kitty Theme Presets & Dual-Theme Switcher CLI"

    # Deploy Kitty presets
    if [ -d "$DOTFILES_DIR/kitty/themes" ]; then
        mkdir -p /usr/share/rinauby/kitty/themes
        cp -rf "$DOTFILES_DIR/kitty/themes"/* /usr/share/rinauby/kitty/themes/ 2>/dev/null || true
        
        mkdir -p /etc/skel/.config/kitty/themes
        cp -rf "$DOTFILES_DIR/kitty/themes"/* /etc/skel/.config/kitty/themes/ 2>/dev/null || true

        for uhome in /home/*; do
            [ -d "$uhome" ] || continue
            local uname="$(basename "$uhome")"
            if id "$uname" >/dev/null 2>&1; then
                mkdir -p "$uhome/.config/kitty/themes"
                cp -rf "$DOTFILES_DIR/kitty/themes"/* "$uhome/.config/kitty/themes/" 2>/dev/null || true
                [ -f "$uhome/.config/kitty/current-theme.conf" ] || cp -f "$DOTFILES_DIR/kitty/themes/everforest-dark.conf" "$uhome/.config/kitty/current-theme.conf"
                chown -R "$uname:$uname" "$uhome/.config/kitty" 2>/dev/null || true
            fi
        done
        log_ok "Everforest Dark & Catppuccin Mocha Kitty themes deployed."
    fi

    # Deploy rinauby-theme-switch binary
    if [ -f "$BIN_DIR/rinauby-theme-switch" ]; then
        mkdir -p /usr/local/bin
        cp -f "$BIN_DIR/rinauby-theme-switch" /usr/local/bin/rinauby-theme-switch
        chmod 755 /usr/local/bin/rinauby-theme-switch
        log_ok "Dual-Theme switcher CLI installed to /usr/local/bin/rinauby-theme-switch"
    fi
}

# ------------------------------------------------------------------------------
# 7. COMPREHENSIVE DIAGNOSTIC & VERIFICATION HEALTHCHECK
# ------------------------------------------------------------------------------
verify_rinauby_environment() {
    echo -e "\n${C_BOLD}${C_GOLD}==============================================================================${C_RESET}"
    echo -e "${C_BOLD}${C_GOLD}  RINAUBY (DIGITAL HUMANISM) — SYSTEM & DEPENDENCY AUDIT REPORT              ${C_RESET}"
    echo -e "${C_BOLD}${C_GOLD}==============================================================================${C_RESET}"

    local total_checks=0
    local pass_count=0
    local fail_count=0

    check_item() {
        local category="$1"
        local name="$2"
        local condition="$3"
        total_checks=$((total_checks + 1))
        
        if eval "$condition"; then
            pass_count=$((pass_count + 1))
            printf "  ${C_GREEN}[PASS]${C_RESET} %-20s : %s\n" "[$category]" "$name"
        else
            fail_count=$((fail_count + 1))
            printf "  ${C_RED}[FAIL]${C_RESET} %-20s : %s\n" "[$category]" "$name"
        fi
    }

    echo -e "${C_BOLD}A. Compositor, Shell & Wayland Ecosystem:${C_RESET}"
    check_item "Binary" "Hyprland Compositor" "command -v hyprctl >/dev/null 2>&1"
    check_item "Binary" "Hyprlock Screen Lock" "command -v hyprlock >/dev/null 2>&1"
    check_item "Binary" "Quickshell Native Shell" "command -v quickshell >/dev/null 2>&1"
    check_item "Binary" "Awww / SWWW Wallpaper Engine" "command -v awww >/dev/null 2>&1 || command -v swww >/dev/null 2>&1 || [ -f '$BIN_DIR/awww' ]"
    check_item "Binary" "Rinauby Session Autostart" "command -v rinauby-autostart >/dev/null 2>&1 || [ -f '$BIN_DIR/rinauby-autostart' ]"
    check_item "Binary" "Matugen Dynamic Color Engine" "command -v matugen >/dev/null 2>&1"
    check_item "Binary" "NWG-Displays Monitor Manager" "command -v nwg-displays >/dev/null 2>&1"
    check_item "Binary" "Kitty Terminal Emulator" "command -v kitty >/dev/null 2>&1"
    check_item "Binary" "Fastfetch System Information" "command -v fastfetch >/dev/null 2>&1"
    check_item "Binary" "Starship Shell Prompt" "command -v starship >/dev/null 2>&1"

    echo -e "\n${C_BOLD}B. Desktop Productivity & Media Suite (GTK):${C_RESET}"
    check_item "App" "Nautilus File Manager" "command -v nautilus >/dev/null 2>&1"
    check_item "App" "GNOME Text Editor" "command -v gnome-text-editor >/dev/null 2>&1"
    check_item "App" "Evince Document/PDF Viewer" "command -v evince >/dev/null 2>&1"
    check_item "App" "Celluloid Video/Audio Player" "command -v celluloid >/dev/null 2>&1"
    check_item "App" "Pavucontrol Audio Mixer" "command -v pavucontrol >/dev/null 2>&1"

    echo -e "\n${C_BOLD}C. Theming, Assets & Personalization:${C_RESET}"
    check_item "Theme" "Plymouth Pack 3 'Pixels'" "[ -f /usr/share/plymouth/themes/pixels/pixels.plymouth ] || [ -f '$PLYMOUTH_DIR/pixels/pixels.plymouth' ]"
    check_item "Theme" "SDDM Sugar-Candy Theme" "[ -f /usr/share/sddm/themes/sugar-candy/Main.qml ] || [ -f '$SDDM_DIR/themes/sugar-candy/Main.qml' ]"
    check_item "Artwork" "Mona Lisa (Louvre C2RMF) Wallpaper" "[ -f /usr/share/backgrounds/rinauby/mona_lisa.jpg ] || [ -f '$ASSETS_DIR/wallpapers/mona_lisa.jpg' ]"
    check_item "Prompt" "Starship osyx Capsule Config" "[ -f /etc/skel/.config/starship.toml ] || [ -f '$DOTFILES_DIR/starship/starship.toml' ]"
    check_item "Theme" "Papirus Folders Utility" "command -v papirus-folders >/dev/null 2>&1 || [ -f '$BIN_DIR/papirus-folders' ]"
    check_item "Dual-Theme" "rinauby-theme-switch CLI" "command -v rinauby-theme-switch >/dev/null 2>&1 || [ -f '$BIN_DIR/rinauby-theme-switch' ]"

    echo -e "\n${C_BOLD}D. System Fonts & Classical Typography:${C_RESET}"
    check_item "Font" "Cinzel Serif Typography" "fc-list : family | grep -qi 'Cinzel' 2>/dev/null || [ -f \"$ASSETS_DIR/fonts/Cinzel.ttf\" ]"
    check_item "Font" "EB Garamond Classical Serif" "fc-list : family | grep -qi 'EB Garamond' 2>/dev/null || dpkg -s fonts-ebgaramond >/dev/null 2>&1"
    check_item "Font" "Inter Sans Interface Font" "fc-list : family | grep -qi 'Inter' 2>/dev/null || dpkg -s fonts-inter >/dev/null 2>&1"
    check_item "Font" "JetBrains Mono / Symbols NF" "fc-list : family | grep -qi 'JetBrains' 2>/dev/null || [ -f \"$ASSETS_DIR/fonts/SymbolsNerdFontMono-Regular.ttf\" ]"

    echo -e "\n${C_BOLD}${C_GOLD}------------------------------------------------------------------------------${C_RESET}"
    echo -e "  Total Verifications : ${C_BOLD}$total_checks${C_RESET}"
    echo -e "  Checks Passed       : ${C_GREEN}${C_BOLD}$pass_count${C_RESET}"
    if [ "$fail_count" -gt 0 ]; then
        echo -e "  Checks Needing Pkg  : ${C_YELLOW}${C_BOLD}$fail_count${C_RESET} (will be provisioned when running full installer)"
    else
        echo -e "  Checks Failed       : ${C_GREEN}0${C_RESET}"
    fi
    echo -e "${C_BOLD}${C_GOLD}==============================================================================${C_RESET}"
}

# ------------------------------------------------------------------------------
# ENTRYPOINT & COMMAND EXECUTION
# ------------------------------------------------------------------------------
ACTION="${1:---install}"

case "$ACTION" in
    --install|install)
        deploy_plymouth_pixels
        deploy_sddm_sugar_candy
        deploy_starship_prompt
        deploy_papirus_folders
        deploy_default_apps_and_mime
        deploy_dual_theme_engine
        verify_rinauby_environment
        ;;
    --check|check)
        verify_rinauby_environment
        ;;
    --theme|theme)
        shift
        bash "$BIN_DIR/rinauby-theme-switch" "$@"
        ;;
    *)
        echo "Usage: $0 {--install|--check|--theme [classic|modern|toggle|status]}"
        exit 1
        ;;
esac
