# 🏛️ Ringkasan Konteks Proyek: Rinauby (Digital Humanism Edition)
**Tugas Besar Praktikum Sistem Operasi 2026 | Remastering Distro Ubuntu via Cubic**  
**Dokumen Konsolidasi Riwayat Diskusi (`agy1.md` & `agy2.md`)**

---

## 1. Identitas, Latar Belakang, & Filosofi Proyek

* **Mata Kuliah / Tugas**: Tugas Besar Praktikum Sistem Operasi (Tubes SO - 2604).
* **Objektif Utama**: Melakukan *remastering* ISO Linux Ubuntu menggunakan aplikasi **Cubic** (*Custom Ubuntu ISO Creator*), dengan seluruh tahapan pengujian dan live demo wajib berjalan lancar pada **Oracle VM VirtualBox**.
* **Nama Distro Resmi**: **Rinauby**
  * *Edisi*: **Digital Humanism Edition**
  * *Aturan Penamaan Mutlak*: **Dilarang menggunakan kata "OS"** (nama resmi adalah **Rinauby**, bukan *Renaissance OS* atau *School of Athens OS*).
* **Basis Distro**: Ubuntu 24.04 LTS (Noble) / Ubuntu 26.04 (Resolute).
* **Filosofi Inti**:
  1. **Rebirth of Knowledge**: Mengambil analogi zaman Renaissance, sistem *proprietary* tertutup diibaratkan Abad Kegelapan; gerakan *Open Source* adalah pencerahan yang mengembalikan transparansi kode ke komunitas.
  2. **Digital Humanism & Kedaulatan Pengguna**: Menempatkan manusia dan akal budi di pusat komputasi. Lingkungan desktop dibuat bersih, bebas distraksi metrik angka yang memicu kecemasan (*zero cognitive clutter*), efisien, dan *keyboard-driven*.
  3. **Agora Intelektual (School of Athens)**: Terinspirasi lukisan mahakarya Raphael; ruang kerja sebagai tempat berdiskusi dan berkreasi secara bebas.

---

## 2. Riwayat Evaluasi Teknis & Keputusan Arsitektur

Sepanjang diskusi pada `agy1.md` dan `agy2.md`, terjadi beberapa iterasi penting dalam pemilihan teknologi antarmuka:

### A. Quickshell vs Waybar
* **Eksperimen**: Quickshell (yang digunakan pengguna di sistem harian Arch) sempat dicoba diduplikasi untuk tema Renaissance.
* **Evaluasi**: Quickshell berbasis C++ dan Qt6 QML bleeding-edge, memakan terlalu banyak dependensi berat, rawan gagal kompilasi di chroot Cubic Ubuntu, dan banyak modul bawaan yang tidak diperlukan.
* **Keputusan Akhir**: **Menggunakan Waybar**. Jauh lebih ringan, modular, stabil, mudah dikonfigurasi melalui JSONC + CSS, serta aman dipaketkan ke lingkungan remastering Ubuntu.

### B. Sway vs Hyprland
* **Eksperimen**: Sway sempat diuji coba (mode *nested* dan sesi login langsung) karena pertimbangan kestabilan grafis VirtualBox (`VBoxSVGA`) yang membutuhkan software fallback (*pixman/llvmpipe*).
* **Evaluasi**: Sway tidak mendukung efek visual modern secara *native* (tanpa *swayfx* yang tidak resmi), seperti *blur*, sudut membulat (*rounded corners*), dan bayangan (*shadows*). Pengguna merasa tampilannya kaku dan kalah estetis dibanding GNOME bawaan.
* **Keputusan Akhir**: **Kembali ke Hyprland (Wayland)**. Hyprland memberikan estetika *glassmorphism*, *blur layer rules*, animasi halus, dan kontrol tiling modern yang presisi. Untuk VirtualBox, digunakan variabel lingkungan fallback (`WLR_NO_HARDWARE_CURSORS=1`, `WLR_RENDERER=pixman`).

### C. Strategi Pengujian Host (Arch Linux)
* Untuk merancang dan menguji seluruh dotfiles tanpa merusak konfigurasi harian pengguna di Arch Linux, dibuat skrip switcher: [`assets/toggle_renaissance.sh`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/toggle_renaissance.sh).
* Skrip ini menonaktifkan Quickshell sementara, menerapkan wallpaper *School of Athens*, memicu *reload* Hyprland, serta menjalankan Waybar, SwayNC, dan daemon OSD Rinauby. Menjalankan skrip kembali akan mengembalikan sesi normal pengguna.

---

## 3. Standar & Aturan Desain Mutlak (Design Guidelines)

Berdasarkan dokumen [`docs/rinauby_gtk_design_guide.md`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/docs/rinauby_gtk_design_guide.md) dan arahan pengguna:

1. **Larangan Mutlak Penggunaan Emoji**:
   * Dilarang keras menggunakan emoji Unicode berwarna-warni (seperti 🏛, ⚙, 🔒, dsb.) pada UI, header, tombol, sidebar GTK, maupun status bar.
   * Wajib menggunakan **Nerd Font Glyphs** (`Symbols Nerd Font Mono`) atau ikon simbolik standar Freedesktop/GTK monokrom.
2. **Anti-Wireframe / Anti-AI Outline**:
   * Hindari garis pembatas (*outline border*) tipis berwarna emas yang melingkari setiap modul atau kartu secara berlebihan (terkesan seperti buatan AI).
   * Gunakan kedalaman warna tonal (*tonal depth*), kontras latar belakang halus, dan bayangan lembut (*soft natural shadow*).
3. **Standar Proporsi & Tata Letak GTK4 / Libadwaita**:
   * Konten pengaturan dibatasi menggunakan `Adw.Clamp` dengan lebar maksimum **`640px`** agar simetris dan tidak melebar tak terkontrol.
   * **Bebas Teks Terpotong (*No Ellipsis/Clipping*)**: Tinggi baris sidebar dan padding telah diaudit agar huruf tidak terpotong (seperti kasus teks *"Tampilan"* yang sempat terpotong menjadi *"Iampilan"*).
4. **Standardisasi Bahasa**:
   * Seluruh teks antarmuka (Rofi, Settings GTK, label wallpaper, tooltip, menu sesi) distandardisasi ke dalam **Bahasa Inggris** (*English UI*).
5. **Palet Warna Resmi (Everforest Warm Renaissance)**:
   * **Base Background**: `#1c2125` / `#232a2e` / `#2d353b` (Warm Slate / Charcoal).
   * **Foreground / Text**: `#d3c6aa` (Antique Parchment / Cream Marble).
   * **Accent Primary (Gold)**: `#db9c5e` (Ochre Gold) & `#e5c07b` (Renaissance Gold).
   * **Muted / Border**: `#4a555b` / `#7a8478`.
   * **Alert / Red**: `#e67e80` (Terracotta Red).
   * **Success / Green**: `#a7c080` (Olive Green).
6. **Tipografi Resmi**:
   * **Serif Klasik**: `Cinzel` & `EB Garamond` (digunakan pada nomor workspace Romawi, judul dialog modal, jam Waybar, dan kutipan filosofis).
   * **Modern / Sans / Body**: `Inter` / `Noto Sans`.
   * **Monospace & Glyphs**: `JetBrains Mono NF` & `Symbols Nerd Font Mono`.

---

## 4. Rincian Komponen & Spesifikasi Antarmuka yang Telah Dibangun

Seluruh file implementasi berada di dalam folder [`assets/dotfiles/`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/dotfiles/) dan dieksekusi melalui wrapper di [`assets/bin/`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/bin/).

### A. Top Bar: Waybar
* **File**: [`assets/dotfiles/waybar/config.jsonc`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/dotfiles/waybar/config.jsonc) & [`style.css`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/dotfiles/waybar/style.css).
* **Tata Letak**:
  * Tinggi 32px, menempel rapat ke batas atas (`margin-top: 0`), border bawah tipis 2px keemasan (`#db9c5e`).
  * Efek akrilik gelap transparan (`rgba(28, 33, 37, 0.82)`) dipadukan dengan Hyprland layer-rule: `blur, waybar`.
* **Modul**:
  * **Kiri**: Logo Renaissance (`custom/logo` - ikon arsitektur klasik pilar/kuil, menggantikan ikon Arch terdahulu) + Workspace Angka Romawi (`I`, `II`, `III`, `IV`, `V`).
  * **Tengah**: Kutipan Humanisme Klasik (`custom/quote` via `rinauby-quote` / `quote_rotator.sh`). Menampilkan semboyan Latin legendaris (*Ad Astra Per Aspera*, *Sapere Aude*, *Cogito Ergo Sum*, *Veritas Vos Liberabit*, dsb.) yang berotasi otomatis; tooltip menampilkan terjemahan dan filsuf pencetus.
  * **Kanan**: Audio (Wireplumber/PulseAudio), Jaringan/WiFi, Baterai (jika laptop), Jam/Kalender (`Cinzel`), dan Tombol Power.
  * **Catatan Desain**: *Zero Module Background* (modul tidak dibungkus kotak-kotak pil warna-warni terpisah, melainkan mengambang elegan di atas bilah).

### B. Fastfetch
* **File**: [`assets/dotfiles/fastfetch/config.jsonc`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/dotfiles/fastfetch/config.jsonc).
* **Logo ASCII**: Menggunakan seni ASCII Pilar Klasik Ionic ([`pillar.txt`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/dotfiles/fastfetch/pillar.txt)) atau Kuil Athena ([`temple.txt`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/dotfiles/fastfetch/temple.txt)).
* **Informasi Sistem**: Menampilkan identitas `OS: Rinauby (Digital Humanism Edition)`, Kernel, WM Hyprland, Terminal, CPU, RAM, Uptime dengan palet warna emas dan slate.

### C. Application Launcher (Rofi)
* **File**: [`assets/dotfiles/rofi/renaissance_launcher.rasi`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/dotfiles/rofi/renaissance_launcher.rasi), dipanggil via [`assets/bin/rinauby-launcher`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/bin/rinauby-launcher).
* **Format**: Center floating modal dengan latar gelap ber-blur, tipografi serif `Cinzel` & `EB Garamond`, outline bersih tanpa garis AI kaku, dan pencarian aplikasi cepat.

### D. Wallpaper Selector (Rofi Grid)
* **File**: [`assets/dotfiles/rofi/wallpaper_grid.rasi`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/dotfiles/rofi/wallpaper_grid.rasi) & [`wp_selector.sh`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/dotfiles/rofi/wp_selector.sh), dipanggil via [`assets/bin/rinauby-wp-selector`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/bin/rinauby-wp-selector).
* **Koleksi Wallpaper**: Dipotong presisi ke rasio 16:10 (**1920×1200**) dengan thumbnail *edge-to-edge* di `.thumbs`:
  1. *School of Athens* (Raphael)
  2. *The Creation of Adam* (Michelangelo)
  3. *The Last Supper* (Leonardo da Vinci)
  4. *The Birth of Venus* (Sandro Botticelli)
  5. *Primavera* (Sandro Botticelli)
  6. *The Tower of Babel* (Pieter Bruegel the Elder)
  7. *The Annunciation* (Leonardo da Vinci)
  8. *Classical Ruins with Figures* (Claude Lorrain)
* **Integrasi**: Hyprland mengaktifkan efek backdrop blur sangat tipis saat pemilih wallpaper dibuka.

### E. Pusat Notifikasi & Kontrol: SwayNC
* **File**: [`assets/dotfiles/swaync/config.json`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/dotfiles/swaync/config.json) & [`style.css`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/dotfiles/swaync/style.css).
* **Desain**: Panel slide dari kanan layar, popup simetris dengan margin yang telah dirapikan, palet gelap Everforest, quick toggles, slider volume/kecerahan, dan riwayat notifikasi.

### F. Power Menu, Lockscreen, & OSD
* **Power Menu**: Modal Rofi 5 tombol horizontal (*Lock, Suspend, Logout, Reboot, Shutdown*) via [`assets/bin/rinauby-powermenu`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/bin/rinauby-powermenu) ([`powermenu.sh`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/dotfiles/scripts/powermenu.sh) & [`powermenu.rasi`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/dotfiles/rofi/powermenu.rasi)).
* **Lockscreen**: [`assets/dotfiles/hypr/hyprlock.conf`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/dotfiles/hypr/hyprlock.conf) dengan wallpaper latar ber-blur, jam serif klasik di tengah, teks salam, dan kotak kata sandi berbingkai emas.
* **OSD Indicator**: Popup kapsul mengambang untuk penyesuaian volume dan kecerahan via [`assets/bin/rinauby-osd`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/bin/rinauby-osd) ([`osd.py`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/dotfiles/scripts/osd.py)).
* **Screenshot Tool**: [`assets/bin/rinauby-screenshot`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/bin/rinauby-screenshot) ([`screenshot.sh`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/dotfiles/scripts/screenshot.sh)) mendukung mode *Area*, *Full Screen*, dan *Active Window* menggunakan `grim`, `slurp`, dan `swappy`.

### G. Aplikasi Pengaturan Desktop: `rinauby-settings` (GTK4 / Libadwaita / Python)
* **File Utama**: [`assets/dotfiles/settings-gtk/`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/dotfiles/settings-gtk/) (`main.py`, `sidebar.py`, `style.css`, `backend.py`, folder `pages/`).
* **Fitur**: Aplikasi GUI mandiri berbasis `Adw.Application` dengan sidebar navigasi pencarian instan dan 16 halaman pengaturan lengkap:
  1. *Displays* (Resolusi, refresh rate, scaling)
  2. *Appearance* (Gaps, borders, radius pembulatan sudut)
  3. *Wallpapers* (Koleksi lukisan klasik)
  4. *Keybindings* (Daftar pintasan keyboard)
  5. *Windows* (Aturan tata letak jendela & opacity)
  6. *Bar (Waybar)* (Kustomisasi status bar)
  7. *Audio / Sound* (Output, input, volume)
  8. *Wi-Fi & Network* (Status koneksi)
  9. *Bluetooth* (Status perangkat)
  10. *Default Applications* (Browser, editor, terminal, file manager)
  11. *Environment Variables* (Variabel sesi Wayland)
  12. *Window Rules* (Aturan floating/tiling per aplikasi)
  13. *Launchers* (Pengaturan Rofi)
  14. *Search & Safety* (Filter pencarian)
  15. *Dock & Lock* (Pengaturan hyprlock & sesi)
  16. *About* (Spesifikasi sistem dan filosofi Rinauby)
* **Standar Mutlak**: Lebar terikat `Adw.Clamp` (640px), bebas emoji (menggunakan simbol standar GTK), bahasa Inggris menyeluruh, dan tidak ada teks label yang terpotong.

---

## 5. Pemetaan Pintasan Papan Ketik (Keybindings)

Pintasan keyboard utama yang aktif dalam sesi Rinauby:

| Shortcut | Aksi / Perintah | Keterangan |
| :--- | :--- | :--- |
| `Super + Space` / `Super + D` | `rinauby-launcher` | Membuka Application Launcher (Rofi) |
| `Super + I` | `rinauby-settings` | Membuka Panel Pengaturan Desktop GTK4 |
| `Super + K` / `Ctrl + Super + T` | `rinauby-wp-selector` | Membuka Pemilih Wallpaper Klasik |
| `Super + Backspace` / `Super + Esc` | `rinauby-powermenu` | Membuka Kontrol Sesi / Power Menu |
| `Super + L` | `hyprlock` | Mengunci Layar (Lockscreen) |
| `Super + A` / `Super + N` | `swaync-client -t -sw` | Membuka Control Center & Riwayat Notifikasi |
| `Super + Shift + S` | `rinauby-screenshot area` | Mengambil Tangkapan Layar Area Pilihan |
| `PrintScreen` | `rinauby-screenshot full` | Mengambil Tangkapan Layar Penuh |
| `Super + Enter` | `kitty` | Membuka Terminal Kitty |
| `Super + Q` | `hyprctl dispatch killactive` | Menutup Jendela Aktif |

---

## 6. Titik Akhir Diskusi & Status Terkini (End of `agy2.md`)

Di bagian akhir berkas `agy2.md`, seluruh pekerjaan desain antarmuka, aset dotfiles, font, wallpaper, dan aplikasi pengaturan telah selesai dan terverifikasi visual di Arch Linux.

Pengguna memberikan instruksi terakhir:
> *"Bisakah kamu membuat script instalasi install.sh atau setup.sh untuk ubuntunya, yg menyiapkan semuanya, mulai dari hyprland, waybar, rofi, wallpaper, settings-gtk, fastfetch, dll. Serta konfigurasi autostart atau display managernya jika diperlukan."*

Sebelum instruksi tersebut tereksekusi secara tuntas, sesi terhenti karena batas kapasitas token / kuota model (*502 Bad Gateway / Usage Limit Reached*).

---

## 7. Langkah Selanjutnya yang Siap Dikerjakan (Next Action Items)

1. **Pembuatan Script Otomasi Instalasi (`setup.sh` / `install.sh`)**:
   * Skrip instalasi otomatis untuk dijalankan di lingkungan chroot Cubic (Ubuntu 24.04/26.04).
   * Menambahkan dependensi paket APT (Hyprland PPA / release binary, Waybar, Rofi-Wayland, SwayNC, Hyprlock, Kitty, Fastfetch, PyGObject, python3-gi, gir1.2-adw-1, fonts, swww / swaybg, grim, slurp, swappy, polkit-gnome).
2. **Penyebaran Konfigurasi Global (`/etc/skel/` & `/usr/share/`)**:
   * Menyalin dotfiles ke `/etc/skel/.config/` agar setiap user baru dan live user ISO otomatis memiliki desktop Rinauby yang siap pakai.
   * Memasang file binary ke `/usr/local/bin/` (`rinauby-*`).
   * Memasang wallpaper ke `/usr/share/backgrounds/rinauby/` dan font ke `/usr/share/fonts/rinauby/`.
3. **Display Manager & Sesi Wayland**:
   * Menyiapkan desktop session entry di `/usr/share/wayland-sessions/hyprland.desktop`.
   * Mengonfigurasi Display Manager (GDM3 / SDDM / Greetd) dengan opsi autologin untuk pengguna live ISO (`ubuntu` atau `rinauby`).
4. **Branding Plymouth & GRUB (Syarat Tugas SO)**:
   * Menyiapkan splash screen boot Plymouth bertema *Rinauby* dengan logo pilar klasik Ionic untuk menggantikan logo Ubuntu bawaan.
5. **Uji Coba & Eksekusi di Cubic**:
   * Uji coba boot ISO hasil remastering pada Oracle VM VirtualBox untuk memastikan **100% bebas black screen**.

