# School of Athens — Power Menu, Lockscreen & OSD Specification Guide

Dokumen ini menjelaskan implementasi teknis, estetika visual, serta pertimbangan arsitektur untuk modul **Power Menu (Session Controls)**, **Lockscreen**, dan **OSD Indicator (Volume & Brightness)** pada tema **School of Athens**.

---

## 1. Power Menu (Session Controls Modal)

Berdasarkan rancangan visual `ui/renaissance_power_menu.png`, Power Menu diwujudkan sebagai modal dialog horizontal yang elegan di tengah layar dengan aksen emas Renaissance (`#db9c5e`) dan latar belakang arang gelap (`#1a1d21`).

### A. Lokasi File
- **Rofi Theme:** `assets/dotfiles/rofi/powermenu.rasi`
- **Launcher Script:** `assets/dotfiles/scripts/powermenu.sh`
- **Ikon Vektor Klasik:** `assets/dotfiles/rofi/icons/`
  - `lock.svg`: Gembok emas beraksen shackle toska.
  - `suspend.svg`: Bulan sabit hangat bernuansa emas (*warm gold*).
  - `logout.svg`: Daun pintu kayu klasik klasik beraksen kuningan.
  - `reboot.svg`: Panas ganda melingkar (*dual sync*) toska dan emas.
  - `shutdown.svg`: Simbol power ruby dengan aksen busur emas.

### B. Tombol & Aksi
| Tombol | Ikon | Perintah yang Dijalankan |
|---|---|---|
| **LOCK** | `lock.svg` | `hyprlock -c assets/dotfiles/hypr/hyprlock.conf` |
| **SUSPEND** | `suspend.svg` | `systemctl suspend` |
| **LOGOUT** | `logout.svg` | `hyprctl dispatch exit` (fallback `pkill -KILL -u $USER`) |
| **REBOOT** | `reboot.svg` | `systemctl reboot` |
| **SHUTDOWN** | `shutdown.svg` | `systemctl poweroff` |

### C. Pintasan Keyboard (Keybinding)
- `Super + Backspace` atau `Super + Escape` membuka menu Session Controls seketika.

---

## 2. Lockscreen (`hyprlock`) & Pertimbangan Stabilitas Ubuntu

Konfigurasi lockscreen dibangun di `assets/dotfiles/hypr/hyprlock.conf`, mengadaptasi konfigurasi host pengguna dengan palet *School of Athens* (wallpaper mahakarya Raphael, border input emas `#db9c5e`, tipografi klasik *Cinzel* dan *Inter*).

### A. Analisis Kompatibilitas Hyprlock: Arch Linux Host vs Ubuntu (Tubes-2604)
Pengguna menanyakan: *"Untuk lockscreen apakah bisa pakai hyprlock dan salin saja persis kode hyprlock di .config/hypr/hyprland saya, tapi kalo hyprlock di ubuntu gak stabil, kita pertimbangkan dulu."*

Berikut analisis arsitektur mendalam:

1. **Status di Host Pengguna (Arch Linux):**
   - Paket `hyprlock v0.9.7` terpasang secara native.
   - Menggunakan konfigurasi PAM `/etc/pam.d/hyprlock` berbasis `system-auth`.
   - Sangat stabil, responsif, dan terintegrasi penuh dengan Hyprland compositor.

2. **Tantangan Stabilitas di Target Ubuntu ISO (Noble 24.04 / Tubes-2604):**
   - **Ketiadaan Paket Resmi di Repositori Canonical:** Ubuntu 24.04 LTS tidak menyediakan paket `hyprlock` di repositori `main` maupun `universe`. Untuk memasangnya di ISO Tubes-2604, paket harus dikompilasi manual dari sumber atau dipasang via PPA eksternal.
   - **Perbedaan Arsitektur PAM (Paling Kritis):**
     - Di Arch Linux: PAM menggunakan directive `auth include system-auth`.
     - Di Ubuntu/Debian: Berkas `system-auth` **tidak ada**. Ubuntu menggunakan `/etc/pam.d/common-auth`.
     - *Konsekuensi:* Jika `hyprlock` dipasang tanpa memperbarui konfigurasi PAM menjadi `auth include common-auth`, sesi lockscreen akan mengalami kegagalan autentikasi (user tidak bisa login kembali/terkunci).
   - **Masalah Versi Dependensi wlroots/hyprutils:** Ubuntu LTS memiliki pustaka `wayland`, `mesa`, dan compiler GCC/Clang yang versinya sering kali lebih lawas dibandingkan dependensi minimum Hyprland/Hyprlock upstream, sehingga berisiko *crash* saat wake-up dari suspend.

3. **Rekomendasi Arsitektur untuk Tubes-2604:**
   - **Host Pengujian (Arch Linux):** Gunakan `assets/dotfiles/hypr/hyprlock.conf` secara langsung via `Super + L`.
   - **Produksi Live ISO Ubuntu (Cubic):**
     - Opsi A (Hyprlock): Buat berkas `/etc/pam.d/hyprlock` berisi:
       ```pam
       auth        include     common-auth
       account     include     common-account
       password    include     common-password
       session     include     common-session
       ```
     - Opsi B (Fallback Tanpa Masalah): Sediakan `gtklock` (`sudo apt install gtklock`) atau `swaylock-effects` yang sudah resmi dan teruji stabil 100% di Ubuntu. Skrip `powermenu.sh` sudah dirancang cerdas dengan fallback otomatis: mendeteksi `hyprlock` terlebih dahulu, lalu otomatis jatuh ke `gtklock` atau `swaylock` jika `hyprlock` tidak ditemukan di sistem.

---

## 3. OSD Indicator (Volume & Brightness Pill Capsules)

Berdasarkan rancangan visual `ui/renaissance_osd.png`, indikator volume dan brightness ditampilkan berupa kapsul pil (*pill capsule*) melayang di bagian bawah tengah layar.

### A. Lokasi File & Arsitektur
- **Skrip Indikator:** `assets/dotfiles/scripts/osd.py`
- **Teknologi:** Python 3 + `GtkLayerShell` + `Cairo` vector rendering (tanpa dependensi root, ringan, native Wayland Layer Shell).
- **Socket IPC:** `/tmp/school_of_athens_osd.sock`

### B. Karakteristik Desain (Pixel-Perfect terhadap Mockup)
- **Geometri:** Kapsul pil dengan ukuran `width: 340px`, `height: 46px`, `border-radius: 23px`.
- **Warna & Efek:** Latar belakang arang transparan gelap `rgba(24, 27, 31, 0.94)` dengan garis tepi emas halus (*gold hairline*) `#db9c5e`.
- **Badge Ikon Melingkar:**
  - Volume: Ikon speaker toska/cyan `󰕾` (atau `󰝟` merah lembut saat mute) dalam lingkaran gelap bertepi emas tipis.
  - Brightness: Ikon matahari emas hangat `󰃠` dalam lingkaran gelap bertepi emas tipis.
- **Track Slider:** Rel abu-abu gelap dengan isi kemajuan berwarna emas Renaissance (`#db9c5e`).
- **Persentase Teks:** Huruf tebal Inter di sisi kanan (misalnya `28%`, `72%`, `85%`) berwarna krem hangat.

### C. Mekanisme Kerja & Integrasi
1. Saat mode *School of Athens* diaktifkan (`toggle_renaissance.sh`), daemon OSD berjalan di latar belakang.
2. Ketika tombol volume atau kecerahan ditekan:
   - Volume dinaikkan/diturunkan via `wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+` / `5%-`.
   - Kecerahan diatur via `brightnessctl set 5%+` / `5%-`.
   - Perintah dikirim ke daemon via UNIX socket dalam hitungan milidetik.
   - Kapsul meluncur tampil di layar bawah tengah tanpa mengambil fokus keyboard (*zero focus steal*).
   - Menghilang otomatis setelah 1,5 detik tanpa aktivitas. Jika tombol ditekan berulang kali, timer 1,5 detik direset mulus tanpa kedip (*zero flicker*).

### D. Pintasan Tombol Media di Hyprland (`shellOverrides/main.lua`)
- `XF86AudioRaiseVolume` -> `osd.py volume-up`
- `XF86AudioLowerVolume` -> `osd.py volume-down`
- `XF86AudioMute` -> `osd.py volume-mute`
- `XF86MonBrightnessUp` -> `osd.py brightness-up`
- `XF86MonBrightnessDown` -> `osd.py brightness-down`
