# Rinauby — GTK4 / Libadwaita Desktop Settings Specification

Dokumen ini menjelaskan arsitektur teknis, panduan tata letak simetris, dan integrasi desktop untuk aplikasi **Pengaturan Rinauby (`rinauby-settings`)**.

---

## 1. Tinjauan & Standar HIG
Aplikasi pengaturan Rinauby dibangun dengan **GTK 4.0** dan **Libadwaita 1.0** mengikuti standar resmi GNOME HIG dan filosofi Digital Humanism:
- **Jendela Mengambang (Floating Window):** Dimensi seimbang `880px × 600px`, sudut membulat `14px`, dengan elevasi bayangan jatuh alami (`box-shadow: 0 16px 40px rgba(0,0,0,0.55)`), kontras tonal, dan hairline halus `1px solid rgba(255, 255, 255, 0.06)` tanpa outline tebal berwarna yang terkesan 'AI generated'.
- **Konten Terukur (`Adw.Clamp`):** Dibatasi pada lebar maksimum `640px` (dengan ambang `520px`) untuk menjaga proporsi kartu dan teks agar tidak meregang berlebihan yang menciptakan ruang kosong visual.
- **Tinggi Baris Proporsional:** Baris pengaturan berukuran standar HIG `44px` dengan padding vertikal `6px` dan horizontal `14px`.
- **Headerbar Mandiri:** Judul halaman terpusat secara presisi tanpa terpotong (*no ellipsis*).
- **Bebas Karakter Emoji:** Menggunakan ikon simbolik standar Freedesktop / GTK dan tipografi bersih.

---

## 2. Struktur Modul & Lokasi Berkas

Direktori aplikasi: [`assets/dotfiles/settings-gtk/`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/dotfiles/settings-gtk/)

```text
settings-gtk/
├── main.py              # Titik masuk utama aplikasi (Adw.Application & SettingsMainWindow)
├── sidebar.py           # Sidebar navigasi terkelompok dengan pencarian langsung (live search)
├── style.css            # Stylesheet tema gelap emas Renaissance GTK4 (Proporsional & Simetris)
├── backend.py           # Backend pengelola konfigurasi JSON, nmcli, bluetoothctl, & Hyprland
├── widgets.py           # NumericSlider, NumericSliderRow, enhance_spin_row
├── app_detector.py      # Pemindai aplikasi desktop terpasang sistem
└── pages/
    ├── wifi_page.py         # Pengaturan Wi-Fi (Sinyal, Terhubung, Tersedia, Mode Pesawat)
    ├── bluetooth_page.py    # Pengaturan Bluetooth (Perangkat Terhubung, Tersimpan, Visibilitas)
    ├── appearance_page.py   # Mode Tampilan, Angka Romawi, Border Emas
    ├── wallpaper_page.py    # Galeri Wallpaper Karya Seni Renaisans
    ├── gtk_theme_page.py    # Pemilih Tema GTK, Ikon, dan Kursor
    ├── general_page.py      # Hyprland Core: Tata Letak, Celah, Border, Blur, Shadow, Input
    ├── window_rules_page.py # Visual Manager Aturan Jendela (windowrulev2)
    ├── default_apps_page.py # Pemilih Aplikasi Bawaan Sistem
    ├── execs_page.py        # Pengelola Layanan & Aplikasi Startup
    ├── env_page.py          # Variabel Sesi Lingkungan Wayland & GPU
    ├── bar_page.py          # Pengaturan Panel Waybar
    ├── dock_lock_page.py    # Pengaturan Layar Kunci Hyprlock
    ├── audio_page.py        # Proteksi Lonjakan Volume & Efek Bunyi
    ├── power_page.py        # Ambang Batas Baterai & Suspensi Otomatis
    ├── shortcuts_page.py    # Tabel Pintasan Keyboard Super Keybinds
    └── about_page.py        # Informasi Spesifikasi Rinauby & Diagnostik Sistem
```

---

## 3. Kompatibilitas Hyprland Ubuntu PPA

Pada distribusi Ubuntu dengan paket Hyprland PPA:
- Setiap perubahan pada pengaturan umum (celah *gaps*, bingkai *border*, radius sudut, blur, bayangan, animasi, sensitivitas kursor) dan aturan jendela langsung ditulis ke `~/.config/hypr/rinauby_overrides.conf`.
- Berkas tersebut di-*source* otomatis oleh `hyprland.conf`:
  ```ini
  source = ~/.config/hypr/rinauby_overrides.conf
  ```
- Perubahan visual diterapkan seketika tanpa menutup sesi pengguna melalui panggilan `hyprctl reload`.

---

## 4. Akses Cepat & Integrasi Desktop
- **Pintasan Keyboard:** `Super + I` atau `Super + ,`
- **File Desktop Entry:** `~/.local/share/applications/rinauby-settings.desktop`
- **Panduan Desain Lengkap:** [`docs/rinauby_gtk_design_guide.md`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/docs/rinauby_gtk_design_guide.md)
