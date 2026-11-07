-- This file sources other files in `hyprland` and `custom` folders
-- You wanna add your stuff in files in `custom`

-- Internal stuff --
require("hyprland.lib")
require("hyprland.services")

-- Muat plugin sistem sebelum modul konfigurasi dievaluasi (dinonaktifkan sementara)
-- pcall(function()
-- 	local hyprexpo_plugin = HOME .. "/.config/hypr/plugins/hyprexpo.so"
-- 	if is_file_exists(hyprexpo_plugin) then
-- 		hl.plugin.load(hyprexpo_plugin)
-- 	end
-- end)

-- Environment & Modular Configurations --
-- Urutan pemuatan deterministik 2-lapis: hyprland/ (Base Default) -> custom/ (GUI Override)
local modules = {
	"variables",
	"env",
	"execs",
	"general",
	"rules",
	"keybinds",
	"colors",
}

for _, mod in ipairs(modules) do
	-- 1. Muat konfigurasi default sistem
	pcall(require, "hyprland." .. mod)

	-- 2. Muat konfigurasi kustom dari Pengaturan Desktop (GUI)
	-- Catatan: 'keybinds' dipusatkan murni di hyprland/keybinds.lua agar tidak rusak/tertimpa GUI
	if mod ~= "keybinds" then
		local custom_file = HOME .. "/.config/hypr/custom/" .. mod .. ".lua"
		if is_file_exists(custom_file) then
			package.loaded["custom." .. mod] = nil
			dofile(custom_file)
		end
	end
end

-- nwg-displays support --
if is_file_exists(HOME .. "/.config/hypr/workspaces.lua") then
	pcall(dofile, HOME .. "/.config/hypr/workspaces.lua")
end
if is_file_exists(HOME .. "/.config/hypr/monitors.lua") then
	pcall(dofile, HOME .. "/.config/hypr/monitors.lua")
end

-- Shell overrides --
require("hyprland.shellOverrides.main")

