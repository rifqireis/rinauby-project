-- Helper pemanggilan layanan bawaan yang mendukung penonaktifan non-destruktif dari custom/execs.lua
local function run_base(tag, cmd)
	local disabled = _G.disabled_base_execs or disabled_base_execs or {}
	if not disabled[tag] then
		hl.exec_cmd(cmd)
	end
end

-- put former exec-once commands inside the func and former exec commands outside
hl.on("hyprland.start", function()
	-- Rinauby Unified Autostart (Wayland, Awww, Wallpaper, Quickshell)
	run_base("rinauby-autostart", "command -v rinauby-autostart >/dev/null 2>&1 && rinauby-autostart")

	-- Splash Screen (Dijalankan paling awal jika tersedia)
	run_base("QuickSplash", "qs -p $HOME/.config/hypr/splash")

	-- Bar, wallpaper (Quickshell dijalankan dalam mode daemon)
	run_base("qs", "qs -c $qsConfig -d")
	-- run_base("auto-theme", "$HOME/.config/hypr/scripts/auto-theme.sh") -- Digantikan oleh systemd timer Desktop Wallpapers (Zero-Resident)
	run_base("video_wallpaper", "$HOME/.config/hypr/custom/scripts/__restore_video_wallpaper.sh")
	run_base("wallpaper-changer-startup", "$HOME/.local/bin/wallpaper-changer --startup 2>/dev/null || true")

	-- Core components (authentication, lock screen, notification daemon)
	run_base("gnome-keyring", "gnome-keyring-daemon --start --components=secrets")
	run_base("hypridle", "systemctl --user start hypridle.service || hypridle")
	hl.exec_cmd("dbus-update-activation-environment --all")
	hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP") -- Some fix idk

	-- Audio
	--hl.exec_cmd("easyeffects --hide-window --service-mode")

	-- Clipboard: history
	local disabled = _G.disabled_base_execs or disabled_base_execs or {}
	if not disabled["cliphist"] then
		hl.exec_cmd(
			"wl-paste --type text --watch bash -c 'cliphist store && qs -c $qsConfig ipc call cliphistService update'"
		)
		hl.exec_cmd(
			"wl-paste --type image --watch bash -c 'cliphist store && qs -c $qsConfig ipc call cliphistService update'"
		)
	end

	-- Cursor
	run_base("cursor", "hyprctl setcursor Bibata-Modern-Ice 24")

	-- KDE connect (daemon murni tanpa GUI indicator)
	run_base("kdeconnectd", "/usr/bin/kdeconnectd")

	-- Hyprpm plugins (Dinonaktifkan: hyprpm tidak terpasang)
	-- run_base("hyprpm", "hyprpm reload -n")

	-- Awww daemon (Dinonaktifkan: Quickshell Background.qml menangani wallpaper secara mandiri)
	-- run_base("awww", "awww-daemon")
end)


