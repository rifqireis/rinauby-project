# 🏛️ Panduan Desain Rofi Launcher: School of Athens
**Tema Sistem:** *Digital Humanism & The Renaissance of Open Source*  
**Status:** Resmi Diterapkan (*Official Production Reference*)  
**File Konfigurasi:** [`assets/dotfiles/rofi/renaissance_launcher.rasi`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/dotfiles/rofi/renaissance_launcher.rasi)  
**Tangkapan Layar Live:** [`ui/rofi_live_desktop.png`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/ui/rofi_live_desktop.png)  
**Detail Close-Up:** [`ui/rofi_modal_closeup.png`](file:///home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/ui/rofi_modal_closeup.png)

---

## 1. Filosofi & Karakteristik Desain

Rofi Application Launcher pada School of Athens dirancang sebagai **modal terpusat (Center Modal Dialog)** yang memancarkan estetika klasik naskah kuno berpadu dengan fungsionalitas modern:

1. **Center Modal Klasik**:
   - Terletak tepat di tengah layar (`location: center; anchor: center`), menghadirkan fokus penuh bagi pengguna saat mencari aplikasi.
   - Menggunakan lebar proporsional `530px` dengan sudut membulat elegan `border-radius: 12px`.
2. **Bingkai Emas Antik (*Renaissance Gold Hairline*)**:
   - Memiliki garis tepi tipis `1.5px solid #db9c5e` yang senada dengan garis bawah Waybar.
   - Latar belakang menggunakan panel akrilik gelap ber-blur (`rgba(28, 33, 37, 0.88)`).
3. **Pencarian Humanis (*Knowledge Search Bar*)**:
   - Kotak pencarian dibingkai garis emas halus (`border-radius: 8px`).
   - Placeholder teks filosofis: `"Search knowledge, tools, apps..."` (`#859289`).
4. **Hierarki Teks Dua Baris (*Two-Line Semantic Format*)**:
   - Setiap elemen aplikasi menampilkan **Nama Aplikasi** di baris atas (`#d3c6aa` Marble Cream) dan **Kategori / Fungsi Generik** di baris bawah (`#859289` Muted Stone Grey, contoh: *terminal, text editor, web browser, process viewer*).
   - Format drun: `{name}\n<span size='9500' color='#859289'>{generic}</span>`.
5. **Item Terpilih Lembut (*Subtle Slate Capsule*)**:
   - Elemen yang sedang dipilih ditandai dengan latar arang hangat lembut `rgba(45, 53, 59, 0.82)` dengan `border-radius: 6px`, tanpa warna mencolok yang menyilaukan mata.

---

## 2. Parameter Geometri & Warna Utama

| Elemen | Nilai / Kode Warna | Keterangan |
| :--- | :--- | :--- |
| **Lebar Modal** | `530px` | Ramping dan fokus di tengah layar |
| **Latar Modal** | `rgba(28, 33, 37, 0.88)` | Dark Slate Acrylic dengan efek blur compositor |
| **Border Luar** | `1.5px solid #db9c5e` | Hairline emas ochre Renaissance |
| **Radius Modal** | `12px` | Kurva sudut modern-klasik |
| **Kotak Input** | `rgba(20, 24, 27, 0.60)` | Inset gelap dengan border `rgba(219, 156, 94, 0.60)` |
| **Ukuran Ikon** | `38px` | Ikon proporsional dan jelas terbaca |
| **Tipografi** | `JetBrainsMono Nerd Font 12` | Monospace tajam berpadu Pango markup |

---

## 3. Integrasi Keybinding Hyprland

Launcher dipanggil menggunakan shortcut keyboard utama:
```ini
# Buka Rofi Launcher
bind = $mainMod, SPACE, exec, rofi -show drun -theme /etc/skel/.config/rofi/renaissance_launcher.rasi
bind = $mainMod, D, exec, rofi -show drun -theme /etc/skel/.config/rofi/renaissance_launcher.rasi
```
