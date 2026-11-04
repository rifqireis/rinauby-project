#!/usr/bin/env bash
# ==============================================================================
# CLEANUP ACCIDENTAL SYSTEM FILES ON ARCH LINUX HOST
# Menghapus file sistem /usr/ dan /etc/ yang sempat disalin oleh install.sh
# ==============================================================================

if [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] Jalankan script ini sebagai root: sudo ./clean_arch_host.sh"
    exit 1
fi

echo "Membersihkan file sistem Rinauby dari Arch Linux host..."

# 1. Hapus konfigurasi font khusus Ubuntu & font rinauby
rm -f /etc/fonts/conf.d/60-rinauby-fonts.conf
rm -rf /usr/local/share/fonts/rinauby
fc-cache -fv >/dev/null 2>&1

# 2. Hapus aset latar belakang & share Rinauby
rm -rf /usr/share/backgrounds/rinauby
rm -rf /usr/share/rinauby

# 3. Hapus binary wrapper rinauby-* di /usr/local/bin/
rm -f /usr/local/bin/rinauby-*

# 4. Hapus desktop entry
rm -f /usr/share/applications/rinauby-settings.desktop

# 5. Bersihkan /etc/skel/.config yang sempat tersalin
rm -rf /etc/skel/.config/hypr \
       /etc/skel/.config/waybar \
       /etc/skel/.config/rofi \
       /etc/skel/.config/swaync \
       /etc/skel/.config/kitty \
       /etc/skel/.config/fastfetch \
       /etc/skel/.config/scripts \
       /etc/skel/.config/rinauby \
       /etc/skel/.local/share/backgrounds/rinauby

echo "[OK] Seluruh file sistem Arch Linux host telah bersih 100%!"

