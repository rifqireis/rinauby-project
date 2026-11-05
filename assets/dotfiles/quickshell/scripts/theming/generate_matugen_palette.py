#!/usr/bin/env python3
"""
Rinauby Monochromatic Matugen Palette Generator
Extracts dominant colors from wallpapers using Matugen and synchronizes:
- Quickshell: ~/.local/state/serpantinum/qs_colors.json & qs_matugen_colors.json
- Waybar: ~/.config/waybar/theme.css
- Hyprland: Active & Inactive window borders
- Rofi: ~/.config/rofi/theme_colors.rasi
- Kitty: ~/.config/kitty/current-theme.conf

Design Standard:
- Strict monochromatic visual harmony (1 primary accent hue).
- Flat dark surfaces, high contrast, zero clashing complementary colors.
"""

import sys
import os
import json
import subprocess
import shutil

def hex_to_rgb(hex_str):
    h = hex_str.lstrip("#")
    if len(h) == 3:
        h = "".join([c*2 for c in h])
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def hex_to_rgba_css(hex_str, alpha):
    r, g, b = hex_to_rgb(hex_str)
    return f"rgba({r}, {g}, {b}, {alpha:.2f})"

def fallback_palette():
    return {
        "primary": "#89b4fa",
        "on_primary": "#11111b",
        "primary_container": "#74c7ec",
        "surface": "#181825",
        "surface_container_lowest": "#11111b",
        "surface_container_low": "#181825",
        "surface_container": "#252739",
        "surface_container_high": "#313244",
        "surface_container_highest": "#45475a",
        "on_surface": "#cdd6f4",
        "on_surface_variant": "#a6adc8",
        "outline": "#6c7086",
        "outline_variant": "#45475a",
        "error": "#f38ba8"
    }

def extract_matugen(wallpaper_path, mode="dark", scheme_type="scheme-fidelity"):
    if not shutil.which("matugen"):
        print("[matugen] 'matugen' binary not found. Falling back to default palette.", file=sys.stderr)
        return fallback_palette()

    try:
        cmd = [
            "matugen", "image", wallpaper_path,
            "-m", mode,
            "-t", scheme_type,
            "--prefer", "saturation",
            "--source-color-index", "0",
            "-j", "hex",
            "--dry-run"
        ]
        res = subprocess.check_output(cmd, stderr=subprocess.DEVNULL, timeout=10)
        data = json.loads(res.decode("utf-8"))
        raw_colors = data.get("colors", {})

        def c(key, default):
            v = raw_colors.get(key, {})
            val = v.get("default", {}).get("color") or v.get("dark", {}).get("color")
            return val if val else default

        palette = {
            "primary": c("primary", "#89b4fa"),
            "on_primary": c("on_primary", "#11111b"),
            "primary_container": c("primary_container", "#74c7ec"),
            "surface": c("surface", "#181825"),
            "surface_container_lowest": c("surface_container_lowest", "#11111b"),
            "surface_container_low": c("surface_container_low", "#181825"),
            "surface_container": c("surface_container", "#252739"),
            "surface_container_high": c("surface_container_high", "#313244"),
            "surface_container_highest": c("surface_container_highest", "#45475a"),
            "on_surface": c("on_surface", "#cdd6f4"),
            "on_surface_variant": c("on_surface_variant", "#a6adc8"),
            "outline": c("outline", "#6c7086"),
            "outline_variant": c("outline_variant", "#45475a"),
            "error": c("error", "#f38ba8")
        }
        return palette
    except Exception as e:
        print(f"[matugen] Extraction failed ({e}). Using curated fallback.", file=sys.stderr)
        return fallback_palette()

def apply_theme(palette, home_dir):
    primary = palette["primary"]
    on_primary = palette["on_primary"]
    surface = palette["surface"]
    surface_low = palette["surface_container_low"]
    surface_lowest = palette["surface_container_lowest"]
    surface0 = palette["surface_container"]
    surface1 = palette["surface_container_high"]
    surface2 = palette["surface_container_highest"]
    on_surface = palette["on_surface"]
    on_surface_variant = palette["on_surface_variant"]
    outline = palette["outline"]
    outline_variant = palette["outline_variant"]
    error = palette["error"]

    # 1. Quickshell: qs_colors.json and qs_matugen_colors.json
    state_dir = os.path.join(home_dir, ".local", "state", "serpantinum")
    os.makedirs(state_dir, exist_ok=True)

    # Monochromatic rule: all accent roles resolve to primary or its tonal container
    qs_colors = {
        "base": surface_low,
        "mantle": surface_lowest,
        "crust": surface_lowest,
        "surface0": surface0,
        "surface1": surface1,
        "surface2": surface2,
        "overlay0": outline_variant,
        "overlay1": outline,
        "overlay2": outline,
        "text": on_surface,
        "subtext0": on_surface_variant,
        "subtext1": outline,
        "blue": primary,
        "sapphire": primary,
        "peach": primary,
        "green": primary,
        "red": error,
        "mauve": primary,
        "pink": primary,
        "yellow": primary,
        "maroon": primary,
        "teal": primary
    }

    qs_json_str = json.dumps(qs_colors, indent=2)
    with open(os.path.join(state_dir, "qs_colors.json"), "w") as f:
        f.write(qs_json_str + "\n")
    with open(os.path.join(state_dir, "qs_matugen_colors.json"), "w") as f:
        f.write(qs_json_str + "\n")

    # 2. Waybar: ~/.config/waybar/theme.css
    waybar_dir = os.path.join(home_dir, ".config", "waybar")
    os.makedirs(waybar_dir, exist_ok=True)
    waybar_theme_css = f"""/* Waybar Dynamic Monochromatic Matugen Palette */
@define-color bar_bg {hex_to_rgba_css(surface, 0.85)};
@define-color bar_fg {on_surface};
@define-color bar_fg_bright #ffffff;
@define-color bar_border_side transparent;
@define-color bar_border_bottom transparent;
@define-color accent {primary};
@define-color accent_gold {primary};
@define-color ws_active {on_primary};
@define-color ws_inactive {outline};
@define-color ws_hover_bg {hex_to_rgba_css(primary, 0.14)};
@define-color ws_active_bg {primary};
@define-color sep_color rgba(255, 255, 255, 0.12);
@define-color tooltip_bg {hex_to_rgba_css(surface, 0.95)};
@define-color tooltip_border {hex_to_rgba_css(primary, 0.30)};
"""
    with open(os.path.join(waybar_dir, "theme.css"), "w") as f:
        f.write(waybar_theme_css)

    # 3. Rofi: ~/.config/rofi/theme_colors.rasi
    rofi_dir = os.path.join(home_dir, ".config", "rofi")
    os.makedirs(rofi_dir, exist_ok=True)
    rofi_rasi = f"""/* Rofi Dynamic Monochromatic Matugen Palette */
* {{
    bg-base: {hex_to_rgba_css(surface, 0.96)};
    bg-input: {hex_to_rgba_css(surface_low, 0.85)};
    bg-selected: {hex_to_rgba_css(primary, 0.18)};
    border-subtle: {hex_to_rgba_css(primary, 0.18)};
    border-hairline: {hex_to_rgba_css(primary, 0.08)};
    accent-gold: {primary};
    accent-gold-bright: {primary};
    fg-main: {on_surface};
    fg-bright: #ffffff;
    fg-muted: {outline};
}}
"""
    with open(os.path.join(rofi_dir, "theme_colors.rasi"), "w") as f:
        f.write(rofi_rasi)

    # 4. Kitty: ~/.config/kitty/current-theme.conf
    kitty_dir = os.path.join(home_dir, ".config", "kitty")
    os.makedirs(kitty_dir, exist_ok=True)
    kitty_conf = f"""# Kitty Dynamic Monochromatic Matugen Palette
background            {surface}
foreground            {on_surface}
selection_background  {surface1}
selection_foreground  {on_surface}
url_color             {primary}
cursor                {primary}
cursor_text_color     {surface}

active_tab_background   {primary}
active_tab_foreground   {on_primary}
inactive_tab_background {surface0}
inactive_tab_foreground {outline}

active_border_color   {primary}
inactive_border_color {surface1}

# Black
color0 {surface0}
color8 {outline_variant}

# Red
color1 {error}
color9 {error}

# Green / Accent
color2  {primary}
color10 {primary}

# Yellow / Accent
color3  {palette.get("primary_container", primary)}
color11 {palette.get("primary_container", primary)}

# Blue / Primary Accent
color4  {primary}
color12 {primary}

# Magenta / Accent
color5  {outline}
color13 {outline}

# Cyan / Accent
color6  {palette.get("primary_container", primary)}
color14 {palette.get("primary_container", primary)}

# White
color7  {on_surface}
color15 #ffffff
"""
    with open(os.path.join(kitty_dir, "current-theme.conf"), "w") as f:
        f.write(kitty_conf)

    # 5. Hyprland Borders via hyprctl eval
    prim_hex = primary.lstrip("#")
    surf_hex = surface0.lstrip("#")
    try:
        subprocess.run([
            "hyprctl", "eval",
            f"hl.config({{ general = {{ col = {{ active_border = 'rgba({prim_hex}ff)', inactive_border = 'rgba({surf_hex}aa)' }} }} }})"
        ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

    # 6. Signal Kitty terminal to reload colors
    try:
        subprocess.run(["pkill", "-USR1", "-x", "kitty"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

    # 7. Notify Quickshell to reload colors
    try:
        qs_shell = os.path.join(home_dir, ".config", "quickshell", "shell.qml")
        subprocess.run(["quickshell", "-p", qs_shell, "ipc", "call", "theme", "reloadColors"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        try:
            subprocess.run(["quickshell", "ipc", "call", "theme", "reloadColors"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception:
            pass

def main():
    if len(sys.argv) < 2:
        print("Usage: generate_matugen_palette.py <wallpaper_path> [mode] [scheme_type]")
        sys.exit(1)

    wallpaper_path = os.path.abspath(sys.argv[1])
    if not os.path.isfile(wallpaper_path):
        print(f"Error: Wallpaper '{wallpaper_path}' not found.", file=sys.stderr)
        sys.exit(1)

    mode = sys.argv[2] if len(sys.argv) > 2 else "dark"
    scheme_type = sys.argv[3] if len(sys.argv) > 3 else "scheme-fidelity"
    home_dir = os.environ.get("HOME", os.path.expanduser("~"))

    print(f"Extracting palette from: {os.path.basename(wallpaper_path)} ({mode}, {scheme_type})...")
    palette = extract_matugen(wallpaper_path, mode, scheme_type)
    print(f"Primary accent extracted: {palette['primary']}")
    print(f"Surface background: {palette['surface']}")

    apply_theme(palette, home_dir)
    print("Monochromatic palette applied successfully across all targets!")

if __name__ == "__main__":
    main()
