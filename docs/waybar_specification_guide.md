# Panduan Desain & Spesifikasi Resmi Waybar: Rinauby
**Tema Sistem:** *Digital Humanism & The Renaissance of Open Source*  
**Status:** Disetujui & Teruji Live (*Official Production Reference*)  
**File Konfigurasi Utama:**
- Config: [`assets/dotfiles/waybar/config.jsonc`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/dotfiles/waybar/config.jsonc)
- Style: [`assets/dotfiles/waybar/style.css`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/dotfiles/waybar/style.css)
- Tangkapan Layar Resmi: [`ui/waybar_topdocked_live.png`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/ui/waybar_topdocked_live.png)

---

## 1. Filosofi & Visi Estetika

Waybar pada Rinauby bukan sekadar penunjuk status perangkat keras, melainkan representasi arsitektur klasik zaman Renaissance yang diterjemahkan ke dalam antarmuka modern.

1. **Digital Humanism & Kedaulatan Pengguna**:
   - Ruang komputasi berfokus pada pekerjaan manusia, bukan angka mesin.
   - Tidak ada metrik persentase CPU dan RAM yang berkedip dan memicu rasa cemas (*distraction-free / zero cognitive clutter*).
2. **Arsitektur Entablature Klasik**:
   - Bilah menempel rapat ke batas atas layar (`margin-top: 0`), menyerupai *frieze/entablature* kuil atau kubah arsitektur Raphael (*School of Athens*).
   - Garis bawah emas tipis (`border-bottom: 2px solid #db9c5e`) menjadi pembatas tegas dan berkelas antara bilah status dan kanvas ruang kerja.
3. **Zero Module Backgrounds**:
   - Modul di sisi kanan tidak dibungkus kotak-kotak pil atau badge berwarna-warni yang ramai. Teks dan ikon mengambang alami di atas panel akrilik gelap, menciptakan kesan bersih dan tenang.
4. **Latar Belakang Akrilik Solid Ber-Blur**:
   - Memanfaatkan latar `rgba(28, 33, 37, 0.82)` yang dipadukan dengan efek blur Hyprland (*layer-shell blur*), memberikan kesan kaca marmer gelap tembus pandang yang tetap kokoh dan terbaca jelas.

---

## 2. Spesifikasi Geometri & Parameter Bilah

| Parameter | Nilai | Penjelasan |
| :--- | :--- | :--- |
| **Layer** | `top` | Berada di atas jendela aplikasi biasa |
| **Position** | `top` | Menempel di sisi atas layar |
| **Height** | `34px` | Ramping, proporsional, dan memaksimalkan area kerja |
| **Margin Top** | `0px` | Menempel rapat ke batas tepi atas monitor |
| **Margin Left / Right** | `8px` | Memberikan nafas halus di sisi kiri dan kanan |
| **Border Radius** | `0 0 6px 6px` | Sudut atas siku (karena menempel ke atas), sudut bawah membulat halus 6px |
| **Border Bottom** | `2px solid #db9c5e` | Garis aksen emas ochre yang membentang penuh |
| **Borders Samping/Atas** | `border-top: none; border-left/right: 1px solid rgba(184, 134, 78, 0.22);` | Hairline tipis pelengkap |
| **Opacity & Background**| `rgba(28, 33, 37, 0.82)` | Solid charcoal bertekstur hangat |

---

## 3. Komposisi & Penataan Modul

Bilah dibagi menjadi 3 zona fungsional yang simetris dan berimbang:

```
+----------------------------------------------------------------------------------------------------+
| []  I  II [III] IV  V │ Active Window Title       Digital Humanism        󰕾 28%  󰂄 80% │ Tue 17:32 |
+----------------------------------------------------------------------------------------------------+
|========================================== Garis Emas ==============================================|
```

### A. Sisi Kiri (Navigasi & Konteks Kerja)
1. **Logo Renaissance (`custom/logo`)**:
   - Ikon Pantheon/Kuil Klasik Renaissance `` (`U+F19C`) dalam balutan warna Ochre (`#db9c5e`).
   - Berfungsi sebagai titik awal visual dan peluncur aplikasi (*application launcher*) di sudut kiri atas.
2. **Workspace Romawi (`hyprland/workspaces`)**:
   - Menggunakan angka Romawi klasik: `I`, `II`, `III`, `IV`, `V` (hingga `X`).
   - **Tipografi**: Font Serif klasik `Cinzel` / `EB Garamond` dengan ukuran 13.5px dan letter-spacing `0.8px`.
   - **Status Aktif**: Teks emas terang `#e5c07b` dengan latar lembut `rgba(229, 192, 123, 0.15)` dan `border-radius: 4px`.
   - **Status Inaktif**: Abu-abu marmer antik `#859289` tanpa latar belakang.
3. **Pemisah Vertikal (`custom/separator-left`)**:
   - Karakter garis halus `│` berwarna emas redup transparan `rgba(184, 134, 78, 0.30)`.
4. **Judul Jendela Aktif (`custom/window-title`)**:
   - Menampilkan judul aplikasi yang sedang dibuka dengan warna hijau zaitun *sage green* (`#a7c080`).
   - Saat desktop kosong (tanpa jendela), otomatis menampilkan judul karya seni wallpaper aktif.

### B. Sisi Tengah (Pusat Filosofis)
- **Semboyan Humanisme (`custom/quote`)**:
   - Menampilkan semboyan klasik filosofi Renaissance (*Ad Fontes, Cerca il Vero, Sapere Aude*, dll) secara berkala dan berganti setiap kali wallpaper berubah.
   - Warna marmer krem antique paper (`#d3c6aa`), bobot sedang (semi-bold 600).
   - Klik untuk memutar semboyan ke kutipan berikutnya.

### C. Sisi Kanan (Status Esensial Manusia)
1. **Audio / Volume (`pulseaudio`)**:
   - Format: `{icon}  {volume}%` (misal `󰕾  28%`).
   - Klik untuk mute/unmute audio seketika.
2. **Baterai / Daya (`battery`)**:
   - Format: `{icon}  {capacity}%` (misal `󰂄  80%`).
   - Indikator dinamis saat charging atau dalam mode baterai.
3. **Pemisah Vertikal (`custom/separator-right`)**:
   - Karakter garis halus `│` sebagai jeda sebelum penunjuk waktu.
4. **Waktu & Kalender Interaktif (`clock`)**:
   - Format: `{0:%a, %d %b  %H:%M}` (misal `Tue, 03 Nov  17:32`).
   - Warna teks emas Renaissance (`#e5c07b`).
   - Klik membuka pusat notifikasi / kalender interaktif.

---

## 4. Palet Warna Resmi (Everforest Warm Renaissance)

| Peran | Hex Code / RGBA | Representasi Material |
| :--- | :--- | :--- |
| **Bar Background** | `rgba(28, 33, 37, 0.82)` | Warm Slate / Arang Marmer Gelap |
| **Aksen Garis Bawah** | `#db9c5e` | Renaissance Ochre / Emas Antik |
| **Aksen Emas Terang** | `#e5c07b` | Renaissance Gold (Workspace Aktif & Jam) |
| **Teks Utama** | `#d3c6aa` | Marble Cream / Antique Parchment Paper |
| **Teks Sekunder/Inaktif** | `#859289` | Weathered Stone Grey |
| **Judul Jendela** | `#a7c080` | Renaissance Olive / Sage Green |
| **Peringatan / Alert** | `#e67e80` | Terracotta Red |

---

## 5. Tipografi Resmi

- **UI & Workspace Romawi**: `Cinzel`, `EB Garamond`, didukung oleh `Inter` (sans-serif modern yang sangat legibel).
- **Window Title, Monospace, & Tooltip**: `JetBrainsMono Nerd Font`, `Iosevka Nerd Font`.

---

## 6. Integrasi Compositor Hyprland

Agar efek *frosted glass* berfungsi sempurna, Hyprland diatur untuk menerapkan blur pada *layer namespace* `waybar`:

### Aturan Layer Rule (Hyprland):
```ini
# Aturan blur transparan untuk Waybar
layerrule = blur, waybar
layerrule = ignorealpha 0.2, waybar
```

*Catatan: Pada konfigurasi dinamis berbasis Lua, hal ini dijalankan via:*
```lua
hl.layer_rule({ match = { namespace = "waybar" }, blur = true, ignore_alpha = 0.2 })
```

---

## 7. Panduan Implementasi Remastering ISO Ubuntu (Cubic)

Saat melakukan proses remastering ISO Ubuntu 26.04 menggunakan Cubic:
1. Pastikan paket dependensi terpasang di chroot:
   ```bash
   apt-get install -y waybar hyprland fonts-inter fonts-jetbrains-mono swaybg pulseaudio-utils
   ```
2. Salin seluruh isi folder `assets/dotfiles/waybar/` ke direktori template pengguna default:
   ```bash
   mkdir -p /etc/skel/.config/waybar/
   cp assets/dotfiles/waybar/config.jsonc /etc/skel/.config/waybar/
   cp assets/dotfiles/waybar/style.css /etc/skel/.config/waybar/
   ```
3. Pastikan font klasik (`Cinzel` dan `EB Garamond`) terpasang di `/usr/local/share/fonts/` agar angka Romawi ter-render dengan sempurna pada setiap instalasi baru.
