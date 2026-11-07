-- File ini dihasilkan otomatis oleh Pengaturan Desktop (Window Management)
-- JANGAN mengedit berkas ini secara manual karena akan tertimpa saat disimpan di GUI.

-- Add/Remove Software
hl.window_rule({ match = { class = "^(pamac-manager|org.manjaro.pamac.manager)$" }, float = true, center = true, size = { "(monitor_w*0.55)", "(monitor_h*0.70)" }, opacity = "1.00 1.00", rounding = 20 })

-- Files
hl.window_rule({ match = { class = "^(org.gnome.Nautilus|nautilus)$" }, float = true, center = true, size = { "(monitor_w*0.55)", "(monitor_h*0.65)" }, no_blur = false, rounding = 20 })

-- Text Editor
hl.window_rule({ match = { class = "^(org.gnome.TextEditor|gnome-text-editor)$" }, float = true, center = true, size = { "(monitor_w*0.60)", "(monitor_h*0.60)" }, rounding = 20 })

-- GTK Settings
hl.window_rule({ match = { class = "^(nwg-look)$" }, float = true, center = true, size = { "(monitor_w*0.55)", "(monitor_h*0.70)" }, rounding = 20 })

-- Dolphin
hl.window_rule({ match = { class = "^(dolphin|org.kde.dolphin)$" }, float = true, center = true, size = { "(monitor_w*0.55)", "(monitor_h*0.65)" }, no_blur = false })

-- Kvantum Manager
hl.window_rule({ match = { class = "^(kvantummanager)$" }, tile = true, no_blur = false })

-- kitty
hl.window_rule({ match = { class = "^(kitty)$" }, tile = true, no_blur = false })

-- PulseAudio Volume Control
hl.window_rule({ match = { class = "^(pavucontrol-qt)$" }, float = true, center = true, size = { "(monitor_w*0.45)", "(monitor_h*0.45)" } })
