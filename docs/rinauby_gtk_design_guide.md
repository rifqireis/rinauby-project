# Panduan Desain Antarmuka Rinauby (GTK4 & Libadwaita HIG)

Dokumen ini merupakan panduan resmi gaya desain (*Human Interface Guidelines* / HIG), arsitektur tata letak, proporsi metrik, kedalaman visual, serta tipografi untuk aplikasi **Pengaturan Rinauby (`rinauby-settings`)** dan seluruh komponen antarmuka ekosistem desktop **Rinauby**.

---

## 1. Tiga Pilar Aturan Desain Rinauby

Untuk menciptakan antarmuka yang matang, elegan, dan berkarakter khas karya pengrajin (*artisan craftsmanship*)—bukan hasil *prompt* instan AI generatif—seluruh pengembangan antarmuka Rinauby wajib mematuhi 3 aturan mutlak berikut:

### Aturan 1: Simetri, Proporsi Padat, & Bebas Ruang Hampa
- **Anti-Bloat Layout**: Tidak boleh membuat kontainer atau kartu yang meregang terlalu lebar di layar lebar sehingga teks dan saklar terpisah jauh dan menyisakan kekosongan (*dead whitespace*).
- **Pembatas Konten (`Adw.Clamp`)**: Area konten selalu dibatasi pada lebar maksimal **`640px`** (dengan *tightening threshold* **`520px`**).
- **Simetri Margin & Padding**:
  - Margin luar halaman konten terstandar: `margin-top: 14px`, `margin-bottom: 18px`, `margin-left: 16px`, `margin-right: 16px` dengan `spacing: 12px`.
  - Padding dalam baris kartu (`Adw.ActionRow` / `Adw.SwitchRow`) terstandar: `padding: 6px 14px`, `min-height: 44px`.
  - Kartu kontainer (`preferencesgroup list`) memiliki `padding: 0` agar baris terpasang presisi memenuhi radius sudut.

### Aturan 2: Larangan Penggunaan Emoji (Strictly No Emojis)
- **Dilarang Keras Menggunakan Karakter Emoji**: Karakter emoji (seperti 🏛, 📋, 🖼, ⚙️, 🚀, dll.) merusak kewibawaan tipografi klasik, tampak kekanak-kanakan, dan tidak konsisten antar font rendering.
- **Gunakan Ikon Simbolik Native**:
  - Gunakan ikon simbolik standar Freedesktop / GNOME (`applications-system-symbolic`, `network-wireless-symbolic`, `bluetooth-symbolic`, `preferences-desktop-display-symbolic`, dll.).
  - Ikon berukuran `16px` dengan warna mengikuti hierarki teks atau aksen emas.
- **Tipografi Bersih Berbasis Teks**: Jika memerlukan pembeda status atau versi, gunakan teks kapital yang terstruktur rapi (misalnya: `v1.0 Masterpiece`, `Noble 26.04 LTS`, `Ad Fontes`) dengan *letter-spacing* yang proporsional.

### Aturan 3: Kedalaman Tonal & Shadow Alami (Anti-Wireframe / Anti-AI Outline)
- **Eliminasi Outline Kasar**: Dilarang menggunakan border/garis tepi berwarna kontras yang tebal (misal: `1px` atau `1.5px solid #db9c5e` di sekeliling jendela atau setiap kartu). Border tebal berwarna emas/kuning di setiap sudut memberikan kesan purwarupa (*wireframe*) atau desain buatan AI yang belum matang (*nanggung*).
- **Fokus pada Tonal Depth & Ambient Shadows**:
  - Gunakan kontras latar bertingkat (*tonal layering*): latar jendela `#171a1d`, sidebar `#131518`, dan permukaan kartu `#202429`.
  - Gunakan bayangan jatuh lembut (*soft ambient drop shadows*): `box-shadow: 0 16px 40px rgba(0,0,0,0.55)` untuk jendela utama dan `box-shadow: 0 2px 8px rgba(0,0,0,0.25)` untuk kartu.
  - Gunakan batas *hairline* ultra-halus bersahaja jika diperlukan batas fisik: `1px solid rgba(255, 255, 255, 0.04)` hingga `rgba(255, 255, 255, 0.06)`, bukan garis berwarna terang.
  - Indikator baris aktif pada sidebar menggunakan *accent background tint* (`rgba(219,156,94,0.14)`) dan garis vertikal tipis di tepi kiri (`box-shadow: inset 2px 0 0 @gold_primary`), bukan bingkai kotak penuh.

---

## 2. Palet Warna Resmi (Digital Humanism)

| Token Warna | Nilai Hex / RGBA | Peran & Penggunaan |
| :--- | :--- | :--- |
| `@gold_primary` | `#db9c5e` | Aksen emas Renaisans untuk saklar aktif, slider, dan indikator fokus primer |
| `@gold_bright` | `#e5c07b` | Judul headerbar, judul grup pengaturan, teks tombol sorot, aksen teks aktif |
| `@bg_charcoal` | `#171a1d` | Kanvas jendela utama (*Dark Slate Charcoal*) |
| `@bg_sidebar` | `#131518` | Latar navigasi sidebar (kontras lebih gelap dari kanvas) |
| `@bg_card` | `#202429` | Latar kontainer kartu baris pengaturan (`Adw.PreferencesGroup list`) |
| `@bg_card_hover` | `#262a30` | Efek hover lembut saat kursor berada di atas baris |
| `@fg_cream` | `#fbf2db` | Teks judul baris, nilai input, teks utama (*Antique Paper*) |
| `@fg_muted` | `#959c9e` | Subjudul baris, label bantuan teknis, sinyal Wi-Fi, keterangan sekunder |
| `@border_hairline` | `rgba(255, 255, 255, 0.04)` | Garis pemisah baris dan bingkai halus pembatas elevasi |

---

## 3. Matriks Dimensi, Padding, & Margin (HIG Standards)

### A. Geometri Jendela & Kontainer Utama
- **Dimensi Standar Jendela**: `880px × 600px` (Mendukung resolusi layar laptop 1080p, monitor 2K/4K, maupun jendela VirtualBox).
- **Radius Sudut Jendela**: `14px`.
- **Batas Tepi Jendela**: Hairline `1px solid rgba(255, 255, 255, 0.06)` dipadu dengan bayangan ganda `box-shadow: 0 16px 40px rgba(0, 0, 0, 0.55), 0 2px 6px rgba(0, 0, 0, 0.35)`.
- **Sidebar Navigasi**: Lebar minimum `240px`, maksimum `270px`, fraksi `0.28`.
- **Pembatas Konten (`Adw.Clamp`)**:
  - `maximum_size`: **`640px`** (menjaga kartu tetap proporsional dan tidak meregang kosong).
  - `tightening_threshold`: **`520px`**.

### B. Grup Pengaturan (`Adw.PreferencesGroup`)
- **Margin Luar Halaman**: `margin-top: 14px`, `margin-bottom: 18px`, `margin-left: 16px`, `margin-right: 16px`.
- **Jarak Antar Grup**: `margin-top: 4px`, `margin-bottom: 14px`.
- **Judul Grup (`header label`)**:
  - Font: `Inter Bold`, ukuran `9.5pt`, `font-weight: 600`, warna `@gold_bright` (`#e5c07b`).
  - Margin: `margin-left: 4px`, `margin-bottom: 6px`.
- **Kontainer Kartu (`preferencesgroup list`)**:
  - Latar: `@bg_card` (`#202429`).
  - Border: `1px solid rgba(255, 255, 255, 0.04)`.
  - Radius: `10px`.
  - Padding: `0`.
  - Bayangan: `box-shadow: 0 2px 8px rgba(0, 0, 0, 0.25), 0 1px 2px rgba(0, 0, 0, 0.15)`.

### C. Baris Pengaturan (`Adw.ActionRow` / `Adw.SwitchRow`)
- **Tinggi Baris Minimal**: `min-height: 44px`.
- **Padding Dalam Baris**: `padding: 6px 14px`.
- **Pemisah Antar Baris**: `border-bottom: 1px solid rgba(255, 255, 255, 0.035)` (Baris terakhir otomatis `border-bottom: none`).
- **Judul Baris (`row label.title`)**: `font-size: 10pt`, `font-weight: 500`, warna `@fg_cream`.
- **Subjudul Baris (`row label.subtitle`)**: `font-size: 8.5pt`, warna `@fg_muted`, `margin-top: 1px`.
- **Ikon Prefix**: Ikon simbolik native ukuran `16px`, `margin-right: 10px`.

### D. Kontrol Interaktif, Saklar, & Tombol
- **Saklar (`Gtk.Switch`)**:
  - Dimensi: `min-width: 38px`, `min-height: 20px`, `border-radius: 11px`.
  - Slider: `min-width: 14px`, `min-height: 14px`, `margin: 3px`, latar putih `#ffffff`, radius `9px`.
  - Keadaan Aktif: Latar `@gold_primary` (`#db9c5e`), bayangan lembut `0 2px 6px rgba(219, 156, 94, 0.25)`, **tanpa outline kasar**.
  - Keadaan Nonaktif: Latar `rgba(255, 255, 255, 0.08)`, bayangan inset `inset 0 1px 2px rgba(0, 0, 0, 0.35)`, **border: none**.
- **Tombol Aksi Baris (`button.flat`)**:
  - Dimensi & Padding: `padding: 4px 11px`, `min-height: 26px`, `border-radius: 6px`.
  - Tipografi: `Inter`, `8.5pt`, `font-weight: 500`.
  - Latar: `rgba(219, 156, 94, 0.12)`, warna teks `@gold_bright`, bayangan `0 1px 2px rgba(0, 0, 0, 0.15)`.
  - Hover: `background-color: rgba(219, 156, 94, 0.24)`, bayangan `0 2px 5px rgba(0, 0, 0, 0.25)`.
- **Sidebar Navigasi Baris (`navigation-sidebar row`)**:
  - Dimensi: `min-height: 32px`, `padding: 4px 8px`, `margin: 1px 8px`, `border-radius: 7px`.
  - Baris Terpilih: Latar `rgba(219, 156, 94, 0.14)`, teks `@gold_bright`, `box-shadow: inset 2px 0 0 @gold_primary` (indikator aksial bersih).

---

## 4. Struktur Navigasi Halaman

```text
RINAUBY
├── 1. Connectivity
│   ├── Wi-Fi (nmcli / Signal, Connected, Available, Airplane Mode)
│   └── Bluetooth (bluetoothctl / Pair, Disconnect, Visibility)
├── 2. Appearance & Personalization
│   ├── Appearance (Color Scheme, Roman Numerals, Border Glow)
│   ├── Wallpapers (Classical Art Gallery)
│   └── GTK Theme & Icons (GTK Theme, Icon Theme, Cursor)
├── 3. Window Manager (Hyprland Core - Ubuntu PPA)
│   ├── General Settings (Tiling Layout, Gaps, Borders, Blur, Shadow, Input)
│   ├── Window Rules (windowrulev2 Floating, Size, Opacity)
│   ├── Default Apps (Terminal, Browser, Files, Text Editor)
│   ├── Startup Applications (Autostart Services)
│   └── Session Variables (Wayland, VA-API, Cursor)
└── 4. Panel & System
    ├── Waybar Panel (Position, Height, Rotator, Telemetry)
    ├── Lock Screen (Hyprlock Blur, Center Clock, Testing)
    ├── Sound (Volume Protection & Feedback Sounds)
    ├── Power & Battery (Alerts & Automatic Suspend)
    ├── Keyboard Shortcuts (Super Keybinds Table)
    └── About Rinauby (Specs, Kernel, Hyprland Version, Ubuntu LTS)
```

---

## 5. Kompatibilitas Hyprland Ubuntu PPA

Setiap perubahan visual (gaps, border, rounding, blur, shadow, window rules) secara instan:
1. Ditulis ke berkas konfigurasi standar `~/.config/hypr/rinauby_overrides.conf` dalam sintaks resmi Hyprland.
2. Di-*source* secara non-destruktif oleh `hyprland.conf` utama:
   ```ini
   source = ~/.config/hypr/rinauby_overrides.conf
   ```
3. Diterapkan seketika tanpa perlu *restart* sesi pengguna lewat perintah:
   ```bash
   hyprctl reload
   ```
