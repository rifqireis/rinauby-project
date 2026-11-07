-- local home_dir = os.getenv("HOME")
--
-- -- Wayland
-- hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
--
-- -- Applications
-- local xdg_data_dirs_old = os.getenv("XDG_DATA_DIRS") or ""
-- hl.env("XDG_DATA_DIRS", home_dir .. "/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share:" .. xdg_data_dirs_old)
--
-- -- Themes
-- hl.env("QT_QPA_PLATFORM", "wayland;xcb")
-- hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
-- hl.env("XDG_MENU_PREFIX", "plasma-")
--
-- -- Virtual environment
-- hl.env("ILLOGICAL_IMPULSE_VIRTUAL_ENV", home_dir .. "/.local/state/quickshell/.venv")

local home_dir = os.getenv("HOME")

-- Wayland & Session Identity
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Toolkit Backends (Wayland First)
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")

-- Electron & Browser Optimization (DMA-BUF / RAM Efficiency)
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- Hardware Acceleration (Intel Iris Xe GPU)
hl.env("LIBVA_DRIVER_NAME", "iHD")

-- Vulkan / DXVK & Mesa Pipeline Optimization (Anti-flicker cold start)
hl.env("DXVK_ASYNC", "1")
hl.env("MESA_SHADER_CACHE_DIR", home_dir .. "/.cache/mesa_shader_cache")

-- Memory Allocator (jemalloc tuning for Quickshell & background memory recycling)
hl.env("MALLOC_CONF", "background_thread:true,dirty_decay_ms:1000,muzzy_decay_ms:1000")

-- Themes & Desktop Integration
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("XDG_MENU_PREFIX", "plasma-")
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE", "24")

-- Sync QS_ICON_THEME with GTK 4 / GTK 3 settings
local function get_gtk_icon_theme()
	local files = {
		home_dir .. "/.config/gtk-4.0/settings.ini",
		home_dir .. "/.config/gtk-3.0/settings.ini",
	}
	for _, file in ipairs(files) do
		local f = io.open(file, "r")
		if f then
			for line in f:lines() do
				local key, val = line:match("^%s*([^=]+)%s*=%s*(.-)%s*$")
				if key == "gtk-icon-theme-name" and val and val ~= "" then
					f:close()
					return val
				end
			end
			f:close()
		end
	end
	return "Adwaita"
end
hl.env("QS_ICON_THEME", get_gtk_icon_theme())


-- Applications & XDG Paths
local function clean_path_list(paths_str)
	local seen = {}
	local result = {}
	for p in string.gmatch(paths_str, "[^:]+") do
		if not seen[p] then
			seen[p] = true
			table.insert(result, p)
		end
	end
	return table.concat(result, ":")
end

local default_data_dirs = home_dir
	.. "/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share"
local xdg_data_dirs_old = os.getenv("XDG_DATA_DIRS") or "/usr/local/share:/usr/share"
hl.env("XDG_DATA_DIRS", clean_path_list(default_data_dirs .. ":" .. xdg_data_dirs_old))

local current_path = os.getenv("PATH") or "/usr/local/bin:/usr/bin"
hl.env("PATH", clean_path_list(home_dir .. "/.local/bin:" .. current_path))

-- Virtual Environment (Illogical Impulse / Quickshell)
hl.env("ILLOGICAL_IMPULSE_VIRTUAL_ENV", home_dir .. "/.local/state/quickshell/.venv")
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")

