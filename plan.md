# Master Plan: Renaissance OS (Digital Humanism Edition)
**Remastering Ubuntu via Cubic | Praktikum Sistem Operasi 2026**
*Target Pengerjaan: 3 Hari*

---

## 1. Visi, Tema, & Filosofi Desain
* **Identitas Distro**: *Renaissance OS (Digital Humanism Edition)*
* **Basis**: Ubuntu 26.04 LTS (Resolute)
* **Filosofi Inti**: Mengambil inspirasi dari lukisan *Scuola di Atene* karya Raphael dan semangat Renaissance:
  * Rebirth of Knowledge (Open Source sebagai pencerahan dari sistem proprietary tertutup).
  * Digital Humanism & Kedaulatan Pengguna (Sistem yang dapat dimodifikasi total, keyboard-driven, transparan).
  * Estetika Klasik & Tipografi: Angka Romawi (`I`, `II`, `III`, `IV`), pilar arsitektur klasik (Corinthian/Ionic column), palet Everforest Dark Slate (`#2d353b`), Cream Parchment (`#d3c6aa`), dan Renaissance Gold (`#db9c5e`).

---

## 2. Standar Desain & Aturan Mutlak Implementasi

> [!IMPORTANT]
> **Aturan Wajib Tampilan & Tipografi:**
> 1. **Dilarang Keras Menggunakan Emoji:** Sama sekali tidak boleh menggunakan emoji warna-warni Unicode (seperti gembok, pintu, petir, folder emoji, dll.). Seluruh ikon wajib menggunakan **Nerd Font Glyphs** (Font Awesome / Material Design Icons via `Iosevka Nerd Font` / `JetBrains Mono NF`) atau vektor SVG monokrom beraksen emas `#db9c5e` / parchment `#d3c6aa`.
> 2. **Ukuran Font Terkontrol & Proporsional:** Font tidak boleh kebesaran (*oversized*). Ukuran body UI 11px - 13px, label kecil 10px, header/modal 16px - 18px.
> 3. **Larangan Simbol Em-Dash ("—"):** Hindari karakter em-dash panjang. Gunakan pemisah bersih seperti pipa vertikal (`|`), titik dua (`:`), atau tanda hubung standar (`-`).
> 4. **Konsistensi Font Family:**
>    * Serif klasik (`EB Garamond` / `Cinzel`): Khusus untuk nomor workspace Romawi (`I`, `II`, `III`, `IV`) dan judul modal utama.
>    * Monospace tajam (`Iosevka Nerd Font` / `JetBrains Mono NF`): Untuk seluruh isi teks terminal, file path, status bar, kontrol sistem, dan deskripsi aplikasi.

---

## 3. Arsitektur Shell Lengkap (Full Desktop Ecosystem)
Daftar seluruh komponen antarmuka dan perkakas shell yang disiapkan di ricing Wayland dan dipetakan ke Ubuntu:

| No | Komponen Shell | Perangkat Lunak | Deskripsi & Perilaku Interaksi | Shortcut / Trigger |
| :--- | :--- | :--- | :--- | :--- |
| 1 | **Compositor / WM** | **Sway (Wayland)** | Window tiling simetris, gaps, border emas `#db9c5e`, stabil di VirtualBox dengan software fallback (*pixman*). | Inti Sesi |
| 2 | **Top Status Bar** | **Waybar (Top)** | Workspace Romawi (`I`, `II`, `III`, `IV`), active window title, metrik CPU/RAM, baterai, jam klasik. | Selalu Tampil |
| 3 | **Side Dock / Toolbelt** | **Waybar (Left Vertical)** | Bar vertikal tipis di sisi kiri layar untuk aplikasi favorit (Terminal, Neovim, Browser, File Manager, Settings). | Auto-hide / Edge hover |
| 4 | **Wallpaper Selector** | **Rofi Grid Picker (`wp-selector.sh`)** | Grid modal (2 baris x 4 kolom) menampilkan thumbnail lukisan klasik. Memilih gambar langsung menerapkan wallpaper via `swaybg`. | `Super + Alt + W` / Klik Icon Bar |
| 5 | **Application Launcher** | **Rofi (`rofi-wayland`)** | Modal terpusat di tengah layar bergaya katalog klasik dengan pencarian literatur & perkakas. | `Super + D` / `Super + Space` |
| 6 | **Control Center & Drawer** | **SwayNC (Notification Center)** | Laci samping geser dari kanan: Quick Toggles (Wi-Fi, Bluetooth, Night Light, Power), Sliders (Volume, Brightness), Media Player widget, dan riwayat notifikasi. | `Super + N` / Klik Jam Bar |
| 7 | **Power Menu (Session)** | **Rofi Power Applet** | Modal terpusat dengan ikon Nerd Font: Lock (`nf-fa-lock`), Suspend (`nf-fa-moon`), Logout (`nf-fa-sign_out`), Reboot (`nf-fa-rotate_right`), Shutdown (`nf-fa-power_off`). | `Super + Backspace` / `Super + Esc` |
| 8 | **Clipboard Manager** | **`cliphist` + Rofi (`clipboard.sh`)** | Popup daftar riwayat teks dan gambar yang baru disalin, dilengkapi pencarian fuzzy. | `Super + V` |
| 9 | **Volume & Brightness OSD** | **`swayosd` / `avizo`** | Popup pill floating minimalis di tengah/bawah layar saat menekan tombol fungsi Volume Up/Down atau Brightness. | Tombol Fn Keyboard |
| 10 | **Screenshot & Annotate** | **`grim` + `slurp` + `swappy`** | Menangkap area layar tertentu dan membuka editor anotasi bergaris emas untuk langsung disalin ke clipboard atau disimpan. | `PrintScreen` / `Super + Shift + S` |
| 11 | **Lockscreen** | **`swaylock-effects`** | Layar kunci dengan efek blur artistik pada lukisan Raphael, jam Romawi di tengah, ring autentikasi emas, dan input passphrase. | `Super + L` / `swayidle` timeout |
| 12 | **Idle Daemon** | **`swayidle`** | Mengatur redup layar setelah 5 menit, mengunci setelah 10 menit, dan mematikan display saat tidur. | Otomatis di background |
| 13 | **Polkit Auth Agent** | **`polkit-gnome`** | Dialog GUI autentikasi hak akses root/sudo yang konsisten dengan tema Everforest. | Otomatis saat sudo GUI |
| 14 | **Settings Customizer** | **Python GTK4 / `settings-gtk`** | Panel GUI kustom untuk mengatur wallpaper default, pergantian tema gelap/terang, layout bar, dan preferensi aplikasi. | `Super + I` / Menu Settings |
| 15 | **Boot Splash (Syarat SO)** | **Plymouth Theme** | Splash screen animasi pilar klasik & teks "Renaissance OS" saat booting di VirtualBox. | Saat Boot & Shutdown |

---

## 4. Rincian Desain Antarmuka (UI/UX Breakdown)

### A. Top Bar (Waybar)
* **Kiri**: Logo pilar klasik (`nf-md-pillar` atau SVG) + Workspaces Romawi (`I`, `II`, `III`, `IV`, `V`) dengan highlight gold `#db9c5e` pada workspace aktif + Window Title.
* **Tengah**: Spacer / Tanggal klasik.
* **Kanan**: Audio icon (`nf-fa-volume_high`), Metrik CPU/RAM (`nf-fa-microchip`, `nf-fa-memory`), Status Baterai, Jam, Tombol Control Center (`nf-fa-sliders`).

### B. Wallpaper Selector (Rofi Thumbnail Grid)
* Modal terpusat berukuran proporsional (60% lebar layar).
* Header: `Search / Choose Renaissance Wallpaper` (didahului icon `nf-fa-image`).
* Grid 2x4 kartu lukisan klasik Renaissance (*The Creation of Adam*, *Mona Lisa*, *Vitruvian Man*, *The Birth of Venus*, *Ancient Greek Library*, *The Last Supper*, *Classical Ruins*, *The School of Athens*).
* Setiap item memiliki thumbnail preview proporsional, border emas ketika dipilih (*focused*), dan label nama karya berukuran 12px di bawahnya.
* Memilih item akan mengeksekusi penggantian wallpaper live via `swaybg` dan memperbarui konfigurasi permanen.

### C. Control Center & Notification Center (SwayNC)
* Terbuka meluncur dari sisi kanan layar.
* **Quick Toggles Grid**: Wi-Fi (`nf-fa-wifi`), Bluetooth (`nf-fa-bluetooth`), Night Light (`nf-fa-moon`), Power (`nf-fa-power_off`).
* **Sliders**: Volume slider dan Brightness slider horizontal bernuansa emas (tinggi 8px, handle emas).
* **Media Player Widget**: Album art, tombol play/pause/prev/next dengan ikon Nerd Font.
* **Notification Stack**: Kartu notifikasi berlatar `#2d353b`, border tipis emas, font monospace 12px.

### D. Side Dock (Floating Toolbelt)
* Bar vertikal di sisi kiri layar dengan ikon Nerd Font monokrom:
  * Terminal: `nf-fa-terminal`
  * Files: `nf-fa-folder`
  * Notes: `nf-fa-book`
  * Editor: `nf-fa-code`
  * Settings: `nf-fa-gear`

### E. Power Menu Modal (Rofi)
* Header: `RENAISSANCE OS : SESSION CONTROLS` (tanpa em-dash).
* Tombol kartu horizontal dengan ikon Nerd Font monokrom emas:
  * `LOCK`: `nf-fa-lock`
  * `SUSPEND`: `nf-fa-moon`
  * `LOGOUT`: `nf-fa-right_from_bracket`
  * `REBOOT`: `nf-fa-rotate_right`
  * `SHUTDOWN`: `nf-fa-power_off`

---

## 5. Jadwal Eksekusi 3 Hari (Timeline Roadmap)

```
[HARI 1] Konfigurasi Ricing di Arch Host & Preview (Assets Creation)
 ├── Finalisasi tema warna (Everforest + Renaissance Gold)
 ├── Buat struktur dotfiles di assets/dotfiles/
 ├── Rancang konfigurasi Sway (config, keybinds, border gold, font proporsional)
 ├── Rancang konfigurasi Waybar (Top Bar Romawi + Side Dock vertikal)
 ├── Rancang Rofi Wallpaper Selector (grid thumbnail), Power Menu, & App Launcher
 ├── Rancang SwayNC (Control Center & Notifications)
 ├── Setup Fastfetch ASCII pilar klasik & Kitty theme
 └── Preview langsung di Arch host menggunakan nested Sway (sway -c ...)

[HARI 2] Otomasi Script & Uji Coba di Mesin Virtual Ubuntu
 ├── Susun folder struktur assets/dotfiles/
 ├── Buat setup.sh (instalasi paket apt, link ke /etc/skel, autologin user live)
 ├── Desain splash screen Plymouth (pilar klasik & logo)
 ├── Uji coba setup.sh di VM Ubuntu bersih (VirtualBox)
 └── Validasi kestabilan grafis (tanpa black screen)

[HARI 3] Remastering ISO di Cubic, Dokumentasi, & Video Demo
 ├── Eksekusi perintah di chroot Cubic (mengikuti script yang sudah teruji di Hari 2)
 ├── Hapus paket bawaan Ubuntu yang tidak diperlukan (bloatware)
 ├── Generate file ISO bootable baru (Renaissance-OS-26.04-amd64.iso)
 ├── Uji boot ISO baru di VirtualBox (Live CD mode)
 ├── Rekam video demonstrasi (Booting -> Splash -> Desktop -> Fastfetch -> Workflow)
 └── Susun laporan praktikum (screenshot tahapan Cubic & penjelasan konsep)
```

---

## 6. Strategi Perintah Cubic & `/etc/skel`
Perintah di dalam Cubic dibagi menjadi 4 tahap terisolasi untuk laporan:
1. **Tahap 1: Repository & Paket**:
   ```bash
   apt update && apt install -y sway swaybg waybar rofi-wayland sway-notification-center \
       kitty zsh fastfetch fonts-ebgaramond fonts-jetbrains-mono fonts-font-awesome \
       plymouth-themes cliphist grim slurp swappy
   ```
2. **Tahap 2: Deployment Konfigurasi**: Menyalin dotfiles ke `/etc/skel/.config/` dan wallpaper ke `/usr/share/backgrounds/`.
3. **Tahap 3: Plymouth & GRUB**: Set tema boot splash kustom.
4. **Tahap 4: Pembersihan**: `apt autoremove -y && apt clean`.
