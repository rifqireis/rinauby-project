# 🏛️ Panduan Desain & Spesifikasi Screenshot Tool: School of Athens
**Tema Sistem:** *Digital Humanism & The Renaissance of Open Source*  
**Status:** Resmi Diterapkan (*Official Production Reference*)  
**File Skrip:** [`assets/dotfiles/scripts/screenshot.sh`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/dotfiles/scripts/screenshot.sh)  
**File Tema Rofi:** [`assets/dotfiles/rofi/screenshot_menu.rasi`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/dotfiles/rofi/screenshot_menu.rasi)  
**File Toggler Mode:** [`assets/toggle_renaissance.sh`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/toggle_renaissance.sh)  

---

## 1. Filosofi & Visi Desain

Screenshot tool pada School of Athens dirancang selaras dengan prinsip **Digital Humanism**:
1. **Presisi Geometris Klasik**:
   - Area penyeleksian (*slurp selection box*) menggunakan garis batas tegas emas Renaissance (`#db9c5e`, ketebalan `2px`) dengan latar belakang akrilik transparan berona arang hangat (`rgba(28, 33, 37, 0.53)`).
2. **Distraction-Free Workflow**:
   - Tangkapan layar otomatis disimpan ke `~/Pictures/Screenshots/Screenshot_YYYY-MM-DD_HH.MM.SS.png` dan langsung disalin ke papan klip (*clipboard*) dalam format `image/png`.
   - Pengguna tidak dipaksa membuka dialog popup yang mengganggu alur berpikir, namun notifikasi halus (*SwayNC*) memberitahukan konfirmasi keberhasilan disertai pratinjau gambar.
3. **Modal Dialog Terpusat (Rofi Menu)**:
   - Apabila pengguna memerlukan variasi mode (layar penuh, jendela aktif, anotasi Swappy, atau timer tunda), tersedia menu terpusat yang serasi dengan tema *Renaissance Launcher*.

---

## 2. Fitur & Parameter Operasi

| Perintah (`screenshot.sh <mode>`) | Deskripsi | Integrasi Alat |
| :--- | :--- | :--- |
| `snip` / `region` | Seleksi area interaktif | `slurp` + `grim` + `wl-copy` |
| `full` / `fullscreen` | Tangkapan layar penuh | `grim` + `wl-copy` |
| `window` | Tangkapan jendela yang sedang aktif | `hyprctl activewindow` + `jq` + `grim` |
| `edit` / `swappy` | Potong area lalu buka editor anotasi | `slurp` + `grim` + `swappy` |
| `delay <detik>` | Tangkapan tunda layar penuh dengan countdown | `sleep` + `grim` + `wl-copy` |
| `menu` | Dialog modal Rofi pilihan lengkap | `rofi -dmenu` bertema emas Renaissance |

---

## 3. Integrasi Pintasan Papan Ketik (Keybindings)

| Shortcut | Fungsi | Deskripsi |
| :--- | :--- | :--- |
| `Super + Shift + Space` | Potong Area (*Snip*) | Seleksi bebas area layar |
| `Super + Shift + S` | Potong Area (*Snip*) | Shortcut alternatif universal |
| `Print` / `Ctrl + Print` | Layar Penuh | Mengambil seluruh tampilan monitor aktif |
| `Super + Print` | Menu Screenshot | Membuka popup menu Rofi terpusat |
| `Super + Shift + E` | Anotasi Swappy | Memotong area dan langsung menggambar / anotasi |

---

## 4. Dependensi Paket & Remastering Cubic (Ubuntu 26.04)

Saat melakukan proses remastering ISO Ubuntu menggunakan Cubic:
1. Pastikan paket dependensi berikut terpasang di chroot:
   ```bash
   apt-get install -y grim slurp swappy wl-clipboard jq sway-notification-center
   ```
2. Salin skrip dan tema ke template pengguna default:
   ```bash
   mkdir -p /etc/skel/.config/hypr/scripts/
   mkdir -p /etc/skel/.config/rofi/
   cp assets/dotfiles/scripts/screenshot.sh /etc/skel/.config/hypr/scripts/
   cp assets/dotfiles/rofi/screenshot_menu.rasi /etc/skel/.config/rofi/
   chmod +x /etc/skel/.config/hypr/scripts/screenshot.sh
   ```
