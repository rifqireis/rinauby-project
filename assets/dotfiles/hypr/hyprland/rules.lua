-- ######## Window rules ########

-- Disable blur for xwayland context menus
hl.window_rule({ match = { class = "^()$", title = "^()$" }, no_blur = true })

-- Disable blur for every window
hl.window_rule({ match = { class = ".*" }, no_blur = true })

-- Floating
hl.window_rule({ match = { title = "^(Open File)(.*)$" }, center = true })
hl.window_rule({ match = { title = "^(Open File)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(Select a File)(.*)$" }, center = true })
hl.window_rule({ match = { title = "^(Select a File)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(Choose wallpaper)(.*)$" }, center = true })
hl.window_rule({ match = { title = "^(Choose wallpaper)(.*)$" }, float = true })
hl.window_rule({
	match = { title = "^(Choose wallpaper)(.*)$" },
	size = { "(monitor_w*0.60)", "(monitor_h*0.65)" },
})
hl.window_rule({ match = { title = "^(Open Folder)(.*)$" }, center = true })
hl.window_rule({ match = { title = "^(Open Folder)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(Save As)(.*)$" }, center = true })
hl.window_rule({ match = { title = "^(Save As)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(Library)(.*)$" }, center = true })
hl.window_rule({ match = { title = "^(Library)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(File Upload)(.*)$" }, center = true })
hl.window_rule({ match = { title = "^(File Upload)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(.*)(wants to save)$" }, center = true })
hl.window_rule({ match = { title = "^(.*)(wants to save)$" }, float = true })
hl.window_rule({ match = { title = "^(.*)(wants to open)$" }, center = true })
hl.window_rule({ match = { title = "^(.*)(wants to open)$" }, float = true })
hl.window_rule({ match = { class = "^(blueberry\\.py)$" }, float = true })
hl.window_rule({ match = { class = "^(guifetch)$" }, float = true }) -- FlafyDev/guifetch
hl.window_rule({ match = { class = "^(pavucontrol)$" }, float = true })
hl.window_rule({
	match = { class = "^(pavucontrol)$" },
	size = { "(monitor_w*0.45)", "(monitor_h*0.45)" },
})
hl.window_rule({ match = { class = "^(pavucontrol)$" }, center = true })
hl.window_rule({ match = { class = "^(org.pulseaudio.pavucontrol)$" }, float = true })
hl.window_rule({
	match = { class = "^(org.pulseaudio.pavucontrol)$" },
	size = { "(monitor_w*0.45)", "(monitor_h*0.45)" },
})
hl.window_rule({ match = { class = "^(org.pulseaudio.pavucontrol)$" }, center = true })
hl.window_rule({ match = { class = "^(nm-connection-editor)$" }, float = true })
hl.window_rule({
	match = { class = "^(nm-connection-editor)$" },
	size = { "(monitor_w*0.45)", "(monitor_h*0.45)" },
})
hl.window_rule({ match = { class = "^(nm-connection-editor)$" }, center = true })
hl.window_rule({ match = { class = ".*plasmawindowed.*" }, float = true })
hl.window_rule({ match = { class = "kcm_.*" }, float = true })
hl.window_rule({ match = { class = ".*bluedevilwizard" }, float = true })
hl.window_rule({ match = { title = ".*Welcome" }, float = true })
hl.window_rule({ match = { title = "^(illogical-impulse Settings)$" }, float = true })
hl.window_rule({ match = { title = ".*Shell conflicts.*" }, float = true })

-- Native Desktop Settings (GTK4 / Libadwaita)
hl.window_rule({
	match = { class = "org.rifqi.desktop.settings" },
	float = true,
	center = true,
	size = { "(monitor_w*0.55)", "(monitor_h*0.72)" },
	keep_aspect_ratio = false,
})
hl.window_rule({
	match = { title = ".*Pengaturan Desktop.*" },
	float = true,
	center = true,
	size = { "(monitor_w*0.55)", "(monitor_h*0.72)" },
	keep_aspect_ratio = false,
})
hl.window_rule({ match = { class = "org.freedesktop.impl.portal.desktop.kde" }, float = true })
hl.window_rule({
	match = { class = "org.freedesktop.impl.portal.desktop.kde" },
	size = { "(monitor_w*0.60)", "(monitor_h*0.65)" },
})
hl.window_rule({ match = { class = "^(Zotero)$" }, float = true })
hl.window_rule({
	match = { class = "^(Zotero)$" },
	size = { "(monitor_w*0.45)", "(monitor_h*0.45)" },
})

-- Move
-- kde-material-you-colors spawns a window when changing dark/light theme. This is to make sure it doesn't interfere at all.
hl.window_rule({ match = { class = "^(plasma-changeicons)$" }, float = true })
hl.window_rule({ match = { class = "^(plasma-changeicons)$" }, no_initial_focus = true })
hl.window_rule({ match = { class = "^(plasma-changeicons)$" }, move = { 999999, 999999 } })
-- stupid dolphin copy
hl.window_rule({ match = { title = "^(Copying — Dolphin)$" }, move = { 40, 80 } })

-- Tiling
hl.window_rule({ match = { class = "^dev\\.warp\\.Warp$" }, tile = true })

-- Picture-in-Picture
hl.window_rule({ match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, keep_aspect_ratio = true })
hl.window_rule({
	match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
	move = { "(monitor_w*0.73)", "(monitor_h*0.72)" },
})
hl.window_rule({
	match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
	size = { "(monitor_w*0.25)", "(monitor_h*0.25)" },
})
hl.window_rule({ match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, pin = true })

-- Screen sharing
hl.window_rule({ match = { title = ".*is sharing (a window|your screen).*" }, float = true })
hl.window_rule({ match = { title = ".*is sharing (a window|your screen).*" }, pin = true })
hl.window_rule({
	match = { title = ".*is sharing (a window|your screen).*" },
	move = { "(monitor_w*.5-window_w*.5)", "(monitor_h-window_h-12)" },
})

-- --- Tearing ---
hl.window_rule({ match = { title = ".*\\.exe" }, immediate = true })
hl.window_rule({ match = { title = ".*minecraft.*" }, immediate = true })
hl.window_rule({ match = { class = "^(steam_app).*" }, immediate = true })

-- No shadow for tiled windows
hl.window_rule({ match = { float = 0 }, no_shadow = true })

-- ######## Workspace rules ########
hl.workspace_rule({ workspace = "special:special", gaps_out = 30 })

-- ######## Layer rules ########
hl.layer_rule({ match = { namespace = ".*" }, xray = true })
hl.layer_rule({ match = { namespace = "walker" }, no_anim = true })
hl.layer_rule({ match = { namespace = "selection" }, no_anim = true })
-- hl.layer_rule({ match = { namespace = "overview" }, no_anim = true })
hl.layer_rule({ match = { namespace = "anyrun" }, no_anim = true })
hl.layer_rule({ match = { namespace = "indicator.*" }, no_anim = true })
hl.layer_rule({ match = { namespace = "osk" }, no_anim = true })
hl.layer_rule({ match = { namespace = "hyprpicker" }, no_anim = true })

hl.layer_rule({ match = { namespace = "noanim" }, no_anim = true })
hl.layer_rule({ match = { namespace = "gtk-layer-shell" }, blur = true })
hl.layer_rule({ match = { namespace = "gtk-layer-shell" }, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "launcher" }, blur = true })
hl.layer_rule({ match = { namespace = "launcher" }, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "notifications" }, blur = true })
hl.layer_rule({ match = { namespace = "notifications" }, ignore_alpha = 0.69 })
hl.layer_rule({ match = { namespace = "logout_dialog" }, blur = true }) -- wlogout

-- ags
hl.layer_rule({ match = { namespace = "sideleft.*" }, animation = "slide left" })
hl.layer_rule({ match = { namespace = "sideright.*" }, animation = "slide right" })
hl.layer_rule({ match = { namespace = "session[0-9]*" }, blur = true })
hl.layer_rule({ match = { namespace = "bar[0-9]*" }, blur = true })
hl.layer_rule({ match = { namespace = "bar[0-9]*" }, ignore_alpha = 0.6 })
hl.layer_rule({ match = { namespace = "barcorner.*" }, blur = true })
hl.layer_rule({ match = { namespace = "barcorner.*" }, ignore_alpha = 0.6 })
hl.layer_rule({ match = { namespace = "dock[0-9]*" }, blur = true })
hl.layer_rule({ match = { namespace = "dock[0-9]*" }, ignore_alpha = 0.6 })
hl.layer_rule({ match = { namespace = "indicator.*" }, blur = true })
hl.layer_rule({ match = { namespace = "indicator.*" }, ignore_alpha = 0.6 })
hl.layer_rule({ match = { namespace = "overview[0-9]*" }, blur = true })
hl.layer_rule({ match = { namespace = "overview[0-9]*" }, ignore_alpha = 0.6 })
hl.layer_rule({ match = { namespace = "cheatsheet[0-9]*" }, blur = true })
hl.layer_rule({ match = { namespace = "cheatsheet[0-9]*" }, ignore_alpha = 0.6 })
hl.layer_rule({ match = { namespace = "sideright[0-9]*" }, blur = true })
hl.layer_rule({ match = { namespace = "sideright[0-9]*" }, ignore_alpha = 0.6 })
hl.layer_rule({ match = { namespace = "sideleft[0-9]*" }, blur = true })
hl.layer_rule({ match = { namespace = "sideleft[0-9]*" }, ignore_alpha = 0.6 })
hl.layer_rule({ match = { namespace = "indicator.*" }, blur = true })
hl.layer_rule({ match = { namespace = "indicator.*" }, ignore_alpha = 0.6 })
hl.layer_rule({ match = { namespace = "osk[0-9]*" }, blur = true })
hl.layer_rule({ match = { namespace = "osk[0-9]*" }, ignore_alpha = 0.6 })

-- Quickshell
-- Blur KHUSUS hanya untuk panel utama (bar) dan bezel celestial
hl.layer_rule({ match = { namespace = "^quickshell:bar$" }, blur = true })
hl.layer_rule({ match = { namespace = "^quickshell:bar$" }, ignore_alpha = 0.0 })
hl.layer_rule({ match = { namespace = "^quickshell:celestialBezel$" }, blur = true })
hl.layer_rule({ match = { namespace = "^quickshell:celestialBezel$" }, ignore_alpha = 0.0 })
hl.layer_rule({ match = { namespace = "^quickshell:celestialBezel$" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:onScreenDisplay" }, blur = false })
hl.layer_rule({ match = { namespace = "quickshell:wOnScreenDisplay" }, blur = false })
hl.layer_rule({ match = { namespace = "quickshell:sidebarRight" }, blur = false })
hl.layer_rule({ match = { namespace = "quickshell:sidebarLeft" }, blur = false })
hl.layer_rule({ match = { namespace = "quickshell:notificationPopup" }, blur = false })
hl.layer_rule({ match = { namespace = "quickshell:popup" }, blur = false })
hl.layer_rule({ match = { namespace = "quickshell:bar" }, animation = "slide" })
hl.layer_rule({ match = { namespace = "quickshell:actionCenter" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:cheatsheet" }, animation = "slide bottom" })
hl.layer_rule({ match = { namespace = "quickshell:dock" }, animation = "slide bottom" })
hl.layer_rule({ match = { namespace = "quickshell:screenCorners" }, animation = "popin 120%" })
hl.layer_rule({ match = { namespace = "quickshell:lockWindowPusher" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:notificationPopup" }, animation = "fade" })
hl.layer_rule({ match = { namespace = "quickshell:overlay" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:overlay" }, ignore_alpha = 1 })
-- hl.layer_rule({ match = { namespace = "quickshell:overview" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:osk" }, animation = "slide bottom" })
hl.layer_rule({ match = { namespace = "quickshell:polkit" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:popup" }, xray = false }) -- No weird color for bar tooltips (this in theory should suffice)
hl.layer_rule({ match = { namespace = "quickshell:popup" }, ignore_alpha = 1 }) -- No weird color for bar tooltips (but somehow this is necessary)
hl.layer_rule({ match = { namespace = "quickshell:mediaControls" }, ignore_alpha = 1 }) -- Same as above

-- ---- Launcher macOS (Quickshell) -------------------------------------------
-- Namespace-nya sengaja TIDAK mengandung kata "launcher" supaya tidak ikut kena
-- rule generik `namespace = "launcher"` di atas (regex tidak di-anchor, dulu itu
-- membuat blur terus menyala walaupun launcher.macos.blur = false).
-- Shell memilih namespace sesuai pengaturan:
--   macosLauncher       -> blur Hyprland aktif di belakang kartu
--   macosLauncherOpaque -> tanpa blur (default, paling murah & fade-out bersih)
-- no_anim: animasi buka/tutup dikerjakan QML (opacity+scale) sehingga compositor
-- tidak menambah popin/fade sendiri -- dulu keduanya jalan bersamaan.
hl.layer_rule({ match = { namespace = "^quickshell:macosLauncher$" }, no_anim = true })
hl.layer_rule({ match = { namespace = "^quickshell:macosLauncher$" }, blur = true })
hl.layer_rule({ match = { namespace = "^quickshell:macosLauncher$" }, ignore_alpha = 0.35 })
hl.layer_rule({ match = { namespace = "^quickshell:macosLauncherOpaque$" }, no_anim = true })
hl.layer_rule({ match = { namespace = "^quickshell:macosLauncherOpaque$" }, blur = false })
-- Penangkap klik di luar kartu: statis, tanpa animasi, tanpa blur.
hl.layer_rule({ match = { namespace = "^quickshell:macosLauncherScrim$" }, no_anim = true })
hl.layer_rule({ match = { namespace = "^quickshell:macosLauncherScrim$" }, blur = false })
hl.layer_rule({ match = { namespace = "quickshell:reloadPopup" }, animation = "slide" })
hl.layer_rule({ match = { namespace = "quickshell:regionSelector" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:screenshot" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:session" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell:session" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:session" }, ignore_alpha = 0 })

-- Rinauby Shell Rules (Digital Humanism / Renaissance Edition)
hl.layer_rule({ match = { namespace = "rinauby-session" }, blur = true })
hl.layer_rule({ match = { namespace = "rinauby-session" }, no_anim = true })
hl.layer_rule({ match = { namespace = "rinauby-session" }, ignore_alpha = 0 })

hl.layer_rule({ match = { namespace = "rinauby-launcher" }, blur = false })
hl.layer_rule({ match = { namespace = "rinauby-launcher" }, no_anim = true })

hl.layer_rule({ match = { namespace = "rinauby-mediacontrols" }, blur = false })
hl.layer_rule({ match = { namespace = "rinauby-mediacontrols" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:sidebarRight" }, animation = "slide right" })
hl.layer_rule({ match = { namespace = "quickshell:sidebarLeft" }, animation = "slide left" })
hl.layer_rule({ match = { namespace = "quickshell:verticalBar" }, animation = "slide" })
hl.layer_rule({ match = { namespace = "quickshell:osk" }, order = -1 })
-- Quickshell: waffles
hl.layer_rule({ match = { namespace = "quickshell:wallpaperSelector" }, animation = "fade" })
hl.layer_rule({ match = { namespace = "quickshell:wNotificationCenter" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:wOnScreenDisplay" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:wStartMenu" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:wTaskView" }, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "quickshell:wTaskView" }, no_anim = true })

-- Launchers need to be FAST
hl.layer_rule({ match = { namespace = "gtk4-layer-shell" }, no_anim = true })

-- 1. Mengatur transparansi jendela Kitty agar tembus pandang
hl.window_rule({
	match = { class = "kitty" },
})

-- 2. Memaksa lapisan blur aktif dan matikan proteksi 'no_blur' khusus untuk Kitty
hl.window_rule({
	match = { class = "kitty" },
	no_blur = false,
})

-- Memaksa lapisan blur aktif untuk Zed Editor
hl.window_rule({
	match = { class = "^(dev\\.zed\\.Zed|zed|zeditor)$" },
	no_blur = false,
})

-- hl.window_rule({
-- 	match = { class = "^(firefox)$" },
-- 	opacity = "0.88 0.88",
-- 	no_blur = false,
-- })

-- -- kalo aktifkan ini nonaktifkan diatas ini
-- -- Transparansi dan Blur khusus untuk Firefox / Gemini
-- hl.window_rule({
-- 	match = {
-- 		class = "^(firefox)$",
-- 		title = ".*(Gemini).*",
-- 	},
-- 	opacity = "0.88 0.88", -- Menggunakan tanda kutip string
-- 	no_blur = false,
-- })

-- -- Efek pop-up membal halus (Popin)
-- hl.layer_rule({ match = { namespace = "quickshell:overview" }, animation = "popin 80%" })
-- hl.layer_rule({ match = { namespace = "overview.*" }, animation = "popin 80%" })

-- ATAU jika lebih suka efek geser dari atas (Slide)
hl.layer_rule({ match = { namespace = "quickshell:overview" }, animation = "fade" })
hl.layer_rule({ match = { namespace = "overview.*" }, animation = "fade" })

-- -- 1. Project Manager Godot: Floating di tengah
-- hl.window_rule({
-- 	match = { class = "^(Godot)$", title = "^(Godot Engine - Project Manager)$" },
-- 	float = true,
-- 	center = true,
-- 	size = "960 600",
-- })
--
-- -- 2. Editor Utama Godot (Standard & .NET): Tiling
-- hl.window_rule({
-- 	match = { class = "^(Godot)$", title = ".* - Godot Engine$" },
-- 	tile = true,
-- })
--
-- -- 3. Jendela Play Game & Dialog Eksternal: Floating di tengah
-- hl.window_rule({
-- 	match = { class = "^(Godot)$", title = "^(?!.* - Godot Engine)(?!Godot Engine - Project Manager).*$" },
-- 	float = true,
-- 	center = true,
-- 	size = "1280 720",
-- 	stay_focused = true,
-- })
--
-- -- 1. Pastikan Editor Godot Utama membuka Group baru
-- hl.window_rule({
-- 	match = { class = "^(Godot)$", title = ".*Godot Engine.*" },
-- 	group = "set",
-- })
--
-- -- 2. Setiap jendela sub/game dari Godot otomatis dimasukkan ke dalam group yang sama
-- hl.window_rule({
-- 	match = { class = "^(Godot)$", title = "^((?!Godot Engine).)*$" },
-- 	group = "set",
-- })
--
-- Splash Screen: Fullscreen, kunci ukuran, dan abaikan event resize/maximize
hl.window_rule({
	match = { class = "^(qml6)$" },
	fullscreen = true,
	float = true,
	pin = true,
	no_anim = true,
	stay_focused = true,
	suppress_event = "maximize fullscreen activate activatefocus",
})

-- hl.window_rule({
-- 	match = {
-- 		class = "^(org.gnome.Nautilus)$",
-- 	},
-- 	opacity = "0.88 0.88", -- Menggunakan tanda kutip string
-- 	no_blur = false,
-- })
hl.layer_rule({ match = { namespace = "quickshell:overview" }, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "quickshell:overview" }, blur = true })

-- macOS Launcher: Floating card blur dan animasi popin
hl.layer_rule({ match = { namespace = "quickshell:macos-launcher" }, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "quickshell:macos-launcher" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell:macos-launcher" }, animation = "popin 85%" })

-- Floating rule for file choosers
hl.window_rule({
	match = { class = "^(xdg-desktop-portal-gtk|zenity|kdialog|yazi-picker)$" },
	float = true,
	center = true,
	size = { "(monitor_w*0.60)", "(monitor_h*0.65)" },
})

-- Window rule khusus untuk Maximize Max (SUPER + SHIFT + M)
-- Menghilangkan border dan sudut lengkung saat jendela ditandai tag maximize_max
hl.window_rule({
	name = "maximize-max-style",
	match = { tag = "maximize_max" },
	border_size = 0,
	rounding = 0,
})

-- Window rule khusus Age of Empires II DE (Low Latency / Tearing + Prevent Sleep)
hl.window_rule({
	match = { class = "^(AoE2DE_s.exe)$" },
	immediate = true,
})

-- Rule untuk Roblox Studio (Floating agar dropdown/pop-up tidak tertutup)
hl.window_rule({
	match = { class = "^(RobloxStudioBeta.exe)$" },
	no_initial_focus = false,
	float = true,
})

-- Rule tambahan jika match berdasarkan title
hl.window_rule({
	match = { title = "^(Roblox Studio)$" },
	no_initial_focus = false,
	float = true,
})
