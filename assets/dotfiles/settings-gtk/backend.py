import os
import re
import json
import subprocess
import shutil
import collections

import gi
gi.require_version("Gio", "2.0")
from gi.repository import Gio
from app_detector import AppDetector

_OLD_CONFIG_PATH = os.path.expanduser("~/.config/illogical-impulse/config.json")
CONFIG_PATH = os.path.expanduser("~/.config/rinauby/config.json")
if not os.path.exists(CONFIG_PATH) and os.path.exists(_OLD_CONFIG_PATH):
    CONFIG_PATH = _OLD_CONFIG_PATH

def _detect_assets_dir():
    if os.environ.get("RINAUBY_ASSETS_DIR"):
        return os.environ.get("RINAUBY_ASSETS_DIR")
    if os.path.isdir("/usr/share/backgrounds/rinauby"):
        return "/usr/share/backgrounds/rinauby"
    if os.path.isdir("/usr/share/rinauby/assets"):
        return "/usr/share/rinauby/assets"
    user_assets = os.path.expanduser("~/.local/share/rinauby/assets")
    if os.path.isdir(user_assets):
        return user_assets
    repo_assets = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    if os.path.isdir(repo_assets) and os.path.isdir(os.path.join(repo_assets, "wallpapers")):
        return repo_assets
    return "/usr/share/backgrounds/rinauby"

ASSETS_DIR = _detect_assets_dir()

GENERATE_HYPR_SCRIPT = os.path.expanduser("~/.config/hypr/scripts/generate_hypr_gui.sh")
SWITCHWALL_SCRIPT = os.path.expanduser("~/.config/quickshell/ii/scripts/colors/switchwall.sh")

def normalize_keybind_combo(combo: str) -> str:
    """Normalisasi string kombinasi tombol ke bentuk kanonikal (SUPER, CTRL, ALT, SHIFT + key)."""
    if not combo:
        return ""
    c_lower = combo.lower().strip()
    if "tap" in c_lower or ("super_l" in c_lower and "release" in c_lower):
        return "SUPER_TAP"
    parts = [p.strip() for p in combo.split("+")]
    mods = set()
    keys = []
    for p in parts:
        up = p.upper()
        if up in ("SUPER", "SUPER_L", "SUPER_R", "MOD4", "WIN"):
            mods.add("SUPER")
        elif up in ("CTRL", "CONTROL", "CONTROL_L", "CONTROL_R"):
            mods.add("CTRL")
        elif up in ("ALT", "ALT_L", "ALT_R", "MOD1"):
            mods.add("ALT")
        elif up in ("SHIFT", "SHIFT_L", "SHIFT_R"):
            mods.add("SHIFT")
        else:
            keys.append(p.lower())
    canonical_mods = [m for m in ["SUPER", "CTRL", "ALT", "SHIFT"] if m in mods]
    return " + ".join(canonical_mods + sorted(keys))

def normalize_keybind_command(cmd: str) -> str:
    """Normalisasi perintah eksekusi agar perbandingan perintah duplikat akurat."""
    if not cmd:
        return ""
    s = cmd.strip()
    m = re.match(r'^hl\.dsp\.(?:exec_cmd|exec|global)\s*\(\s*["\']?(.*?)["\']?\s*\)$', s, re.DOTALL)
    if m:
        s = m.group(1).strip()
    if s.startswith("exec,"):
        s = s[5:].strip()
    elif s.startswith("exec "):
        s = s[5:].strip()
    if (s.startswith('"') and s.endswith('"')) or (s.startswith("'") and s.endswith("'")):
        s = s[1:-1].strip()
    s = re.sub(r'\s+', ' ', s)
    return s.strip().lower()

class ConfigBackend:
    def __init__(self):
        self.config_data = {}
        self.last_mtime = 0
        self.load()
        # check_all_configs_health spawns `luac` once per config file, and the
        # health page calls it on every refresh. Remember the verdict per file,
        # keyed by mtime and size, so unchanged files are not re-validated.
        self._config_health_cache = {}
        self.sync_swappy_config()

    def _check_and_reload(self):
        if os.path.exists(CONFIG_PATH):
            try:
                mtime = os.path.getmtime(CONFIG_PATH)
                if mtime > self.last_mtime:
                    self.load()
            except Exception:
                pass

    def load(self):
        if os.path.exists(CONFIG_PATH):
            try:
                self.last_mtime = os.path.getmtime(CONFIG_PATH)
                with open(CONFIG_PATH, "r", encoding="utf-8") as f:
                    self.config_data = json.load(f)
            except Exception as e:
                print(f"Error reading config: {e}")
                self.config_data = {}
        else:
            self.config_data = {}

    def get(self, key_path, default=None):
        self._check_and_reload()
        parts = key_path.split(".")
        curr = self.config_data
        for p in parts:
            if isinstance(curr, dict) and p in curr:
                curr = curr[p]
            else:
                return default
        return curr

    def set(self, key_path, value, auto_apply=True):
        self._check_and_reload()
        parts = key_path.split(".")
        curr = self.config_data
        for p in parts[:-1]:
            if p not in curr or not isinstance(curr[p], dict):
                curr[p] = {}
            curr = curr[p]
        curr[parts[-1]] = value
        self.save()
        if auto_apply and key_path.startswith("hyprland."):
            self.apply_hyprland()
        elif key_path == "screenSnip.savePath":
            self.sync_swappy_config(value)

    def sync_swappy_config(self, save_path=None):
        if not save_path:
            save_path = self.get("screenSnip.savePath", "~/Screenshots")
        if not save_path:
            save_path = "~/Screenshots"
        save_path = os.path.expanduser(save_path)
        try:
            os.makedirs(save_path, exist_ok=True)
            swappy_dir = os.path.expanduser("~/.config/swappy")
            os.makedirs(swappy_dir, exist_ok=True)
            config_path = os.path.join(swappy_dir, "config")
            cfg_content = f"""[Default]
save_dir={save_path}
save_filename_format=screenshot-%Y-%m-%d_%H.%M.%S.png
show_panel=false
line_size=5
text_size=20
text_font=sans-serif
paint_mode=brush
early_exit=true
fill_shape=false
auto_save=false
"""
            with open(config_path, "w", encoding="utf-8") as f:
                f.write(cfg_content)
        except Exception as e:
            print(f"Error syncing swappy config: {e}")

    def save(self):
        try:
            os.makedirs(os.path.dirname(CONFIG_PATH), exist_ok=True)
            with open(CONFIG_PATH, "w", encoding="utf-8") as f:
                json.dump(self.config_data, f, indent=2, ensure_ascii=False)
                f.write("\n")
            self.last_mtime = os.path.getmtime(CONFIG_PATH)
        except Exception as e:
            print(f"Error saving config: {e}")

    def get_current_color_scheme(self):
        try:
            res = subprocess.check_output(
                ["gsettings", "get", "org.gnome.desktop.interface", "color-scheme"],
                text=True,
                stderr=subprocess.DEVNULL
            ).strip()
            if "dark" in res.lower():
                return "dark"
            return "light"
        except Exception:
            return "dark"

    def generate_standard_hypr_conf(self):
        """Menghasilkan konfigurasi standar hyprland.conf / rinauby_overrides.conf
        sehingga 100% kompatibel dengan Hyprland Ubuntu PPA tanpa ketergantungan Lua."""
        overrides_path = os.path.expanduser("~/.config/hypr/rinauby_overrides.conf")
        try:
            os.makedirs(os.path.dirname(overrides_path), exist_ok=True)
            layout = self.get("hyprland.layout", "dwindle")
            gaps_in = self.get("hyprland.gapsIn", 8)
            gaps_out = self.get("hyprland.gapsOut", 10)
            border_size = self.get("hyprland.borderSize", 2)
            rounding = self.get("hyprland.rounding", 12)
            active_op = self.get("hyprland.activeOpacity", 1.0)
            inactive_op = self.get("hyprland.inactiveOpacity", 0.95)
            dim_inactive = "true" if self.get("hyprland.dimInactive", False) else "false"
            dim_strength = self.get("hyprland.dimStrength", 0.05)

            blur_enabled = "true" if self.get("hyprland.blurEnabled", True) else "false"
            blur_size = self.get("hyprland.blurSize", 8)
            blur_passes = self.get("hyprland.blurPasses", 3)

            shadow_enabled = "true" if self.get("hyprland.shadowEnabled", True) else "false"
            shadow_range = self.get("hyprland.shadowRange", 16)

            anim_enabled = "true" if self.get("hyprland.animationsEnabled", True) else "false"

            sensitivity = self.get("hyprland.mouseSensitivity", 0.0)
            natural_scroll = "true" if self.get("hyprland.touchpadNaturalScroll", True) else "false"
            tap_to_click = "true" if self.get("hyprland.touchpadTapToClick", True) else "false"
            disable_typing = "true" if self.get("hyprland.touchpadDisableWhileTyping", False) else "false"

            resize_border = "true" if self.get("hyprland.resizeOnBorder", True) else "false"
            allow_tearing = "true" if self.get("hyprland.allowTearing", True) else "false"

            # Border Colors
            cur_mode = self.get_current_color_scheme()
            if cur_mode == "light":
                act_border = self.get("hyprland.activeBorderLight", "rgb(db9c5e) rgb(e5c07b) 45deg")
                inact_border = self.get("hyprland.inactiveBorderLight", "rgba(45535bcc)")
            else:
                act_border = self.get("hyprland.activeBorderDark", "rgb(db9c5e) rgb(e5c07b) 45deg")
                inact_border = self.get("hyprland.inactiveBorderDark", "rgba(45535bcc)")

            lines = [
                "# ==============================================================================",
                "# RINAUBY HYPRLAND OVERRIDES (Auto-generated by Rinauby Settings)",
                "# 100% Compatible with Ubuntu Hyprland PPA & Standard hyprland.conf",
                "# ==============================================================================",
                "",
                "general {",
                f"    layout = {layout}",
                f"    gaps_in = {gaps_in}",
                f"    gaps_out = {gaps_out}",
                f"    border_size = {border_size}",
                f"    col.active_border = {act_border}",
                f"    col.inactive_border = {inact_border}",
                f"    resize_on_border = {resize_border}",
                f"    allow_tearing = {allow_tearing}",
                "}",
                "",
                "decoration {",
                f"    rounding = {rounding}",
                f"    active_opacity = {active_op}",
                f"    inactive_opacity = {inactive_op}",
                f"    dim_inactive = {dim_inactive}",
                f"    dim_strength = {dim_strength}",
                "    shadow {",
                f"        enabled = {shadow_enabled}",
                f"        range = {shadow_range}",
                "        render_power = 3",
                "        color = rgba(1a1a1a88)",
                "    }",
                "    blur {",
                f"        enabled = {blur_enabled}",
                f"        size = {blur_size}",
                f"        passes = {blur_passes}",
                "    }",
                "}",
                "",
                "animations {",
                f"    enabled = {anim_enabled}",
                "}",
                "",
                "input {",
                f"    sensitivity = {sensitivity}",
                "    touchpad {",
                f"        natural_scroll = {natural_scroll}",
                f"        tap-to-click = {tap_to_click}",
                f"        disable_while_typing = {disable_typing}",
                "    }",
                "}",
                ""
            ]

            # Window Rules
            rules = self.get_window_rules()
            if rules:
                lines.append("# --- Aturan Jendela (Window Rules) ---")
                for r in rules:
                    cls = r.get("class", "").strip()
                    title = r.get("title", "").strip()
                    mode = r.get("mode", "tile")
                    if not cls and not title:
                        continue
                    match = f"class:^({cls})$" if cls else f"title:^({title})$"
                    if mode == "float":
                        lines.append(f"windowrulev2 = float, {match}")
                    if r.get("center"):
                        lines.append(f"windowrulev2 = center, {match}")
                    if r.get("custom_opacity"):
                        op_a = r.get("opacity_active", 0.95)
                        op_i = r.get("opacity_inactive", 0.90)
                        lines.append(f"windowrulev2 = opacity {op_a} {op_i}, {match}")
                    if r.get("pin"):
                        lines.append(f"windowrulev2 = pin, {match}")
                lines.append("")

            with open(overrides_path, "w", encoding="utf-8") as f:
                f.write("\n".join(lines) + "\n")
        except Exception as e:
            print(f"Error generating rinauby_overrides.conf: {e}")

    def ensure_hyprland_source(self):
        """Memastikan source rinauby_overrides.conf ada di hyprland.conf."""
        confs = [
            os.path.expanduser("~/.config/hypr/hyprland.conf"),
            "/home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/dotfiles/hypr/hyprland.conf"
        ]
        override_line = "source = ~/.config/hypr/rinauby_overrides.conf"
        for path in confs:
            if os.path.exists(path):
                try:
                    with open(path, "r", encoding="utf-8") as f:
                        content = f.read()
                    if override_line not in content and "rinauby_overrides.conf" not in content:
                        with open(path, "a", encoding="utf-8") as f:
                            f.write("\n# Rinauby Dynamic Settings Overrides\n" + override_line + "\n")
                except Exception as e:
                    print(f"Error ensuring source in {path}: {e}")

    def apply_hyprland(self):
        # 1. Terapkan konfigurasi standar Ubuntu Hyprland PPA
        self.generate_standard_hypr_conf()
        self.ensure_hyprland_source()

        # 2. Jika ada script generator host, jalankan juga secara paralel
        if os.path.exists(GENERATE_HYPR_SCRIPT):
            try:
                subprocess.Popen(["bash", GENERATE_HYPR_SCRIPT])
            except Exception:
                pass

        # 3. Reload hyprland secara instan
        subprocess.run(["hyprctl", "reload"], stderr=subprocess.DEVNULL)

    def update_gtk_settings_ini(self, updates: dict):
        ini_files = [
            os.path.expanduser("~/.config/gtk-3.0/settings.ini"),
            os.path.expanduser("~/.config/gtk-4.0/settings.ini"),
        ]
        for fpath in ini_files:
            if not os.path.exists(fpath):
                continue
            try:
                with open(fpath, "r", encoding="utf-8") as f:
                    lines = f.readlines()
                updated_keys = set()
                new_lines = []
                for line in lines:
                    match = re.match(r"^(\s*([^=]+?)\s*=\s*)(.*)$", line)
                    if match:
                        k = match.group(2).strip()
                        if k in updates:
                            new_lines.append(f"{k}={updates[k]}\n")
                            updated_keys.add(k)
                            continue
                    new_lines.append(line)
                for k, v in updates.items():
                    if k not in updated_keys:
                        new_lines.append(f"{k}={v}\n")
                with open(fpath, "w", encoding="utf-8") as f:
                    f.writelines(new_lines)
            except Exception as e:
                print(f"Error updating {fpath}: {e}")

    def apply_icon_theme(self, theme_name: str):
        if not theme_name:
            return
        try:
            subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", "icon-theme", theme_name], check=False)
            self.update_gtk_settings_ini({"gtk-icon-theme-name": theme_name})
        except Exception as e:
            print(f"Error applying icon theme: {e}")

    def apply_gtk_theme(self, mode=None):
        # mode: "light", "dark", or None (auto-detect)
        if not mode:
            mode = self.get_current_color_scheme()

        if mode == "dark":
            gtk_theme = self.get("appearance.darkGtkTheme", "")
            icon_theme = self.get("appearance.darkIconTheme", "")
        else:
            gtk_theme = self.get("appearance.lightGtkTheme", "")
            icon_theme = self.get("appearance.lightIconTheme", "")

        updates = {}
        if gtk_theme:
            updates["gtk-theme-name"] = gtk_theme
            try:
                subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", "gtk-theme", gtk_theme], check=False)
            except Exception:
                pass
        if icon_theme:
            updates["gtk-icon-theme-name"] = icon_theme
            try:
                subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", "icon-theme", icon_theme], check=False)
            except Exception:
                pass

        updates["gtk-application-prefer-dark-theme"] = "1" if mode == "dark" else "0"
        self.update_gtk_settings_ini(updates)

        cmd = ["bash", SWITCHWALL_SCRIPT, "--mode", mode, "--noswitch"]
        if os.path.exists(SWITCHWALL_SCRIPT):
            subprocess.Popen(cmd)

    def apply_wallpaper(self, image_path, mode=None):
        if not mode:
            mode = self.get_current_color_scheme()
        if os.path.exists(SWITCHWALL_SCRIPT) and os.path.exists(image_path):
            cmd = ["bash", SWITCHWALL_SCRIPT, "--mode", mode, "--image", image_path]
            subprocess.Popen(cmd)

    def apply_accent_color(self, hex_color: str):
        self.set("appearance.palette.accentColor", hex_color)
        self.set("appearance.palette.useWallpaper", False)
        mode = self.get_current_color_scheme()
        cmd = ["bash", SWITCHWALL_SCRIPT, "--color", hex_color, "--mode", mode, "--noswitch"]
        if os.path.exists(SWITCHWALL_SCRIPT):
            subprocess.Popen(cmd)

    def set_use_wallpaper_accent(self, use_wallpaper: bool):
        self.set("appearance.palette.useWallpaper", use_wallpaper)
        mode = self.get_current_color_scheme()
        if use_wallpaper:
            cmd = ["bash", SWITCHWALL_SCRIPT, "--color", "clear", "--mode", mode, "--noswitch"]
            if os.path.exists(SWITCHWALL_SCRIPT):
                subprocess.Popen(cmd)
        else:
            cur_color = self.get("appearance.palette.accentColor", "")
            if not cur_color:
                cur_color = "#3584e4"
                self.set("appearance.palette.accentColor", cur_color)
            self.apply_accent_color(cur_color)

    def apply_sync_all(self):
        self.apply_hyprland()
        self.apply_gtk_theme()

    def get_installed_gtk_themes(self):
        themes = set()
        search_dirs = [
            "/usr/share/themes",
            os.path.expanduser("~/.themes"),
            os.path.expanduser("~/.local/share/themes")
        ]
        for d in search_dirs:
            if os.path.isdir(d):
                for item in os.listdir(d):
                    sub = os.path.join(d, item)
                    if os.path.isdir(sub):
                        themes.add(item)
        return sorted(list(themes))

    def get_installed_icon_themes(self):
        icon_themes = set()
        search_dirs = [
            "/usr/share/icons",
            os.path.expanduser("~/.icons"),
            os.path.expanduser("~/.local/share/icons")
        ]
        import configparser
        for d in search_dirs:
            if not os.path.isdir(d):
                continue
            for item in os.listdir(d):
                sub = os.path.join(d, item)
                theme_index = os.path.join(sub, "index.theme")
                if os.path.isdir(sub) and os.path.exists(theme_index):
                    try:
                        cp = configparser.ConfigParser(interpolation=None)
                        cp.read(theme_index, encoding="utf-8")
                        if cp.has_section("Icon Theme"):
                            dirs_val = cp.get("Icon Theme", "Directories", fallback="")
                            if dirs_val or any(os.path.isdir(os.path.join(sub, s)) for s in ["scalable", "16x16", "24x24", "32x32", "48x48", "symbolic"]):
                                if item not in ["default", "hicolor"]:
                                    icon_themes.add(item)
                    except Exception:
                        pass
        res = sorted(list(icon_themes))
        return res if res else ["Adwaita", "WhiteSur-light", "WhiteSur-dark", "Yaru-magenta", "Yaru-magenta-dark"]

    RULES_JSON_PATH = os.path.expanduser("~/.config/hypr/custom/rules.json")

    def _save_rules_json_backup(self, rules_list):
        try:
            os.makedirs(os.path.dirname(self.RULES_JSON_PATH), exist_ok=True)
            tmp = self.RULES_JSON_PATH + ".tmp"
            with open(tmp, "w", encoding="utf-8") as f:
                json.dump(rules_list, f, indent=2, ensure_ascii=False)
                f.write("\n")
            os.replace(tmp, self.RULES_JSON_PATH)
        except Exception as e:
            print(f"Error saving rules.json backup: {e}")

    def parse_rules_from_lua(self):
        rules_lua_path = os.path.expanduser("~/.config/hypr/custom/rules.lua")
        if not os.path.exists(rules_lua_path):
            return []
        try:
            with open(rules_lua_path, "r", encoding="utf-8") as f:
                lines = f.readlines()
            rules = []
            current_name = "Aturan"
            for line in lines:
                sline = line.strip()
                if sline.startswith("--") and "File ini" not in sline and "JANGAN" not in sline and "Perilaku" not in sline:
                    current_name = sline.lstrip("-").strip()
                    continue
                if sline.startswith("hl.window_rule"):
                    rule = {"id": f"rule_{len(rules)+1}", "name": current_name}
                    m_cls = re.search(r'class\s*=\s*"(.*?)"', sline)
                    if m_cls:
                        rule["class"] = m_cls.group(1)
                    m_title = re.search(r'title\s*=\s*"(.*?)"', sline)
                    if m_title:
                        rule["title"] = m_title.group(1)
                    rule["mode"] = "float" if "float = true" in sline else "tile"
                    m_size = re.search(r'size\s*=\s*\{\s*"\(monitor_w\*([0-9.]+)\)"\s*,\s*"\(monitor_h\*([0-9.]+)\)"\s*\}', sline)
                    if m_size:
                        rule["size_w"] = float(m_size.group(1))
                        rule["size_h"] = float(m_size.group(2))
                    else:
                        rule["size_w"] = 0.55
                        rule["size_h"] = 0.70
                    rule["center"] = ("center = true" in sline)
                    rule["keep_aspect_ratio"] = ("keep_aspect_ratio = true" in sline)
                    rule["blur"] = ("no_blur = false" in sline)
                    m_op = re.search(r'opacity\s*=\s*"([0-9.]+)\s+([0-9.]+)"', sline)
                    if m_op:
                        rule["custom_opacity"] = True
                        rule["opacity_mode"] = "custom"
                        rule["opacity_active"] = float(m_op.group(1))
                        rule["opacity_inactive"] = float(m_op.group(2))
                    elif "opaque = true" in sline:
                        rule["custom_opacity"] = True
                        rule["opacity_mode"] = "opaque"
                    else:
                        rule["custom_opacity"] = False
                    rule["pin"] = ("pin = true" in sline)
                    rule["dim_around"] = ("dim_around = true" in sline)
                    rule["no_shadow"] = ("no_shadow = true" in sline)
                    m_round = re.search(r'rounding\s*=\s*(\d+)', sline)
                    if m_round:
                        rule["custom_rounding"] = True
                        rule["rounding"] = int(m_round.group(1))
                    m_border = re.search(r'border_size\s*=\s*(\d+)', sline)
                    if m_border:
                        rule["custom_border"] = True
                        rule["border_size"] = int(m_border.group(1))

                    app = AppDetector.find_app_by_class(rule.get("class", ""))
                    if app:
                        rule["icon"] = app.get("icon", "")
                        rule["category"] = app.get("workflow_category", "custom")
                        rule["is_custom"] = False
                    else:
                        rule["icon"] = "application-x-executable"
                        rule["category"] = "custom"
                        rule["is_custom"] = True

                    rules.append(rule)
            return rules
        except Exception as e:
            print(f"Error parsing rules.lua: {e}")
            return []

    def get_window_rules(self):
        self._check_and_reload()
        rules = self.get("hyprland.windowRules")
        if isinstance(rules, list) and len(rules) > 0:
            self._save_rules_json_backup(rules)
            return rules

        if os.path.exists(self.RULES_JSON_PATH):
            try:
                with open(self.RULES_JSON_PATH, "r", encoding="utf-8") as f:
                    cached_rules = json.load(f)
                if isinstance(cached_rules, list) and len(cached_rules) > 0:
                    self.set("hyprland.windowRules", cached_rules, auto_apply=False)
                    return cached_rules
            except Exception as e:
                print(f"Error reading rules.json backup: {e}")

        recovered = self.parse_rules_from_lua()
        if recovered:
            self._save_rules_json_backup(recovered)
            self.set("hyprland.windowRules", recovered, auto_apply=False)
            return recovered

        return []

    def save_window_rules(self, rules_list):
        self._check_and_reload()
        self._save_rules_json_backup(rules_list)
        self.set("hyprland.windowRules", rules_list, auto_apply=False)
        self.generate_rules_lua()

    def validate_lua_syntax(self, lua_code: str) -> tuple[bool, str]:
        """Validasi sintaksis kode Lua menggunakan /usr/bin/luac -p - (jika tersedia)."""
        if not shutil.which("luac"):
            return True, ""
        try:
            res = subprocess.run(
                ["luac", "-p", "-"],
                input=lua_code,
                text=True,
                capture_output=True,
                timeout=2.0
            )
            if res.returncode == 0:
                return True, ""
            return False, res.stderr.strip()
        except Exception as e:
            return True, f"Warning: luac check skipped ({e})"

    def _atomic_write_lua(self, target_path: str, content: str) -> tuple[bool, str]:
        """Validasi sintaks Lua terlebih dahulu di memori, lalu tulis secara atomik."""
        is_valid, err = self.validate_lua_syntax(content)
        if not is_valid:
            print(f"ATOMIC GUARD REJECTED: Sintaks Lua tidak valid untuk {target_path}:\n{err}")
            return False, err

        try:
            os.makedirs(os.path.dirname(target_path), exist_ok=True)
            tmp_path = target_path + ".tmp"
            with open(tmp_path, "w", encoding="utf-8") as f:
                f.write(content)
                if not content.endswith("\n"):
                    f.write("\n")
                f.flush()
                os.fsync(f.fileno())
            os.replace(tmp_path, target_path)
            return True, ""
        except Exception as e:
            print(f"Gagal menulis berkas konfigurasi {target_path}: {e}")
            return False, str(e)

    def generate_rules_lua(self):
        rules_lua_path = os.path.expanduser("~/.config/hypr/custom/rules.lua")
        rules = self.get_window_rules()

        new_ws_behavior = self.get("hyprland.tiling.newWorkspaceBehavior", "tiled")

        lines = [
            "-- File ini dihasilkan otomatis oleh Pengaturan Desktop (Window Management)",
            "-- JANGAN mengedit berkas ini secara manual karena akan tertimpa saat disimpan di GUI.",
            ""
        ]

        if new_ws_behavior == "floating":
            lines.extend([
                "-- Perilaku Bawaan Ruang Kerja Baru: Melayang Bebas",
                'hl.window_rule({ match = { class = ".*" }, float = true })',
                ""
            ])

        for r in rules:
            name = r.get("name", "Aturan")
            cls = r.get("class", "").strip()
            title = r.get("title", "").strip()
            raw_mode = str(r.get("mode", "tile")).lower()
            mode = "float" if raw_mode in ("float", "floating") else "tile"
            size_w = max(0.10, min(1.00, float(r.get("size_w", r.get("width_scale", 0.60)))))
            size_h = max(0.10, min(1.00, float(r.get("size_h", r.get("height_scale", 0.60)))))
            center = bool(r.get("center", True))

            if not cls and not title:
                continue

            match_parts = []
            if cls:
                cls_lua = cls.replace('\\', '\\\\').replace('"', '\\"')
                match_parts.append(f'class = "{cls_lua}"')
            if title:
                title_lua = title.replace('\\', '\\\\').replace('"', '\\"')
                match_parts.append(f'title = "{title_lua}"')
            match_str = ", ".join(match_parts)

            lines.append(f"-- {name}")
            props = [f"match = {{ {match_str} }}"]

            if mode == "float":
                props.append("float = true")
                if center:
                    props.append("center = true")
                props.append(f'size = {{ "(monitor_w*{size_w:.2f})", "(monitor_h*{size_h:.2f})" }}')
                if r.get("keep_aspect_ratio"):
                    props.append("keep_aspect_ratio = true")
            else:
                props.append("tile = true")

            # Transparansi & Opacity
            if r.get("custom_opacity"):
                op_mode = r.get("opacity_mode", "custom")
                if op_mode == "opaque":
                    props.append("opaque = true")
                else:
                    op_act = max(0.0, min(1.00, float(r.get("opacity_active", 0.88))))
                    op_inact = max(0.0, min(1.00, float(r.get("opacity_inactive", 0.85))))
                    props.append(f'opacity = "{op_act:.2f} {op_inact:.2f}"')

            # Efek Kaca Buram (Blur)
            if r.get("blur"):
                props.append("no_blur = false")

            # Sematkan di semua ruang kerja (Pin)
            if r.get("pin"):
                props.append("pin = true")

            # Redupkan sekeliling (Dim around)
            if r.get("dim_around"):
                props.append("dim_around = true")

            # Tanpa bayangan (No shadow)
            if r.get("no_shadow"):
                props.append("no_shadow = true")

            # Sudut lengkung kustom (Rounding) - Hyprland window_rule mewajibkan 0 <= rounding <= 20
            if r.get("custom_rounding"):
                r_val = max(0, min(20, int(r.get("rounding", 10))))
                props.append(f"rounding = {r_val}")

            # Border size kustom
            if r.get("custom_border"):
                b_val = max(0, min(20, int(r.get("border_size", 2))))
                props.append(f"border_size = {b_val}")

            lines.append(f"hl.window_rule({{ {', '.join(props)} }})")
            lines.append("")

        self._atomic_write_lua(rules_lua_path, "\n".join(lines))
        self.apply_hyprland()

    def rescan_system(self):
        self.load()
        AppDetector.get_all_apps(force_reload=True)
        self.get_default_apps_data(force_reload=True)

    # === Default Apps Management ===
    def get_default_apps_data(self, force_reload=False):
        self._check_and_reload()
        all_apps = AppDetector.get_all_apps(force_reload=force_reload)
        all_apps_by_norm_id = {}
        for a in all_apps:
            nid = a["id"][:-8] if a["id"].endswith(".desktop") else a["id"]
            all_apps_by_norm_id[nid] = a

        KNOWN_TERMS = [
            ("kitty", "Kitty Terminal", "kitty", "kitty"),
            ("foot", "Foot Terminal", "foot", "foot"),
            ("alacritty", "Alacritty", "Alacritty", "alacritty"),
            ("ghostty", "Ghostty", "ghostty", "ghostty"),
            ("wezterm", "WezTerm", "org.wezfurlong.wezterm", "wezterm"),
            ("gnome-terminal", "GNOME Terminal", "org.gnome.Terminal", "gnome-terminal"),
            ("konsole", "Konsole", "org.kde.konsole", "konsole"),
            ("xfce4-terminal", "XFCE Terminal", "xfce4-terminal", "xfce4-terminal"),
            ("kgx", "Console (King's Cross)", "org.gnome.Console", "kgx"),
            ("ptyxis", "Ptyxis", "org.gnome.Ptyxis", "ptyxis"),
            ("xterm", "XTerm", "xterm", "xterm"),
            ("terminator", "Terminator", "terminator", "terminator"),
            ("tilix", "Tilix", "com.gexperts.Tilix", "tilix"),
        ]

        result = []

        for cat in DEFAULT_APP_CATEGORIES:
            cat_id = cat["id"]
            cat_type = cat["type"]
            candidates = {}
            current_def = None

            if cat_type == "terminal":
                for a in all_apps:
                    if "TerminalEmulator" in a.get("categories", []):
                        if a["id"] not in ("kitty-open", "kitty-open.desktop"):
                            nid = a["id"][:-8] if a["id"].endswith(".desktop") else a["id"]
                            exe = a["exec"].split()[0] if a["exec"] else nid
                            candidates[nid] = {
                                "id": f"{nid}.desktop",
                                "name": a["name"],
                                "icon": a["icon"],
                                "exec": exe
                            }
                for cmd, name, icon, exe in KNOWN_TERMS:
                    if shutil.which(cmd):
                        if cmd not in candidates:
                            candidates[cmd] = {
                                "id": f"{cmd}.desktop",
                                "name": name,
                                "icon": icon,
                                "exec": exe
                            }

                cfg_term = self.get("apps.terminal", "kitty -1")
                cfg_term_bin = cfg_term.split()[0] if cfg_term else "kitty"
                for cid, cinfo in candidates.items():
                    if cinfo["exec"] == cfg_term_bin or cid == cfg_term_bin:
                        current_def = cinfo["id"]
                        break
                if not current_def and candidates:
                    current_def = list(candidates.values())[0]["id"]

            else:
                mimes = cat.get("mimes", [])
                primary_mimes = cat.get("primary_mimes", mimes)
                cat_filter = cat.get("category_filter", [])
                bad_norm = {b[:-8] if b.endswith(".desktop") else b for b in cat.get("bad_apps", set())}

                # 1. Query GIO mime associations using primary_mimes
                for m in primary_mimes:
                    for app in Gio.AppInfo.get_all_for_type(m):
                        aid = app.get_id()
                        if not aid:
                            continue
                        nid = aid[:-8] if aid.endswith(".desktop") else aid
                        if nid in bad_norm:
                            continue
                        cmd_line = app.get_commandline() or ""
                        if cat_id == "web_browser" and ("--app=" in cmd_line or "--profile-directory=" in cmd_line):
                            continue
                        desktop_id = aid if aid.endswith(".desktop") else f"{aid}.desktop"
                        icon_str = app.get_icon().to_string() if app.get_icon() else "application-x-executable"
                        candidates[nid] = {
                            "id": desktop_id,
                            "name": app.get_name(),
                            "icon": icon_str,
                            "exec": app.get_executable() or nid
                        }

                # 2. Query AppDetector categories
                if cat_id == "code_editor":
                    for nid, a in all_apps_by_norm_id.items():
                        if nid in bad_norm or nid in candidates:
                            continue
                        cats = set(a.get("categories", []))
                        if "IDE" in cats or ("Development" in cats and "TextEditor" in cats):
                            desktop_id = a["id"] if a["id"].endswith(".desktop") else f"{a['id']}.desktop"
                            candidates[nid] = {
                                "id": desktop_id,
                                "name": a["name"],
                                "icon": a["icon"],
                                "exec": a["exec"].split()[0] if a["exec"] else nid
                            }
                elif cat_filter:
                    for nid, a in all_apps_by_norm_id.items():
                        if nid in bad_norm or nid in candidates:
                            continue
                        cmd_line = a.get("exec", "")
                        if cat_id == "web_browser" and ("--app=" in cmd_line or "--profile-directory=" in cmd_line):
                            continue
                        app_cats = set(a.get("categories", []))
                        if any(c in app_cats for c in cat_filter):
                            desktop_id = a["id"] if a["id"].endswith(".desktop") else f"{a['id']}.desktop"
                            candidates[nid] = {
                                "id": desktop_id,
                                "name": a["name"],
                                "icon": a["icon"],
                                "exec": cmd_line.split()[0] if cmd_line else nid
                            }

                # 3. Determine current default
                if mimes:
                    def_app = Gio.AppInfo.get_default_for_type(mimes[0], False)
                    if def_app and def_app.get_id():
                        cur_id = def_app.get_id()
                        cur_desktop = cur_id if cur_id.endswith(".desktop") else f"{cur_id}.desktop"
                        if any(c["id"] == cur_desktop for c in candidates.values()):
                            current_def = cur_desktop

                # Check specific quickshell config keys if applicable
                cfg_match_key = {
                    "web_browser": "apps.browser",
                    "file_manager": "apps.fileManager",
                    "code_editor": "apps.codeEditor"
                }.get(cat_id)

                if cfg_match_key:
                    cfg_bin = self.get(cfg_match_key, None)
                    if cfg_bin:
                        cfg_base = cfg_bin.split()[0]
                        for cid, cinfo in candidates.items():
                            if os.path.basename(cinfo["exec"]) == cfg_base or cid == cfg_base:
                                current_def = cinfo["id"]
                                break

                saved_override = self.get(f"apps.defaults.{cat_id}", None)
                if saved_override and any(c["id"] == saved_override for c in candidates.values()):
                    current_def = saved_override

                if not current_def and candidates:
                    current_def = list(candidates.values())[0]["id"]

            sorted_apps = sorted(candidates.values(), key=lambda x: x["name"].lower())
            result.append({
                "definition": cat,
                "current_default_id": current_def,
                "apps": sorted_apps
            })

        return result

    def set_default_app(self, cat_id, app_id, app_info=None):
        self._check_and_reload()
        cat_def = None
        for c in DEFAULT_APP_CATEGORIES:
            if c["id"] == cat_id:
                cat_def = c
                break
        if not cat_def:
            return False

        self.set(f"apps.defaults.{cat_id}", app_id)

        exec_bin = app_info.get("exec", "") if app_info else ""
        if not exec_bin:
            nid = app_id[:-8] if app_id.endswith(".desktop") else app_id
            exec_bin = nid
        exec_base = os.path.basename(exec_bin)

        if cat_def["type"] == "terminal":
            self.set("apps.terminal", exec_base)
            self.generate_variables_lua()
            self.generate_keybinds_apps_lua()
            self._update_env_terminal(exec_base)
            self.apply_hyprland()
            return True

        mimes = cat_def.get("mimes", [])
        for m in mimes:
            try:
                app_obj = Gio.DesktopAppInfo.new(app_id)
                if app_obj:
                    app_obj.set_as_default_for_type(m)
            except Exception:
                pass
            try:
                subprocess.Popen(["xdg-mime", "default", app_id, m], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except Exception:
                pass

        if cat_id == "web_browser":
            try:
                subprocess.Popen(["xdg-settings", "set", "default-web-browser", app_id], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except Exception:
                pass
            self.set("apps.browser", exec_base)
            self.generate_variables_lua()
            self.generate_keybinds_apps_lua()
            self.apply_hyprland()
        elif cat_id == "file_manager":
            self.set("apps.fileManager", exec_base)
            self.generate_variables_lua()
            self.generate_keybinds_apps_lua()
            self.apply_hyprland()
        elif cat_id == "code_editor":
            self.set("apps.codeEditor", exec_base)
            self.generate_variables_lua()
            self.generate_keybinds_apps_lua()
            self.apply_hyprland()
        elif cat_id == "text_editor":
            self.generate_variables_lua()
            self.apply_hyprland()

        return True

    def _update_env_terminal(self, terminal_bin):
        self.generate_env_lua()


    def generate_variables_lua(self):
        vars_lua_path = os.path.expanduser("~/.config/hypr/custom/variables.lua")
        term = self.get("apps.terminal", "kitty")
        fm = self.get("apps.fileManager", "nautilus")
        browser = self.get("apps.browser", "firefox")
        editor = self.get("apps.codeEditor", "zeditor")
        text_editor = self.get("apps.defaults.text_editor", "gnome-text-editor")

        lines = [
            "-- File ini dihasilkan otomatis oleh Pengaturan Desktop (Variabel Aplikasi)",
            "-- JANGAN mengedit berkas ini secara manual karena akan tertimpa saat disimpan di GUI.",
            "",
            f'terminal = "{term}"',
            f'fileManager = "{fm}"',
            f'browser = "{browser}"',
            f'codeEditor = "{editor}"',
            f'textEditor = "{text_editor}"',
            ""
        ]

        self._atomic_write_lua(vars_lua_path, "\n".join(lines))

    def generate_keybinds_lua(self):
        # Keybinds dipusatkan di hyprland/keybinds.lua
        return

    generate_keybinds_apps_lua = generate_keybinds_lua

    def parse_keybinds_from_lua(self):
        """Parsing berkas custom/keybinds.lua untuk merekonstruksi overrides dan custom keybinds."""
        keybinds_lua_path = os.path.expanduser("~/.config/hypr/custom/keybinds.lua")
        if not os.path.exists(keybinds_lua_path):
            return {"added": [], "overrides": {}, "disabled": []}
        try:
            with open(keybinds_lua_path, "r", encoding="utf-8") as f:
                content = f.read()

            overrides = {}
            added = []
            disabled = []

            def _parse_bind_line(line_str):
                s = line_str.strip()
                if not s.startswith("hl.bind("):
                    return None
                if not s.endswith(")"):
                    return None
                inner = s[8:-1].strip()

                desc = ""
                table_m = re.search(r',\s*\{\s*description\s*=\s*["\'](.*?)["\']\s*\}\s*$', inner)
                if table_m:
                    desc = table_m.group(1)
                    inner = inner[:table_m.start()].strip()

                m_combo = re.match(r'^["\']([^"\']+)["\']\s*,\s*(.*)$', inner)
                if m_combo:
                    combo = m_combo.group(1).strip()
                    action = m_combo.group(2).strip()
                    return combo, action, desc
                return None

            # 3. Pintasan Bawaan yang Diubah (Overrides)
            sec3_match = re.search(r'-- 3\. Pintasan Bawaan yang Diubah \(Overrides\)(.*?)(?:-- 4\.|$)', content, re.DOTALL)
            if sec3_match:
                sec3_text = sec3_match.group(1)
                for line in sec3_text.splitlines():
                    parsed = _parse_bind_line(line)
                    if parsed:
                        combo, action, desc = parsed
                        overrides[combo] = {
                            "action": action,
                            "command": action,
                            "description": desc,
                            "enabled": True,
                            "new_combo": combo
                        }

            # 4. Pintasan Kustom Tambahan Pengguna
            sec4_match = re.search(r'-- 4\. Pintasan Kustom Tambahan Pengguna(.*?)$', content, re.DOTALL)
            if sec4_match:
                sec4_text = sec4_match.group(1)
                for line in sec4_text.splitlines():
                    parsed = _parse_bind_line(line)
                    if parsed:
                        combo, action, desc = parsed
                        m_cmd = re.match(r'^hl\.dsp\.exec_cmd\(\s*["\'](.*?)["\']\s*\)$', action)
                        cmd = m_cmd.group(1) if m_cmd else action
                        added.append({
                            "combo": combo,
                            "command": cmd,
                            "name": desc or "Pintasan Kustom"
                        })

            return {
                "added": added,
                "overrides": overrides,
                "disabled": disabled
            }
        except Exception as e:
            print(f"Error parsing keybinds from lua: {e}")
            return {"added": [], "overrides": {}, "disabled": []}

    def get_custom_keybinds(self):
        self._check_and_reload()
        kb = self.get("hyprland.custom_keybinds")
        keybinds_json_path = os.path.expanduser("~/.config/hypr/custom/keybinds.json")

        if not kb or (not kb.get("added") and not kb.get("overrides") and not kb.get("disabled")):
            if os.path.exists(keybinds_json_path):
                try:
                    with open(keybinds_json_path, "r", encoding="utf-8") as f:
                        cached_kb = json.load(f)
                    if cached_kb and (cached_kb.get("added") or cached_kb.get("overrides") or cached_kb.get("disabled")):
                        self.set("hyprland.custom_keybinds", cached_kb, auto_apply=False)
                        return cached_kb
                except Exception as e:
                    print(f"Error reading keybinds.json: {e}")

            # Recovery from custom/keybinds.lua jika config.json dan keybinds.json kosong
            recovered = self.parse_keybinds_from_lua()
            if recovered and (recovered.get("added") or recovered.get("overrides") or recovered.get("disabled")):
                self.save_custom_keybinds(recovered)
                return recovered

        if not kb:
            kb = {"added": [], "overrides": {}, "disabled": []}
        return kb

    def save_custom_keybinds(self, custom_data):
        self.set("hyprland.custom_keybinds", custom_data, auto_apply=False)
        try:
            keybinds_json_path = os.path.expanduser("~/.config/hypr/custom/keybinds.json")
            with open(keybinds_json_path, "w", encoding="utf-8") as f:
                json.dump(custom_data, f, indent=2)
        except Exception as e:
            print(f"Error saving keybinds.json: {e}")
        self.generate_keybinds_lua()

    def enter_key_recording(self):
        """Beralih sementara ke submap pass-through agar Hyprland tidak mencegat penekanan tombol saat perekaman GUI."""
        try:
            subprocess.run(["hyprctl", "dispatch", 'hl.dsp.submap("virtual-machine")'],
                           capture_output=True, timeout=0.5)
        except Exception as e:
            print(f"enter_key_recording failed: {e}")

    def exit_key_recording(self):
        """Kembalikan submap Hyprland ke keadaan normal setelah perekaman selesai."""
        try:
            subprocess.run(["hyprctl", "dispatch", 'hl.dsp.submap("reset")'],
                           capture_output=True, timeout=0.5)
        except Exception as e:
            print(f"exit_key_recording failed: {e}")

    def run_compositor_audit(self) -> tuple[bool, str]:
        """Jalankan audit kompositor Hyprland menggunakan Hyprland --verify-config."""
        try:
            res = subprocess.run(
                ["Hyprland", "--verify-config"],
                text=True,
                capture_output=True,
                timeout=5.0
            )
            output = (res.stdout or "") + "\n" + (res.stderr or "")
            clean_lines = [line for line in output.splitlines() if not line.strip().startswith("DEBUG")]
            return res.returncode == 0, "\n".join(clean_lines).strip()
        except Exception as e:
            return False, f"Gagal menjalankan audit Hyprland: {e}"

    def check_all_configs_health(self) -> list[dict]:
        """Periksa kesehatan sintaksis seluruh berkas konfigurasi .lua menggunakan luac -p."""
        base_dir = os.path.expanduser("~/.config/hypr")
        files_to_check = []

        # 1. Custom configs
        custom_dir = os.path.join(base_dir, "custom")
        if os.path.exists(custom_dir):
            for f in sorted(os.listdir(custom_dir)):
                if f.endswith(".lua"):
                    files_to_check.append((os.path.join(custom_dir, f), True))

        # 2. Hyprland base configs
        hl_dir = os.path.join(base_dir, "hyprland")
        if os.path.exists(hl_dir):
            for f in sorted(os.listdir(hl_dir)):
                if f.endswith(".lua"):
                    files_to_check.append((os.path.join(hl_dir, f), False))

        # 3. Root hyprland.lua
        root_hl = os.path.join(base_dir, "hyprland.lua")
        if os.path.exists(root_hl):
            files_to_check.insert(0, (root_hl, False))

        results = []
        seen_paths = set()
        for path, is_custom in files_to_check:
            rel = os.path.relpath(path, base_dir)
            seen_paths.add(path)

            try:
                stat = os.stat(path)
                signature = (stat.st_mtime_ns, stat.st_size)
            except OSError:
                signature = None

            cached = self._config_health_cache.get(path)
            if signature is not None and cached is not None and cached[0] == signature:
                valid, err = cached[1], cached[2]
            else:
                if not shutil.which("luac"):
                    valid = True
                    err = None
                else:
                    try:
                        res = subprocess.run(
                            ["luac", "-p", path],
                            capture_output=True,
                            text=True,
                            timeout=2.0
                        )
                        valid = (res.returncode == 0)
                        err = res.stderr.strip() if not valid else None
                    except Exception as e:
                        valid = True
                        err = str(e)
                if signature is not None:
                    self._config_health_cache[path] = (signature, valid, err)

            results.append({
                "name": os.path.basename(path),
                "rel_path": rel,
                "full_path": path,
                "is_custom": is_custom,
                "valid": valid,
                "error": err
            })

        # Forget entries for files that disappeared, so the cache cannot grow
        # without bound as configs are added and removed.
        for stale_path in [p for p in self._config_health_cache if p not in seen_paths]:
            del self._config_health_cache[stale_path]

        return results

    def get_hyprland_runtime_status(self) -> dict:
        """Kumpulkan status runtime compositor Hyprland."""
        info = {
            "connected": False,
            "version": "Tidak diketahui",
            "monitors_count": 0,
            "workspaces_count": 0,
            "clients_count": 0,
            "active_workspace": "",
        }
        if not shutil.which("hyprctl"):
            return info

        try:
            ver_out = subprocess.check_output(["hyprctl", "version"], text=True, timeout=1.0).splitlines()
            if ver_out:
                info["version"] = ver_out[0].strip()
            info["connected"] = True

            mons = subprocess.check_output(["hyprctl", "monitors", "-j"], text=True, timeout=1.0)
            mons_data = json.loads(mons)
            info["monitors_count"] = len(mons_data)

            ws = subprocess.check_output(["hyprctl", "workspaces", "-j"], text=True, timeout=1.0)
            ws_data = json.loads(ws)
            info["workspaces_count"] = len(ws_data)

            clients = subprocess.check_output(["hyprctl", "clients", "-j"], text=True, timeout=1.0)
            clients_data = json.loads(clients)
            info["clients_count"] = len(clients_data)

            act_ws = subprocess.check_output(["hyprctl", "activeworkspace", "-j"], text=True, timeout=1.0)
            act_data = json.loads(act_ws)
            info["active_workspace"] = str(act_data.get("id", ""))
        except Exception:
            pass

        return info

    def get_all_keybinds(self):
        custom_data = self.get_custom_keybinds()
        disabled_set = set(custom_data.get("disabled", []))
        overrides = custom_data.get("overrides", {})
        added = custom_data.get("added", [])

        keybinds_path = os.path.expanduser("~/.config/hypr/hyprland/keybinds.lua")
        results = []
        if os.path.exists(keybinds_path):
            try:
                with open(keybinds_path, "r", encoding="utf-8") as f:
                    raw_text = f.read()

                # Lewati baris komentar Lua (-- ...)
                clean_lines = []
                for line in raw_text.splitlines():
                    stripped = line.strip()
                    if stripped.startswith("--"):
                        continue
                    clean_lines.append(line)
                text = "\n".join(clean_lines)

                pos = 0
                binds = []
                while True:
                    idx = text.find("hl.bind(", pos)
                    if idx == -1:
                        break
                    start = idx + len("hl.bind(")
                    depth = 1
                    i = start
                    in_str = None
                    while i < len(text) and depth > 0:
                        c = text[i]
                        if in_str:
                            if c == "\\":
                                i += 2
                                continue
                            elif c == in_str:
                                in_str = None
                        else:
                            if c in ('"', "'"):
                                in_str = c
                            elif c == "(":
                                depth += 1
                            elif c == ")":
                                depth -= 1
                        i += 1
                    arg_text = text[start:i-1].strip()
                    binds.append(arg_text)
                    pos = i

                seen_combos = set()
                for idx, b in enumerate(binds):
                    m_combo = re.match(r'^"([^"]+)"|^mainMod\s*\.\.\s*"([^"]+)"', b)
                    if not m_combo:
                        continue
                    orig_combo = m_combo.group(1) if m_combo.group(1) else ("SUPER" + m_combo.group(2))
                    orig_combo = orig_combo.strip()
                    combo = orig_combo

                    # 1. Lewati duplikat tombol SUPER kanan (_R) karena keyboard hanya punya tombol Super kiri
                    if combo.endswith("_R") or "SUPER_R" in combo:
                        continue

                    # 2. Lewati fallback internal compositor (misal: pkill fuzzel jika quickshell mati)
                    if "pkill fuzzel" in b or "qsIsAlive" in b:
                        continue

                    # 3. Lewati hook event transparan internal quickshell (bukan pintasan pengguna)
                    if "workspaceNumber" in b and ("transparent" in b or "ignore_mods" in b):
                        continue

                    # 4. Tangani template loop Lua dinamis untuk workspace
                    if combo.rstrip().endswith("+") or combo.endswith("code:") or combo.endswith("Page_"):
                        if "SHIFT" in b and "workspace" in b and "key" in b:
                            combo = "SUPER + SHIFT + [1 - 0]"
                            category = "Window Management"
                            desc = "Pindahkan Jendela ke Ruang Kerja 1 - 10"
                        elif "workspace" in b and "key" in b:
                            combo = "SUPER + [1 - 0]"
                            category = "Workspaces"
                            desc = "Pindah ke Ruang Kerja 1 - 10"
                        elif "SUPER + ALT +" in b and "workspace" in b:
                            combo = "SUPER + ALT + [1 - 0]"
                            category = "Window Management"
                            desc = "Kirim Jendela ke Ruang Kerja 1 - 10 (Tanpa Pindah)"
                        elif "Page_" in b and "descdir" in b:
                            combo = "SUPER + SHIFT + PgUp / PgDn"
                            category = "Window Management"
                            desc = "Kirim Jendela ke Ruang Kerja Kiri / Kanan"
                        elif "keys[i]" in b and "CTRL + SUPER +" in b:
                            combo = "CTRL + SUPER + Panah Kiri / Kanan"
                            category = "Workspaces"
                            desc = "Pindah ke Ruang Kerja Kiri / Kanan"
                        else:
                            continue
                    else:
                        category = None
                        desc = None

                    # 5. Format tombol tap Super menjadi label yang ramah pengguna
                    is_super_tap = (combo == "SUPER + SUPER_L")
                    if is_super_tap:
                        combo = "SUPER (Tap)"
                        category = "Panels & Shell"
                        desc = "Buka Menu Pencarian & Peluncur Aplikasi"

                    # Hindari duplikasi tampilan pintasan
                    if combo in seen_combos:
                        continue
                    seen_combos.add(combo)

                    m_desc = re.search(r'description\s*=\s*"([^"]+)"', b)
                    raw_desc = m_desc.group(1) if m_desc else ""

                    rest = b[m_combo.end():].strip()
                    if rest.startswith(","):
                        rest = rest[1:].strip()
                    m_table = re.search(r",\s*\{.*\}\s*$", rest, re.DOTALL)
                    if m_table:
                        action = rest[:m_table.start()].strip()
                    else:
                        action = rest.strip()

                    if category is None:
                        category = "Lainnya"
                    if desc is None:
                        desc = raw_desc

                    if desc.startswith("App:"):
                        category = "Applications"
                        desc = desc[4:].strip()
                    elif desc.startswith("Window:"):
                        category = "Window Management"
                        desc = desc[7:].strip()
                    elif desc.startswith("Shell:"):
                        category = "Panels & Shell"
                        desc = desc[6:].strip()
                    elif desc.startswith("System:"):
                        category = "System"
                        desc = desc[7:].strip()
                    elif desc.startswith("Utilities:"):
                        category = "System Tools"
                        desc = desc[10:].strip()
                    elif desc.startswith("Workspace:"):
                        category = "Workspaces"
                        desc = desc[10:].strip()
                    elif desc.startswith("Media:"):
                        category = "Media"
                        desc = desc[6:].strip()
                    elif desc.startswith("Session:"):
                        category = "System"
                        desc = desc[8:].strip()
                    elif "workspace" in action.lower():
                        category = "Workspaces"
                        if not desc:
                            desc = "Workspace Navigation"

                    if not desc or desc == raw_desc:
                        # Terjemahkan aksi teknis umum ke bahasa yang ramah pengguna
                        if "terminal" in action:
                            category = "Applications"
                            desc = "Launch Terminal"
                        elif "browser" in action:
                            category = "Applications"
                            desc = "Launch Web Browser"
                        elif "fileManager" in action:
                            category = "Applications"
                            desc = "Launch File Manager"
                        elif "codeEditor" in action:
                            category = "Applications"
                            desc = "Launch Code Editor"
                        elif "overviewEmojiToggle" in action or "emojiPicker" in action:
                            category = "Panels & Shell"
                            desc = "Toggle Emoji Picker"
                        elif "sidebarLeftToggleDetach" in action:
                            category = "Panels & Shell"
                            desc = "Detach Left Sidebar"
                        elif "sidebarLeftToggle" in action:
                            category = "Panels & Shell"
                            desc = "Toggle Left Sidebar"
                        elif "sidebarRightToggle" in action:
                            category = "Panels & Shell"
                            desc = "Toggle Right Sidebar"
                        elif "overviewClipboardToggle" in action:
                            category = "Panels & Shell"
                            desc = "Toggle Clipboard History"
                        elif "searchToggleRelease" in action:
                            category = "Panels & Shell"
                            desc = "Toggle App Launcher & Search"
                        elif "window.kill" in action or "killactive" in action or "close" in action:
                            category = "Window Management"
                            desc = "Close Focused Window"
                        elif "focus" in action:
                            category = "Window Management"
                            desc = "Focus Window"
                        elif "fullscreen" in action:
                            category = "Window Management"
                            desc = "Toggle Fullscreen"
                        elif "brightness increment" in action or "brightnessctl s 5%+" in action:
                            category = "System"
                            desc = "Brightness Up (+)"
                        elif "brightness decrement" in action or "brightnessctl s 5%-" in action:
                            category = "System"
                            desc = "Brightness Down (-)"
                        elif "RaiseVolume" in combo:
                            category = "System"
                            desc = "Volume Up (+)"
                        elif "LowerVolume" in combo:
                            category = "System"
                            desc = "Volume Down (-)"
                        elif "AudioMute" in combo:
                            category = "System"
                            desc = "Mute Audio"
                        elif "AudioMicMute" in combo:
                            category = "System"
                            desc = "Mute Microphone"
                        elif "AudioNext" in combo:
                            category = "Media"
                            desc = "Next Media Track"
                        elif "AudioPrev" in combo:
                            category = "Media"
                            desc = "Previous Media Track"
                        elif "AudioPlay" in combo or "AudioPause" in combo:
                            category = "Media"
                            desc = "Play / Pause Media"
                        elif "zoomfunction" in action:
                            category = "Display"
                            desc = "Display Zoom In / Out"
                        elif "splitratio" in action:
                            category = "Window Management"
                            desc = "Adjust Window Split Ratio"
                        elif "virtual-machine" in action:
                            category = "System"
                            desc = "Virtual Machine Mode (VM Submap)"
                        elif "mouse_down" in combo or "mouse_up" in combo:
                            category = "Workspaces"
                            desc = "Switch Workspace (Mouse Scroll)"
                        elif "mouse:272" in combo or "mouse:274" in combo:
                            category = "Window Management"
                            desc = "Move Window (Drag)"
                        elif "mouse:273" in combo:
                            category = "Window Management"
                            desc = "Resize Window (Drag)"
                        elif "welcome.qml" in action:
                            category = "Panels & Shell"
                            desc = "Open Welcome Screen"
                        elif "regionRecord" in action:
                            category = "System Tools"
                            desc = "Screen Recording (Video Capture)"
                        elif "grimhyprctl" in action:
                            category = "System Tools"
                            desc = "Screenshot to File / Clipboard"
                        elif "Wrong close keybind" in action:
                            category = "Window Management"
                            desc = "Close Window Reminder (Alt+F4)"
                        elif not desc:
                            desc = action

                    item_id = f"base_{idx}_{orig_combo}"
                    display_combo = combo
                    is_disabled = (orig_combo in disabled_set) or (combo in disabled_set)
                    is_modified = (orig_combo in overrides) or (combo in overrides)

                    display_action = action
                    target_key = orig_combo if orig_combo in overrides else combo
                    if is_modified and target_key in overrides:
                        ovr = overrides[target_key]
                        display_combo = ovr.get("new_combo", combo)
                        if ovr.get("command"):
                            display_action = ovr.get("command")
                        if ovr.get("description"):
                            desc = ovr.get("description")
                        status = "modified"
                    elif is_disabled:
                        status = "disabled"
                    else:
                        status = "default"

                    results.append({
                        "id": item_id,
                        "combo": display_combo,
                        "orig_combo": orig_combo,
                        "action": display_action,
                        "command": display_action,
                        "description": desc,
                        "category": category,
                        "status": status,
                        "is_custom": False,
                        "is_modified": is_modified,
                        "is_disabled": is_disabled,
                        "can_reset": is_modified or is_disabled,
                        "can_delete": False
                    })
            except Exception as e:
                print(f"Error parsing base keybinds: {e}")

        for idx, item in enumerate(added):
            is_dis = not item.get("enabled", True)
            results.append({
                "id": item.get("id", f"custom_{idx}"),
                "combo": item.get("combo", ""),
                "orig_combo": item.get("combo", ""),
                "action": item.get("command", ""),
                "command": item.get("command", ""),
                "description": item.get("name", "Pintasan Kustom"),
                "category": "Kustom",
                "status": "disabled" if is_dis else "custom",
                "is_custom": True,
                "is_modified": False,
                "is_disabled": is_dis,
                "can_reset": False,
                "can_delete": True
            })

        # Analisis Konflik Kombinasi Tombol dan Duplikasi Perintah
        active_items = [it for it in results if not it.get("is_disabled", False)]

        combo_buckets = collections.defaultdict(list)
        for it in active_items:
            c = normalize_keybind_combo(it.get("combo", ""))
            if c and not c.startswith("SUPER + [1 - 0]"):
                combo_buckets[c].append(it)

        cmd_buckets = collections.defaultdict(list)
        for it in active_items:
            cmd = normalize_keybind_command(it.get("command", ""))
            if cmd and len(cmd) > 2:
                cmd_buckets[cmd].append(it)

        for it in results:
            it["combo_conflicts"] = []
            it["command_duplicates"] = []
            if not it.get("is_disabled", False):
                c = normalize_keybind_combo(it.get("combo", ""))
                if c in combo_buckets and len(combo_buckets[c]) > 1:
                    it["combo_conflicts"] = [
                        {
                            "id": o.get("id", ""),
                            "combo": o.get("combo", ""),
                            "description": o.get("description", "") or o.get("combo", ""),
                            "command": o.get("command", "")
                        }
                        for o in combo_buckets[c] if o.get("id") != it.get("id")
                    ]

                cmd = normalize_keybind_command(it.get("command", ""))
                if cmd in cmd_buckets and len(cmd_buckets[cmd]) > 1:
                    it["command_duplicates"] = [
                        {
                            "id": o.get("id", ""),
                            "combo": o.get("combo", ""),
                            "description": o.get("description", "") or o.get("combo", "")
                        }
                        for o in cmd_buckets[cmd] if o.get("id") != it.get("id")
                    ]

        return results

    def check_keybind_collision(self, combo: str, command: str = "", exclude_id: str = None) -> dict:
        """Periksa apakah kombinasi tombol atau perintah bertabrakan dengan pintasan aktif yang sudah ada."""
        all_kbs = self.get_all_keybinds()
        norm_c = normalize_keybind_combo(combo)
        norm_cmd = normalize_keybind_command(command)

        conflict = None
        dup_cmd = None

        for it in all_kbs:
            if it.get("is_disabled", False):
                continue
            if exclude_id and it.get("id") == exclude_id:
                continue

            if norm_c and not conflict and not norm_c.startswith("SUPER + [1 - 0]"):
                it_c = normalize_keybind_combo(it.get("combo", ""))
                if it_c == norm_c:
                    conflict = {
                        "id": it.get("id", ""),
                        "combo": it.get("combo", ""),
                        "description": it.get("description", "") or it.get("combo", ""),
                        "command": it.get("command", "")
                    }

            if norm_cmd and len(norm_cmd) > 2 and not dup_cmd:
                it_cmd = normalize_keybind_command(it.get("command", ""))
                if it_cmd == norm_cmd:
                    dup_cmd = {
                        "id": it.get("id", ""),
                        "combo": it.get("combo", ""),
                        "description": it.get("description", "") or it.get("combo", ""),
                        "command": it.get("command", "")
                    }

        return {
            "combo_conflict": conflict,
            "command_duplicate": dup_cmd
        }

    # Backward compatibility alias
    get_base_keybinds = get_all_keybinds

    def get_disabled_base_execs(self):
        self._check_and_reload()
        return set(self.get("hyprland.disabled_base_execs", []))

    def set_base_exec_enabled(self, tag, is_enabled):
        disabled = self.get_disabled_base_execs()
        if is_enabled:
            disabled.discard(tag)
        else:
            disabled.add(tag)
        self.set("hyprland.disabled_base_execs", sorted(list(disabled)), auto_apply=False)
        self.generate_execs_lua()

    def get_base_execs(self):
        disabled = self.get_disabled_base_execs()
        services = [
            {"id": "QuickSplash", "command": "qs -p QuickSplash.qml", "title": "Startup Splash (QuickSplash)", "desc": "Boot splash screen when logging into desktop", "category": "Appearance"},
            {"id": "qs", "command": "qs -c $qsConfig", "title": "Quickshell Desktop", "desc": "Status bar panels, wallpaper widgets, and OSDs", "category": "Interface"},
            {"id": "gnome-keyring", "command": "gnome-keyring-daemon", "title": "GNOME Keyring", "desc": "Secure credential and password storage", "category": "Security"},
            {"id": "hypridle", "command": "hypridle", "title": "Hypridle Daemon", "desc": "Idle timeout manager and automatic screen locker", "category": "Power"},
            {"id": "cliphist", "command": "cliphist", "title": "Cliphist Clipboard", "desc": "Clipboard text and image history recorder", "category": "Utilities"},
            {"id": "kdeconnectd", "command": "kdeconnectd", "title": "KDE Connect Daemon", "desc": "Notification sync and file transfer with mobile devices", "category": "Network"},
            {"id": "hyprpm", "command": "hyprpm reload", "title": "Hyprland Plugin Manager", "desc": "Initialize Hyprland compositor plugins", "category": "System"},
            {"id": "awww", "command": "awww-daemon", "title": "Awww Wallpaper Daemon", "desc": "Desktop background artwork rendering service", "category": "Appearance"},
        ]
        for s in services:
            s["enabled"] = s["id"] not in disabled
        return services

    def get_execs(self):
        self._check_and_reload()
        return self.get("hyprland.execs", [])

    def save_execs(self, execs_list):
        self.set("hyprland.execs", execs_list, auto_apply=False)
        self.generate_execs_lua()

    def generate_execs_lua(self):
        execs_lua_path = os.path.expanduser("~/.config/hypr/custom/execs.lua")
        execs = self.get_execs()
        disabled = self.get_disabled_base_execs()

        lines = [
            "-- File ini dihasilkan otomatis oleh Pengaturan Desktop (Autostart & Layanan)",
            "-- JANGAN mengedit berkas ini secara manual karena akan tertimpa saat disimpan di GUI.",
            "",
            "-- Daftar layanan bawaan sistem yang dinonaktifkan secara non-destruktif",
            "_G.disabled_base_execs = {",
        ]
        for tag in sorted(disabled):
            lines.append(f'\t["{tag}"] = true,')
        lines.append("}")
        lines.append("disabled_base_execs = _G.disabled_base_execs")
        lines.append("")
        lines.append('hl.on("hyprland.start", function()')

        for item in execs:
            if item.get("enabled", True):
                cmd = item.get("command", "").strip()
                name = item.get("name", "Aplikasi")
                if cmd:
                    cmd_lua = cmd.replace('\\', '\\\\').replace('"', '\\"')
                    lines.append(f'\t-- {name}')
                    lines.append(f'\thl.exec_cmd("{cmd_lua}")')

        lines.append("end)")
        lines.append("")

        self._atomic_write_lua(execs_lua_path, "\n".join(lines))

    def get_env(self):
        self._check_and_reload()
        return {
            "xcursor_size": self.get("hyprland.env.xcursor_size", 24),
            "electron_platform": self.get("hyprland.env.electron_platform", "auto"),
            "moz_wayland": self.get("hyprland.env.moz_wayland", True),
            "libva_driver": self.get("hyprland.env.libva_driver", "iHD"),
            "custom_vars": self.get("hyprland.env.custom_vars", [])
        }

    def save_env(self, env_data):
        self.set("hyprland.env", env_data, auto_apply=False)
        self.generate_env_lua()

    def generate_env_lua(self):
        env_lua_path = os.path.expanduser("~/.config/hypr/custom/env.lua")
        env_data = self.get_env()
        term = self.get("apps.terminal", "kitty -1")

        lines = [
            "-- File ini dihasilkan otomatis oleh Pengaturan Desktop (Variabel Sesi)",
            "-- JANGAN mengedit berkas ini secara manual karena akan tertimpa saat disimpan di GUI.",
            "",
            f'hl.env("TERMINAL", "{term}")',
            f'hl.env("XCURSOR_SIZE", "{env_data.get("xcursor_size", 24)}")',
            f'hl.env("HYPRCURSOR_SIZE", "{env_data.get("xcursor_size", 24)}")',
            f'hl.env("ELECTRON_OZONE_PLATFORM_HINT", "{env_data.get("electron_platform", "auto")}")',
        ]

        if env_data.get("moz_wayland", True):
            lines.append('hl.env("MOZ_ENABLE_WAYLAND", "1")')

        driver = env_data.get("libva_driver", "iHD")
        if driver and driver != "auto":
            lines.append(f'hl.env("LIBVA_DRIVER_NAME", "{driver}")')

        for cv in env_data.get("custom_vars", []):
            k = cv.get("key", "").strip()
            v = cv.get("val", "").strip()
            if k:
                k_lua = k.replace('"', '\\"')
                v_lua = v.replace('"', '\\"')
                lines.append(f'hl.env("{k_lua}", "{v_lua}")')

        lines.append("")
        self._atomic_write_lua(env_lua_path, "\n".join(lines))




    # --------------------------------------------------------------------------
    # RINAUBY SPECIFIC METHODS
    # --------------------------------------------------------------------------
    def set_border_glow(self, enabled: bool):
        self.set("hyprland.customBorders", enabled)
        if enabled:
            self.set("hyprland.activeBorderDark", "rgb(db9c5e) rgb(e5c07b) 45deg")
            self.set("hyprland.borderSize", 2)
        else:
            self.set("hyprland.activeBorderDark", "rgba(555555cc)")
        self.apply_hyprland()

    def set_roman_workspaces(self, enabled: bool):
        self.set("rinauby.roman_workspaces", enabled)
        subprocess.run(["pkill", "-RTMIN+8", "waybar"], stderr=subprocess.DEVNULL)

    def set_wallpaper(self, wp_filename: str, title: str):
        self.set("active_wallpaper", wp_filename)
        candidates = [
            os.path.join(ASSETS_DIR, "wallpapers", wp_filename) if os.path.isdir(os.path.join(ASSETS_DIR, "wallpapers")) else os.path.join(ASSETS_DIR, wp_filename),
            os.path.join("/usr/share/backgrounds/rinauby", wp_filename),
            os.path.expanduser(f"~/.local/share/backgrounds/rinauby/{wp_filename}"),
            f"/home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/wallpapers/{wp_filename}"
        ]
        wp_path = next((c for c in candidates if os.path.exists(c)), candidates[0])
        if os.path.exists(wp_path):
            subprocess.run(["pkill", "-x", "swaybg"], stderr=subprocess.DEVNULL)
            subprocess.Popen(["swaybg", "-i", wp_path, "-m", "fill"],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            with open("/tmp/current_wallpaper_title", "w") as f:
                f.write(title)
            # Rotasi semboyan dan update Waybar
            quote_candidates = [
                os.path.expanduser("~/.config/waybar/quote_rotator.sh"),
                "/usr/local/bin/rinauby-quote",
                os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "waybar", "quote_rotator.sh")),
                "/home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/dotfiles/waybar/quote_rotator.sh"
            ]
            quote_rotator = next((q for q in quote_candidates if os.path.exists(q)), None)
            if quote_rotator:
                subprocess.run([quote_rotator, "--next"], stderr=subprocess.DEVNULL)
            subprocess.run(["pkill", "-RTMIN+8", "waybar"], stderr=subprocess.DEVNULL)
            subprocess.run(["pkill", "-USR1", "-f", "window_title.py"], stderr=subprocess.DEVNULL)


    # --------------------------------------------------------------------------
    # NETWORK & WI-FI (NetworkManager / nmcli)
    # --------------------------------------------------------------------------
    def get_wifi_enabled(self) -> bool:
        try:
            out = subprocess.check_output(["nmcli", "radio", "wifi"], text=True, stderr=subprocess.DEVNULL).strip()
            return out.lower() == "enabled"
        except Exception:
            return False

    def set_wifi_enabled(self, enabled: bool):
        val = "on" if enabled else "off"
        subprocess.run(["nmcli", "radio", "wifi", val], stderr=subprocess.DEVNULL)

    def get_airplane_mode(self) -> bool:
        try:
            out = subprocess.check_output(["rfkill", "list", "all"], text=True, stderr=subprocess.DEVNULL)
            return "Soft blocked: yes" in out
        except Exception:
            return False

    def set_airplane_mode(self, enabled: bool):
        val = "block" if enabled else "unblock"
        subprocess.run(["rfkill", val, "all"], stderr=subprocess.DEVNULL)

    def get_wifi_networks(self) -> list:
        try:
            res = subprocess.check_output(["nmcli", "-t", "-f", "in-use,ssid,signal,security", "dev", "wifi", "list"], text=True, stderr=subprocess.DEVNULL)
            networks = []
            seen = set()
            for line in res.splitlines():
                parts = line.strip().split(":")
                if len(parts) >= 4:
                    in_use = (parts[0] == "*")
                    ssid = parts[1].strip()
                    if not ssid or ssid in seen:
                        continue
                    seen.add(ssid)
                    sig = int(parts[2]) if parts[2].isdigit() else 50
                    sec = parts[3].strip()
                    networks.append({"in_use": in_use, "ssid": ssid, "signal": sig, "security": sec})
            return networks
        except Exception:
            return []

    def connect_wifi(self, ssid: str, password: str = None):
        cmd = ["nmcli", "dev", "wifi", "connect", ssid]
        if password:
            cmd.extend(["password", password])
        subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    def disconnect_wifi(self, ssid: str):
        subprocess.run(["nmcli", "con", "down", "id", ssid], stderr=subprocess.DEVNULL)

    # --------------------------------------------------------------------------
    # BLUETOOTH (bluetoothctl)
    # --------------------------------------------------------------------------
    def get_bluetooth_enabled(self) -> bool:
        try:
            out = subprocess.check_output(["bluetoothctl", "show"], text=True, stderr=subprocess.DEVNULL)
            return "Powered: yes" in out
        except Exception:
            return False

    def set_bluetooth_enabled(self, enabled: bool):
        val = "on" if enabled else "off"
        subprocess.run(["bluetoothctl", "power", val], stderr=subprocess.DEVNULL)

    def get_bluetooth_discoverable(self) -> bool:
        try:
            out = subprocess.check_output(["bluetoothctl", "show"], text=True, stderr=subprocess.DEVNULL)
            return "Discoverable: yes" in out
        except Exception:
            return False

    def set_bluetooth_discoverable(self, enabled: bool):
        val = "on" if enabled else "off"
        subprocess.run(["bluetoothctl", "discoverable", val], stderr=subprocess.DEVNULL)

    def get_bluetooth_devices(self) -> list:
        try:
            out = subprocess.check_output(["bluetoothctl", "devices"], text=True, stderr=subprocess.DEVNULL)
            devs = []
            for line in out.splitlines():
                parts = line.strip().split(" ", 2)
                if len(parts) >= 3 and parts[0] == "Device":
                    mac = parts[1]
                    name = parts[2]
                    try:
                        info = subprocess.check_output(["bluetoothctl", "info", mac], text=True, stderr=subprocess.DEVNULL)
                    except Exception:
                        info = ""
                    connected = "Connected: yes" in info
                    paired = "Paired: yes" in info
                    icon = "audio-headphones-symbolic" if any(k in info.lower() or k in name.lower() for k in ["x3", "head", "ear", "sound", "audio"]) else "bluetooth-symbolic"
                    devs.append({"mac": mac, "name": name, "connected": connected, "paired": paired, "icon": icon})
            return devs
        except Exception:
            return []

    def connect_bluetooth(self, mac: str):
        subprocess.Popen(["bluetoothctl", "connect", mac], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    def disconnect_bluetooth(self, mac: str):
        subprocess.run(["bluetoothctl", "disconnect", mac], stderr=subprocess.DEVNULL)

    def remove_bluetooth(self, mac: str):
        subprocess.run(["bluetoothctl", "remove", mac], stderr=subprocess.DEVNULL)

DEFAULT_APP_CATEGORIES = [
    # 1. Aplikasi Utama
    {
        "id": "terminal",
        "group_id": "core",
        "group_title": "Core Applications",
        "group_desc": "Terminal, web browser, and file manager",
        "title": "Terminal",
        "subtitle": "Console and command line environment",
        "icon": "utilities-terminal-symbolic",
        "type": "terminal",
    },
    {
        "id": "web_browser",
        "group_id": "core",
        "group_title": "Core Applications",
        "group_desc": "Terminal, web browser, and file manager",
        "title": "Web Browser",
        "subtitle": "Web links and internet pages",
        "icon": "web-browser-symbolic",
        "type": "mime",
        "primary_mimes": ["x-scheme-handler/http", "x-scheme-handler/https"],
        "mimes": ["x-scheme-handler/http", "x-scheme-handler/https", "text/html", "application/xhtml+xml"],
        "category_filter": ["WebBrowser"],
        "bad_apps": {"claude.desktop", "gemini.desktop", "whatsapp.desktop", "youtube.desktop"},
    },
    {
        "id": "file_manager",
        "group_id": "core",
        "group_title": "Core Applications",
        "group_desc": "Terminal, web browser, and file manager",
        "title": "File Manager",
        "subtitle": "Browse folders and storage drives",
        "icon": "system-file-manager-symbolic",
        "type": "mime",
        "primary_mimes": ["inode/directory"],
        "mimes": ["inode/directory"],
        "category_filter": ["FileManager"],
        "bad_apps": {"kitty-open.desktop", "org.gnome.baobab.desktop", "baobab.desktop"},
    },

    # 2. Dokumen & Teks
    {
        "id": "word_processor",
        "group_id": "productivity",
        "group_title": "Documents & Text",
        "group_desc": "Word processor, text editor, code, spreadsheets, and presentations",
        "title": "Word Processor",
        "subtitle": "Manuscript documents (.docx, .odt)",
        "icon": "x-office-document-symbolic",
        "type": "mime",
        "primary_mimes": [
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "application/msword",
            "application/vnd.oasis.opendocument.text"
        ],
        "mimes": [
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "application/msword",
            "application/vnd.oasis.opendocument.text",
            "application/rtf"
        ],
        "category_filter": ["WordProcessor"],
        "bad_apps": {
            "org.gnome.Nautilus.desktop", "nautilus.desktop",
            "org.kde.ark.desktop", "ark.desktop",
            "clickup.desktop", "dev.zed.Zed.desktop",
            "org.gnome.TextEditor.desktop", "vim.desktop",
            "nvim.desktop", "code.desktop"
        },
    },
    {
        "id": "text_editor",
        "group_id": "productivity",
        "group_title": "Documents & Text",
        "group_desc": "Word processor, text editor, code, spreadsheets, and presentations",
        "title": "Text Editor",
        "subtitle": "Plain text notes and files (.txt, .md)",
        "icon": "accessories-text-editor-symbolic",
        "type": "mime",
        "primary_mimes": ["text/plain", "text/markdown"],
        "mimes": ["text/plain", "text/markdown"],
        "category_filter": ["TextEditor"],
        "bad_apps": {
            "libreoffice-writer.desktop", "onlyoffice-desktopeditors.desktop",
            "textmaker-2026.desktop", "kitty-open.desktop",
            "matlab.desktop", "org.godotengine.Godot.desktop", "godot-mono.desktop"
        },
    },
    {
        "id": "code_editor",
        "group_id": "productivity",
        "group_title": "Documents & Text",
        "group_desc": "Word processor, text editor, code, spreadsheets, and presentations",
        "title": "Code Editor",
        "subtitle": "Programming scripts and development projects",
        "icon": "applications-development-symbolic",
        "type": "code_editor",
        "primary_mimes": ["application/x-shellscript", "text/x-python", "text/x-c"],
        "mimes": [
            "application/x-shellscript", "text/x-python", "text/x-c",
            "text/x-c++", "text/javascript", "application/json",
            "text/x-lua", "application/xml", "application/yaml"
        ],
        "category_filter": ["IDE"],
        "bad_apps": {
            "libreoffice-writer.desktop", "onlyoffice-desktopeditors.desktop",
            "textmaker-2026.desktop", "kitty-open.desktop",
            "matlab.desktop", "org.godotengine.Godot.desktop", "godot-mono.desktop",
            "assistant.desktop", "designer.desktop", "linguist.desktop",
            "qdbusviewer.desktop", "cmake-gui.desktop", "org.kde.kuserfeedback-console.desktop",
            "yad-icon-browser.desktop", "yad.desktop"
        },
    },
    {
        "id": "pdf_viewer",
        "group_id": "productivity",
        "group_title": "Documents & Text",
        "group_desc": "Word processor, text editor, code, spreadsheets, and presentations",
        "title": "Document Viewer (PDF)",
        "subtitle": "Portable document format files (.pdf)",
        "icon": "x-office-document-symbolic",
        "type": "mime",
        "primary_mimes": ["application/pdf"],
        "mimes": ["application/pdf"],
        "category_filter": [],
        "bad_apps": {
            "libreoffice-draw.desktop", "libreoffice-writer.desktop",
            "libreoffice-calc.desktop", "libreoffice-impress.desktop",
            "libreoffice-math.desktop", "libreoffice-startcenter.desktop",
            "org.inkscape.Inkscape.desktop", "inkscape.desktop",
            "clickup.desktop", "org.gnome.Loupe.desktop"
        },
    },
    {
        "id": "spreadsheet",
        "group_id": "productivity",
        "group_title": "Documents & Text",
        "group_desc": "Word processor, text editor, code, spreadsheets, and presentations",
        "title": "Spreadsheets",
        "subtitle": "Data tables and calculations (.xlsx, .ods)",
        "icon": "x-office-spreadsheet-symbolic",
        "type": "mime",
        "primary_mimes": [
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "application/vnd.ms-excel",
            "application/vnd.oasis.opendocument.spreadsheet"
        ],
        "mimes": [
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "application/vnd.ms-excel",
            "application/vnd.oasis.opendocument.spreadsheet",
            "text/csv"
        ],
        "category_filter": ["Spreadsheet"],
        "bad_apps": {
            "org.gnome.Nautilus.desktop", "nautilus.desktop",
            "org.kde.ark.desktop", "ark.desktop",
            "clickup.desktop", "org.gnome.Evince.desktop",
            "libreoffice-draw.desktop", "libreoffice-impress.desktop",
            "libreoffice-writer.desktop", "libreoffice-math.desktop",
            "libreoffice-startcenter.desktop", "nvim.desktop",
            "vim.desktop", "dev.zed.Zed.desktop", "org.gnome.TextEditor.desktop"
        },
    },
    {
        "id": "presentation",
        "group_id": "productivity",
        "group_title": "Documents & Text",
        "group_desc": "Word processor, text editor, code, spreadsheets, and presentations",
        "title": "Presentations",
        "subtitle": "Slide decks and presentations (.pptx, .odp)",
        "icon": "x-office-presentation-symbolic",
        "type": "mime",
        "primary_mimes": [
            "application/vnd.openxmlformats-officedocument.presentationml.presentation",
            "application/vnd.ms-powerpoint",
            "application/vnd.oasis.opendocument.presentation"
        ],
        "mimes": [
            "application/vnd.openxmlformats-officedocument.presentationml.presentation",
            "application/vnd.ms-powerpoint",
            "application/vnd.oasis.opendocument.presentation"
        ],
        "category_filter": ["Presentation"],
        "bad_apps": {
            "org.gnome.Nautilus.desktop", "nautilus.desktop",
            "org.kde.ark.desktop", "ark.desktop",
            "clickup.desktop", "org.gnome.Evince.desktop",
            "libreoffice-draw.desktop", "libreoffice-calc.desktop",
            "libreoffice-writer.desktop", "libreoffice-math.desktop",
            "libreoffice-startcenter.desktop"
        },
    },

    # 3. Multimedia
    {
        "id": "image_viewer",
        "group_id": "media",
        "group_title": "Multimedia",
        "group_desc": "Photos, video playback, and music player",
        "title": "Image Viewer",
        "subtitle": "Photos and visual illustrations (.png, .jpg, .svg)",
        "icon": "image-x-generic-symbolic",
        "type": "mime",
        "primary_mimes": ["image/png", "image/jpeg"],
        "mimes": ["image/png", "image/jpeg", "image/webp", "image/gif", "image/svg+xml", "image/bmp"],
        "category_filter": ["2DGraphics", "RasterGraphics"],
        "bad_apps": {
            "firefox.desktop", "swappy.desktop", "org.kde.kdenlive.desktop",
            "org.inkscape.Inkscape.desktop", "org.fontforge.FontForge.desktop",
            "libreoffice-draw.desktop", "libreoffice-writer.desktop",
            "dev.zed.Zed.desktop", "org.gnome.TextEditor.desktop",
            "nvim.desktop", "vim.desktop", "onlyoffice-desktopeditors.desktop",
            "com.usebottles.bottles.desktop", "org.gnome.Evince.desktop",
            "org.gnome.Evince"
        },
    },
    {
        "id": "video_player",
        "group_id": "media",
        "group_title": "Multimedia",
        "group_desc": "Photos, video playback, and music player",
        "title": "Video Player",
        "subtitle": "Video clips and movies (.mp4, .mkv)",
        "icon": "video-x-generic-symbolic",
        "type": "mime",
        "primary_mimes": ["video/mp4", "video/x-matroska", "video/webm"],
        "mimes": ["video/mp4", "video/x-matroska", "video/webm", "video/quicktime", "video/x-msvideo"],
        "category_filter": [],
        "bad_apps": {
            "org.kde.kdenlive.desktop", "firefox.desktop",
            "org.gnome.Snapshot.desktop", "com.github.wwmm.easyeffects.desktop",
            "com.dec05eba.gpu_screen_recorder.desktop", "guvcview.desktop",
            "org.kde.kamoso.desktop", "com.obsproject.Studio.desktop",
            "pavucontrol-qt.desktop", "qv4l2.desktop", "qvidcap.desktop",
            "re.fossplant.songrec.desktop", "org.pulseaudio.pavucontrol.desktop"
        },
    },
    {
        "id": "audio_player",
        "group_id": "media",
        "group_title": "Multimedia",
        "group_desc": "Photos, video playback, and music player",
        "title": "Music Player",
        "subtitle": "Audio tracks and music files (.mp3, .flac)",
        "icon": "audio-x-generic-symbolic",
        "type": "mime",
        "primary_mimes": ["audio/mpeg", "audio/flac", "audio/ogg"],
        "mimes": ["audio/mpeg", "audio/flac", "audio/ogg", "audio/mp4", "audio/wav", "audio/x-wav"],
        "category_filter": ["Music"],
        "bad_apps": {
            "org.kde.kdenlive.desktop", "firefox.desktop",
            "org.gnome.Snapshot.desktop", "com.github.wwmm.easyeffects.desktop",
            "com.dec05eba.gpu_screen_recorder.desktop", "guvcview.desktop",
            "org.kde.kamoso.desktop", "com.obsproject.Studio.desktop",
            "pavucontrol-qt.desktop", "qv4l2.desktop", "qvidcap.desktop",
            "re.fossplant.songrec.desktop", "org.pulseaudio.pavucontrol.desktop"
        },
    },

    # 4. Utilitas
    {
        "id": "archive_manager",
        "group_id": "utility",
        "group_title": "Utilities",
        "group_desc": "Archive manager and email client",
        "title": "Archive Manager",
        "subtitle": "Archive packages and compressed files (.zip, .tar, .7z)",
        "icon": "package-x-generic-symbolic",
        "type": "mime",
        "primary_mimes": ["application/zip", "application/x-tar", "application/x-7z-compressed"],
        "mimes": [
            "application/zip",
            "application/x-tar",
            "application/x-7z-compressed",
            "application/x-compressed-tar",
            "application/x-rar",
            "application/x-bzip2"
        ],
        "category_filter": ["Archiving"],
        "bad_apps": {
            "org.gnome.Nautilus.desktop", "nautilus.desktop",
            "com.system76.CosmicFiles.desktop", "org.kde.dolphin.desktop"
        },
    },
    {
        "id": "email_client",
        "group_id": "utility",
        "group_title": "Utilities",
        "group_desc": "Archive manager and email client",
        "title": "Email Client",
        "subtitle": "Electronic mail messaging (mailto:)",
        "icon": "mail-unread-symbolic",
        "type": "mime",
        "primary_mimes": ["x-scheme-handler/mailto"],
        "mimes": ["x-scheme-handler/mailto", "message/rfc822"],
        "category_filter": ["Email"],
        "bad_apps": {
            "claude.desktop", "gemini.desktop", "whatsapp.desktop",
            "youtube.desktop", "steam.desktop", "discord.desktop", "webcord.desktop"
        },
    }
]



backend = ConfigBackend()
