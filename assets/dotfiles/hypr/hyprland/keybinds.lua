require("hyprland.lib")
require("hyprland.variables")
if is_file_exists(HOME .. "/.config/hypr/custom/variables.lua") then
	require("custom.variables")
end

---------------------------------------------------------------------
-- 1. DEFINISI VARIABEL & PATH
---------------------------------------------------------------------
local qsScripts = "$HOME/.config/quickshell/$qsConfig/scripts"
local hyprScripts = "$HOME/.config/hypr/hyprland/scripts"
local qsIpcCall = "qs -c $qsConfig ipc call"

local terminal = _G.terminal or terminal or "kitty -1"
local fileManager = _G.fileManager or fileManager or "nautilus"
local browser = _G.browser or browser or "brave"
local codeEditor = _G.codeEditor or codeEditor or "zeditor"

---------------------------------------------------------------------
-- 2. HARDWARE INPUT & MEDIA
---------------------------------------------------------------------
-- Remap Caps Lock menjadi Escape
hl.config({
	input = {
		kb_options = "caps:escape",
	},
})

-- Kecerahan Layar (Brightness)
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd(qsIpcCall .. " brightness increment || brightnessctl s 5%+"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd(qsIpcCall .. " brightness decrement || brightnessctl s 5%-"),
	{ locked = true, repeating = true }
)

-- Volume Audio & Mic (Wireplumber)
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+ -l 1.5"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"),
	{ locked = true, repeating = true }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })

-- Kontrol Media (Playerctl)
local mediaNextCommand =
	'playerctl next || playerctl position `bc <<< "100 * $(playerctl metadata mpris:length) / 1000000 / 100"`'
hl.bind("SUPER + SHIFT + N", hl.dsp.exec_cmd(mediaNextCommand), { locked = true, description = "Media: Next track" })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd(mediaNextCommand), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })

-- Zoom Factor Layar (Cursor Zoom)
local function zoomfunction(value)
	local zoomvalue = hl.get_config("cursor:zoom_factor")
	if (zoomvalue + value) > 3.0 then
		hl.config({ cursor = { zoom_factor = 3.0 } })
	elseif (zoomvalue + value) < 1.0 then
		hl.config({ cursor = { zoom_factor = 1.0 } })
	else
		hl.config({ cursor = { zoom_factor = zoomvalue + value } })
	end
end
hl.bind("SUPER + Minus", function() zoomfunction(-0.3) end, { repeating = true })
hl.bind("SUPER + Equal", function() zoomfunction(0.3) end, { repeating = true })
hl.bind("SUPER + code:82", function() zoomfunction(-0.3) end, { repeating = true })
hl.bind("SUPER + code:86", function() zoomfunction(0.3) end, { repeating = true })

---------------------------------------------------------------------
-- 3. APLIKASI UTAMA (APPS)
---------------------------------------------------------------------
hl.bind("SUPER + T", hl.dsp.exec_cmd(terminal), { description = "App: Terminal" })
hl.bind("CTRL + ALT + T", hl.dsp.exec_cmd(terminal), { description = "App: Terminal (Alt)" })
hl.bind("SUPER + E", hl.dsp.exec_cmd(fileManager), { description = "App: File manager" })
hl.bind("SUPER + B", hl.dsp.exec_cmd(browser), { description = "App: Web browser" })
hl.bind("SUPER + C", hl.dsp.exec_cmd(codeEditor), { description = "App: Code editor" })
hl.bind("CTRL + SUPER + V", hl.dsp.exec_cmd("pavucontrol"), { description = "App: Volume mixer" })
hl.bind("CTRL + SHIFT + Escape", hl.dsp.exec_cmd("gnome-system-monitor"), { description = "App: Task manager" })

---------------------------------------------------------------------
-- 4. QUICKSHELL UI & SHELL LAUNCHER
---------------------------------------------------------------------
-- App Launcher & Search
hl.bind(
	"SUPER + Space",
	hl.dsp.global("quickshell:searchToggleRelease"),
	{ description = "Shell: Buka Menu Pencarian & Peluncur Aplikasi" }
)

-- Overlay indikator workspace saat tombol SUPER ditekan & dilepas
hl.bind("SUPER_L", hl.dsp.global("quickshell:workspaceNumber"), { ignore_mods = true, transparent = true })
hl.bind("SUPER_R", hl.dsp.global("quickshell:workspaceNumber"), { ignore_mods = true, transparent = true })
hl.bind("SUPER_L", hl.dsp.global("quickshell:workspaceNumber"), { ignore_mods = true, transparent = true, release = true })
hl.bind("SUPER_R", hl.dsp.global("quickshell:workspaceNumber"), { ignore_mods = true, transparent = true, release = true })

-- Quicksettings / Control Center & Notifikasi (Sidebar Kanan)
hl.bind("SUPER + A", hl.dsp.global("quickshell:sidebarRightToggle"), { description = "Shell: Toggle Quicksettings & Notifikasi" })

-- Utilities (Sidebar Kiri)
hl.bind("SUPER + ALT + A", hl.dsp.global("quickshell:sidebarLeftToggle"), { description = "Shell: Toggle Left Sidebar" })

-- Session / Power Menu (Lock, Shutdown, Reboot, Suspend)
hl.bind("SUPER + X", hl.dsp.global("quickshell:sessionToggle"), { description = "Shell: Toggle Session & Power Menu" })

-- Clipboard Manager & Emoji
hl.bind("SUPER + V", hl.dsp.global("quickshell:overviewClipboardToggle"), { description = "Shell: Toggle Clipboard History" })
hl.bind("SUPER + Period", hl.dsp.global("quickshell:overviewEmojiToggle"), { description = "Shell: Toggle Emoji Picker" })

-- Bantuan Cheatsheet & AI Launcher
hl.bind("SUPER + Slash", hl.dsp.global("quickshell:cheatsheetToggle"), { description = "Shell: Toggle Cheatsheet" })
hl.bind("SUPER + grave", hl.dsp.global("quickshell:aiLauncherToggle"), { description = "Shell: Toggle AI Launcher" })

-- Wallpaper & Tema
hl.bind("CTRL + SUPER + T", hl.dsp.global("quickshell:wallpaperSelectorToggle"), { description = "Shell: Change Wallpaper" })
hl.bind("CTRL + SUPER + ALT + T", hl.dsp.global("quickshell:wallpaperSelectorRandom"), { description = "Shell: Random Wallpaper" })
hl.bind("CTRL + SUPER + SHIFT + D", hl.dsp.global("quickshell:toggleLightDark"), { description = "Shell: Toggle Light/Dark Mode" })
hl.bind("CTRL + SUPER + P", hl.dsp.global("quickshell:panelFamilyCycle"), { description = "Shell: Cycle Panel Family" })
hl.bind(
	"CTRL + SUPER + R",
	hl.dsp.exec_cmd("killall -w -q qs quickshell 2>/dev/null; qs -c $qsConfig -d &"),
	{ description = "Shell: Restart Quickshell Widgets" }
)

---------------------------------------------------------------------
-- 5. UTILITAS & SCREENSHOT
---------------------------------------------------------------------
-- Screen Snip / Screenshot Area
hl.bind("SUPER + SHIFT + Space", hl.dsp.global("quickshell:regionScreenshot"), { description = "Utilities: Screen snip" })

-- Screenshot Layar Penuh
local grimhyprctl = 'grim -o "$(hyprctl activeworkspace -j | jq -r \'.monitor\')"'
hl.bind("Print", hl.dsp.exec_cmd(grimhyprctl .. " - | wl-copy"), { locked = true, description = "Utilities: Screenshot >> Clipboard" })
hl.bind(
	"CTRL + Print",
	hl.dsp.exec_cmd(
		"mkdir -p $(xdg-user-dir PICTURES)/Screenshots && "
			.. grimhyprctl
			.. ' $(xdg-user-dir PICTURES)/Screenshots/Screenshot_"$(date \'+%Y-%m-%d_%H.%M.%S\')".png && '
			.. grimhyprctl .. " - | wl-copy"
	),
	{ locked = true, description = "Utilities: Screenshot >> File & Clipboard" }
)

-- Google Lens & AI Utilities
hl.bind("SUPER + SHIFT + Semicolon", hl.dsp.global("quickshell:regionSearch"), { description = "Utilities: Google Lens (Region Search)" })
hl.bind("SUPER + SHIFT + X", hl.dsp.global("quickshell:regionOcr"), { description = "Utilities: OCR >> Clipboard" })
hl.bind("SUPER + SHIFT + T", hl.dsp.global("quickshell:screenTranslate"), { description = "Utilities: Screen Translate" })
hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"), { description = "Utilities: Color Picker >> Clipboard" })

-- Screen Recording
hl.bind("SUPER + SHIFT + R", hl.dsp.global("quickshell:regionRecord"), { locked = true, description = "Utilities: Record Region" })
hl.bind("CTRL + ALT + R", hl.dsp.exec_cmd(qsScripts .. "/videos/record.sh --fullscreen"), { locked = true, description = "Utilities: Record Fullscreen" })
hl.bind("SUPER + SHIFT + ALT + R", hl.dsp.exec_cmd(qsScripts .. "/videos/record.sh --fullscreen --sound"), { locked = true, description = "Utilities: Record Fullscreen with Sound" })

---------------------------------------------------------------------
-- 6. MANAJEMEN JENDELA (WINDOW CONTROLS & SIZING)
---------------------------------------------------------------------
-- Helper: Deteksi & Penanganan Bersih Jendela Waydroid
local function is_waydroid_window(win)
	if not win then return false end
	local c = (win.class or ""):lower()
	local ic = (win.initialClass or ""):lower()
	local t = (win.title or ""):lower()
	return c:find("waydroid") ~= nil or ic:find("waydroid") ~= nil or t:find("waydroid") ~= nil
end

local function get_waydroid_app_package(win)
	if not win then return nil end
	local c = win.class or ""
	local ic = win.initialClass or ""
	local t = (win.title or ""):lower()

	local pkg = c:match("^[Ww]aydroid%.([%w_%.]+)") or ic:match("^[Ww]aydroid%.([%w_%.]+)")
	if pkg and pkg ~= "" then return pkg end
	if c:lower():find("mobile%.legends") or ic:lower():find("mobile%.legends") or t:find("mobile legends") then
		return "com.mobile.legends"
	end
	return nil
end

-- Close Window Pintar (Menutup app Android secara bersih tanpa mematikan sesi kontainer)
hl.bind("SUPER + Q", function()
	local w = hl.get_active_window()
	if w and is_waydroid_window(w) then
		local pkg = get_waydroid_app_package(w)
		if pkg then
			os.execute("adb shell am force-stop " .. pkg .. " >/dev/null 2>&1 &")
			hl.dispatch(hl.dsp.window.close())
		else
			hl.dispatch(hl.dsp.window.close())
		end
	else
		hl.dispatch(hl.dsp.window.close())
	end
end, { description = "Window: Close" })

-- Force Kill Jendela Hang / Beku
hl.bind("SUPER + SHIFT + ALT + Q", hl.dsp.exec_cmd("hyprctl kill"), { description = "Window: Force Zap Window" })
hl.bind("ALT + F4", function()
	hl.exec_cmd('notify-send "Pintasan Tutup Jendela" "Gunakan Super+Q untuk menutup jendela di Hyprland" -a Hyprland')
end, { non_consuming = true })

-- Helper & Fungsi Smart Float (55% x 65% dengan Auto Staggering / Cascade)
local function resize_and_center_float(w)
	if not w then return end

	local m = hl.get_active_monitor()
	local scale = (m and m.scale and m.scale > 0) and m.scale or 1.0
	local mon_w = m and (m.width / scale) or 1920
	local mon_h = m and (m.height / scale) or 1080
	if m and (m.transform or 0) % 2 == 1 then
		mon_w, mon_h = mon_h, mon_w
	end

	local res = m and m.reserved or {}
	local pad_l = res.left or 0
	local pad_t = res.top or 0
	local pad_r = res.right or 0
	local pad_b = res.bottom or 0

	local mon_x = (m and m.position and m.position.x) or 0
	local mon_y = (m and m.position and m.position.y) or 0

	local target_w = math.floor(mon_w * 0.55)
	local target_h = math.floor(mon_h * 0.65)
	local avail_w = mon_w - pad_l - pad_r
	local avail_h = mon_h - pad_t - pad_b

	local base_x = mon_x + pad_l + math.floor((avail_w - target_w) / 2)
	local base_y = mon_y + pad_t + math.floor((avail_h - target_h) / 2)

	local cur_ws_id = w.workspace and w.workspace.id
	local other_floats = {}
	if cur_ws_id then
		for _, other in ipairs(hl.get_windows() or {}) do
			if other.address ~= w.address and other.floating and other.workspace and other.workspace.id == cur_ws_id then
				table.insert(other_floats, other)
			end
		end
	end

	local chosen_x = base_x
	local chosen_y = base_y

	if #other_floats > 0 then
		local candidate_slots = {
			{ x = 0, y = 0 }, { x = 40, y = 40 }, { x = 80, y = 80 }, { x = 120, y = 120 },
			{ x = -40, y = 40 }, { x = -80, y = 80 }, { x = 40, y = -40 }, { x = 80, y = -40 },
			{ x = 160, y = 160 }, { x = -120, y = 120 },
		}
		for _, slot in ipairs(candidate_slots) do
			local cand_x = base_x + slot.x
			local cand_y = base_y + slot.y
			local occupied = false
			for _, other in ipairs(other_floats) do
				if other.at and other.at.x and other.at.y then
					local dx = math.abs(other.at.x - cand_x)
					local dy = math.abs(other.at.y - cand_y)
					if dx < 28 and dy < 28 then
						occupied = true
						break
					end
				end
			end
			if not occupied then
				chosen_x = cand_x
				chosen_y = cand_y
				break
			end
		end
	end

	local min_x = mon_x + pad_l
	local max_x = mon_x + mon_w - pad_r - target_w
	local min_y = mon_y + pad_t
	local max_y = mon_y + mon_h - pad_b - target_h

	chosen_x = math.max(min_x, math.min(chosen_x, max_x))
	chosen_y = math.max(min_y, math.min(chosen_y, max_y))

	hl.dispatch(hl.dsp.window.resize({ window = w, x = target_w, y = target_h, relative = false }))
	hl.dispatch(hl.dsp.window.move({ window = w, x = chosen_x, y = chosen_y, relative = false }))
end

-- Toggle Float Pintar / Tiling
hl.bind("SUPER + F", function()
	local w = hl.get_active_window()
	if not w then return end

	if w.floating then
		hl.dispatch(hl.dsp.window.float({ action = "set", window = w, value = false }))
	else
		if w.fullscreen ~= 0 then
			hl.dispatch(hl.dsp.window.fullscreen({ action = "set", window = w, value = false }))
		end
		hl.dispatch(hl.dsp.window.float({ action = "set", window = w, value = true }))
		resize_and_center_float(w)
	end
end, { description = "Window: Float (55%x65% Center) / Tile" })

-- Maximize MAX (SUPER + SHIFT + M): Gaps = 0, Border = 0, mepet rapat ke panel bar
local max_max_saved = {}

local function restore_maximize_max(w)
	if not w or not max_max_saved[w.address] then return end
	hl.dispatch(hl.dsp.window.tag({ window = w, tag = "maximize_max" }))
	local prev = max_max_saved[w.address]
	if prev and prev.was_floating then
		resize_and_center_float(w)
	else
		hl.dispatch(hl.dsp.window.float({ action = "set", window = w, value = false }))
	end
	max_max_saved[w.address] = nil
end

local function toggle_maximize_max()
	local w = hl.get_active_window()
	if not w then return end

	local is_max_max = false
	if w.tags then
		for _, t in ipairs(w.tags) do
			if t == "maximize_max" then
				is_max_max = true
				break
			end
		end
	end

	if is_max_max then
		restore_maximize_max(w)
	else
		if w.fullscreen ~= 0 then
			hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "unset", window = w }))
		end

		max_max_saved[w.address] = { was_floating = w.floating }
		local mon = hl.get_active_monitor()
		if not mon then return end

		local mw, mh = mon.width, mon.height
		if (mon.transform or 0) % 2 == 1 then mw, mh = mh, mw end

		local res = mon.reserved or {}
		local pad_l = res.left or 0
		local pad_t = res.top or 0
		local pad_r = res.right or 0
		local pad_b = res.bottom or 0

		local x = mon.position.x + pad_l
		local y = mon.position.y + pad_t
		local width = mw - pad_l - pad_r
		local height = mh - pad_t - pad_b

		hl.dispatch(hl.dsp.window.float({ action = "set", window = w, value = true }))
		hl.dispatch(hl.dsp.window.resize({ window = w, x = width, y = height, relative = false }))
		hl.dispatch(hl.dsp.window.move({ window = w, x = x, y = y, relative = false }))
		hl.dispatch(hl.dsp.window.tag({ window = w, tag = "maximize_max" }))
	end
end

if hl.on then
	hl.on("window.open", function()
		local ws = hl.get_active_workspace()
		if not ws then return end
		local windows = hl.get_windows() or {}
		for _, w in ipairs(windows) do
			if w.workspace and w.workspace.id == ws.id and max_max_saved[w.address] then
				restore_maximize_max(w)
				break
			end
		end
	end)
end

hl.bind("SUPER + SHIFT + Z", toggle_maximize_max, { description = "Window: Maximize MAX (No gaps, no border)" })

-- Maximize Biasa (Tetap ada margin & panel)
hl.bind("SUPER + Z", function()
	local w = hl.get_active_window()
	if w and w.tags then
		for _, t in ipairs(w.tags) do
			if t == "maximize_max" then
				hl.dispatch(hl.dsp.window.tag({ window = w, tag = "maximize_max" }))
				hl.dispatch(hl.dsp.window.float({ action = "set", window = w, value = false }))
				max_max_saved[w.address] = nil
				break
			end
		end
	end
	hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
end, { description = "Window: Maximize (Normal)" })

-- True Fullscreen (Menutupi seluruh layar & panel bar)
hl.bind("SUPER + SHIFT + F", function()
	local w = hl.get_active_window()
	if w and w.tags then
		for _, t in ipairs(w.tags) do
			if t == "maximize_max" then
				hl.dispatch(hl.dsp.window.tag({ window = w, tag = "maximize_max" }))
				hl.dispatch(hl.dsp.window.float({ action = "set", window = w, value = false }))
				max_max_saved[w.address] = nil
				break
			end
		end
	end
	hl.dispatch(hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
end, { description = "Window: True Fullscreen (No panel)" })

-- Tiling Controls & Split Ratio
hl.bind("SUPER + D", hl.dsp.exec_cmd("hyprctl dispatch togglesplit"), { description = "Layout: Toggle Split Orientation" })
hl.bind("SUPER + Semicolon", hl.dsp.layout("splitratio -0.1"), { repeating = true, description = "Layout: Split Ratio -0.1" })
hl.bind("SUPER + Apostrophe", hl.dsp.layout("splitratio +0.1"), { repeating = true, description = "Layout: Split Ratio +0.1" })

---------------------------------------------------------------------
-- 7. NAVIGASI VIM & GROUP TABS
---------------------------------------------------------------------
-- Fokus Jendela: Vim Style (H / J / K / L)
hl.bind("SUPER + H", function()
	if is_file_exists("/dev/shm/qs_appgrid_active") then
		hl.dispatch(hl.dsp.global("quickshell:appGridPagePrev"))
	else
		hl.dispatch(hl.dsp.focus({ direction = "left" }))
	end
end, { description = "Window: Focus Left / App Grid Prev" })

hl.bind("SUPER + L", function()
	if is_file_exists("/dev/shm/qs_appgrid_active") then
		hl.dispatch(hl.dsp.global("quickshell:appGridPageNext"))
	else
		hl.dispatch(hl.dsp.focus({ direction = "right" }))
	end
end, { description = "Window: Focus Right / App Grid Next" })

hl.bind("SUPER + K", hl.dsp.focus({ direction = "up" }), { description = "Window: Focus Up" })
hl.bind("SUPER + J", hl.dsp.focus({ direction = "down" }), { description = "Window: Focus Down" })

-- Fokus Jendela: Tombol Panah (Alternatif)
hl.bind("SUPER + Left", hl.dsp.focus({ direction = "left" }), { description = "Window: Focus Left" })
hl.bind("SUPER + Right", hl.dsp.focus({ direction = "right" }), { description = "Window: Focus Right" })
hl.bind("SUPER + Up", hl.dsp.focus({ direction = "up" }), { description = "Window: Focus Up" })
hl.bind("SUPER + Down", hl.dsp.focus({ direction = "down" }), { description = "Window: Focus Down" })

-- Memindahkan Posisi Jendela: Vim Style
hl.bind("SUPER + SHIFT + H", hl.dsp.window.move({ direction = "left" }), { description = "Window: Move Left" })
hl.bind("SUPER + SHIFT + L", hl.dsp.window.move({ direction = "right" }), { description = "Window: Move Right" })
hl.bind("SUPER + SHIFT + K", hl.dsp.window.move({ direction = "up" }), { description = "Window: Move Up" })
hl.bind("SUPER + SHIFT + J", hl.dsp.window.move({ direction = "down" }), { description = "Window: Move Down" })

-- Memindahkan Posisi Jendela: Tombol Panah
hl.bind("SUPER + SHIFT + Left", hl.dsp.window.move({ direction = "left" }), { description = "Window: Move Left" })
hl.bind("SUPER + SHIFT + Right", hl.dsp.window.move({ direction = "right" }), { description = "Window: Move Right" })
hl.bind("SUPER + SHIFT + Up", hl.dsp.window.move({ direction = "up" }), { description = "Window: Move Up" })
hl.bind("SUPER + SHIFT + Down", hl.dsp.window.move({ direction = "down" }), { description = "Window: Move Down" })

-- Tabbed Grouping
hl.bind("SUPER + G", function()
	local w = hl.get_active_window()
	if not w then return end

	local g = w.group
	local members = g and g.members
	local count = members and #members or 0

	if count <= 1 then
		hl.dispatch(hl.dsp.group.toggle())
	else
		hl.dispatch(hl.dsp.window.move({ out_of_group = true }))
	end
end, { description = "Group: Smart Toggle (Create / Cancel / Eject Tab)" })
hl.bind("SUPER + SHIFT + G", hl.dsp.group.toggle(), { description = "Group: Dissolve Group" })
hl.bind("SUPER + BracketLeft", hl.dsp.group.prev(), { description = "Group: Prev Tab in Group" })
hl.bind("SUPER + BracketRight", hl.dsp.group.next(), { description = "Group: Next Tab in Group" })
hl.bind("CTRL + SUPER + H", hl.dsp.window.move({ into_group = "left" }), { description = "Group: Move Window into Left Group" })
hl.bind("CTRL + SUPER + L", hl.dsp.window.move({ into_group = "right" }), { description = "Group: Move Window into Right Group" })
hl.bind("CTRL + SUPER + K", hl.dsp.window.move({ into_group = "up" }), { description = "Group: Move Window into Upper Group" })
hl.bind("CTRL + SUPER + J", hl.dsp.window.move({ into_group = "down" }), { description = "Group: Move Window into Lower Group" })

---------------------------------------------------------------------
-- 8. WORKSPACE & SCRATCHPAD
---------------------------------------------------------------------
-- Berpindah Antar Workspace [1-10]
for i = 1, 10 do
	local key = i % 10
	hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Pindah ke Workspace Sebelumnya
hl.bind("SUPER + Tab", hl.dsp.focus({ workspace = "previous" }), { description = "Workspace: Switch to Previous Workspace" })

-- Scratchpad (Special Workspace)
hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("special"), { description = "Workspace: Toggle Scratchpad" })
hl.bind(
	"SUPER + SHIFT + S",
	hl.dsp.window.move({ workspace = "special:special", follow = false }),
	{ description = "Window: Send Window to Scratchpad (Silent)" }
)

-- Navigasi Workspace via Mouse
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Drag & Resize Window dengan Mouse
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("SUPER + mouse:274", hl.dsp.window.drag(), { mouse = true })

---------------------------------------------------------------------
-- 9. PLUGINS (HYPREXPO) - Dinonaktifkan sementara
---------------------------------------------------------------------
-- pcall(function()
-- 	hl.config({
-- 		plugin = {
-- 			hyprexpo = {
-- 				columns = 3,
-- 				gaps_in = 5,
-- 				gaps_out = 10,
-- 				bg_col = "rgb(111111)",
-- 				workspace_method = "center current",
-- 				gesture_fingers = 3,
-- 				gesture_distance = 300,
-- 			},
-- 		},
-- 	})
-- end)
-- 
-- -- Toggle Overview Kisi Workspace (HyprExpo)
-- hl.bind("SUPER + W", function()
-- 	pcall(function()
-- 		hl.plugin.hyprexpo.expo("toggle")
-- 	end)
-- end, { description = "Plugin: HyprExpo Grid Overview" })

---------------------------------------------------------------------
-- 10. SUBMAPS & SYSTEM
---------------------------------------------------------------------
-- Submap Mesin Virtual (VM Keybinds Passthrough)
hl.define_submap("virtual-machine", function()
	hl.bind("SUPER + ALT + F1", function()
		local currentsubmap = hl.get_current_submap()
		if currentsubmap == "virtual-machine" then
			hl.dispatch(hl.dsp.exec_cmd("notify-send 'Exited Virtual Machine submap' 'Keybinds re-enabled' -a 'Hyprland'"))
			hl.dispatch(hl.dsp.submap("reset"))
		elseif currentsubmap == "" then
			hl.dispatch(hl.dsp.exec_cmd("notify-send 'Entered Virtual Machine submap' 'Keybinds disabled. Tekan SUPER+ALT+F1 untuk keluar' -a 'Hyprland'"))
			hl.dispatch(hl.dsp.submap("virtual-machine"))
		end
	end, { submap_universal = true })
end)

-- Reload Konfigurasi Hyprland
hl.bind("SUPER + R", hl.dsp.exec_cmd("hyprctl reload"), { description = "System: Reload Hyprland config" })

