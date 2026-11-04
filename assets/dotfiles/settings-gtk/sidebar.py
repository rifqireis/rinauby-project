import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw

SIDEBAR_GROUPS = [
    # 1. Connectivity & Network
    {
        "category": "Connectivity",
        "items": [
            {
                "id": "wifi",
                "title": "Wi-Fi",
                "icon": "network-wireless-symbolic",
                "keywords": ["wifi", "wi-fi", "internet", "network", "wireless", "ssid", "airplane", "hotspot"]
            },
            {
                "id": "bluetooth",
                "title": "Bluetooth",
                "icon": "bluetooth-symbolic",
                "keywords": ["bluetooth", "bt", "wireless", "devices", "headset", "earphone", "mouse", "keyboard"]
            }
        ]
    },
    # 2. Appearance & Personalization
    {
        "category": "Appearance & Personalization",
        "items": [
            {
                "id": "appearance",
                "title": "Appearance",
                "icon": "preferences-desktop-appearance-symbolic",
                "keywords": ["appearance", "theme", "mode", "dark", "light", "color", "accent", "roman", "numerals"]
            },
            {
                "id": "wallpaper",
                "title": "Wallpapers",
                "icon": "preferences-desktop-wallpaper-symbolic",
                "keywords": ["wallpaper", "background", "artwork", "renaissance", "gallery", "image"]
            },
            {
                "id": "gtk_theme",
                "title": "GTK Theme & Icons",
                "icon": "applications-graphics-symbolic",
                "keywords": ["gtk", "theme", "icons", "cursor", "fonts", "styling"]
            }
        ]
    },
    # 3. Window Manager (Hyprland Core)
    {
        "category": "Window Manager",
        "items": [
            {
                "id": "general",
                "title": "General Settings",
                "icon": "preferences-system-windows-symbolic",
                "keywords": ["general", "tiling", "layout", "gaps", "borders", "rounding", "blur", "shadow", "animations", "touchpad", "cursor", "sensitivity", "input"]
            },
            {
                "id": "window_rules",
                "title": "Window Rules",
                "icon": "window-restore-symbolic",
                "keywords": ["window", "rules", "floating", "geometry", "size", "opacity", "class", "behavior"]
            },
            {
                "id": "default_apps",
                "title": "Default Apps",
                "icon": "preferences-desktop-default-applications-symbolic",
                "keywords": ["default", "apps", "browser", "terminal", "files", "editor", "applications"]
            },
            {
                "id": "execs",
                "title": "Startup Applications",
                "icon": "system-run-symbolic",
                "keywords": ["autostart", "startup", "execs", "services", "login", "daemons"]
            },
            {
                "id": "env",
                "title": "Session Variables",
                "icon": "utilities-terminal-symbolic",
                "keywords": ["env", "environment", "variables", "session", "wayland", "vaapi", "gpu", "cursor"]
            }
        ]
    },
    # 4. Panel & System
    {
        "category": "Panel & System",
        "items": [
            {
                "id": "bar",
                "title": "Waybar Panel",
                "icon": "user-desktop-symbolic",
                "keywords": ["bar", "waybar", "panel", "motto", "clock", "telemetry", "status", "system"]
            },
            {
                "id": "dock_lock",
                "title": "Lock Screen",
                "icon": "system-lock-screen-symbolic",
                "keywords": ["lockscreen", "hyprlock", "security", "password", "blur", "clock"]
            },
            {
                "id": "audio",
                "title": "Sound",
                "icon": "audio-volume-high-symbolic",
                "keywords": ["audio", "sound", "volume", "protection", "speaker", "output"]
            },
            {
                "id": "power",
                "title": "Power & Battery",
                "icon": "battery-symbolic",
                "keywords": ["battery", "power", "suspend", "sleep", "energy", "threshold"]
            },
            {
                "id": "shortcuts",
                "title": "Keyboard Shortcuts",
                "icon": "input-keyboard-symbolic",
                "keywords": ["shortcuts", "keyboard", "keybinds", "super", "hotkeys"]
            },
            {
                "id": "about",
                "title": "About Rinauby",
                "icon": "help-about-symbolic",
                "keywords": ["about", "system", "kernel", "hyprland", "ubuntu", "distribution", "specs"]
            }
        ]
    }
]

class SettingsSidebar(Gtk.Box):
    def __init__(self, on_select_callback=None):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        self.set_size_request(260, -1)
        self.on_select_callback = on_select_callback
        self.rows_map = {}
        self.item_rows = []
        self.separator_rows = []
        self.search_text = ""

        # Search Entry Container
        search_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        search_box.set_margin_start(12)
        search_box.set_margin_end(12)
        search_box.set_margin_top(8)
        search_box.set_margin_bottom(6)

        self.search_entry = Gtk.SearchEntry()
        self.search_entry.set_placeholder_text("Search settings...")
        self.search_entry.set_hexpand(True)
        self.search_entry.connect("search-changed", self._on_search_changed)
        search_box.append(self.search_entry)
        self.append(search_box)

        # Scrolled Window
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_vexpand(True)
        scrolled.set_hexpand(True)
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)

        self.listbox = Gtk.ListBox()
        self.listbox.add_css_class("navigation-sidebar")
        self.listbox.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self.listbox.set_filter_func(self._filter_func)
        self.listbox.connect("row-activated", self._on_row_activated)

        self._build_sidebar()

        scrolled.set_child(self.listbox)
        self.append(scrolled)

    def _build_sidebar(self):
        for idx, group in enumerate(SIDEBAR_GROUPS):
            for item in group["items"]:
                row = Gtk.ListBoxRow()
                row.set_selectable(True)
                row.set_activatable(True)
                row.page_id = item["id"]
                row.title = item["title"]
                row.keywords = item["keywords"]
                row.category = group["category"]
                row.is_separator = False

                box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
                box.set_margin_start(6)
                box.set_margin_end(6)
                box.set_valign(Gtk.Align.CENTER)

                icon = Gtk.Image.new_from_icon_name(item["icon"])
                icon.set_pixel_size(16)
                icon.set_valign(Gtk.Align.CENTER)
                box.append(icon)

                lbl = Gtk.Label(label=item["title"], xalign=0)
                lbl.set_valign(Gtk.Align.CENTER)
                lbl.set_hexpand(True)
                box.append(lbl)

                row.set_child(box)
                self.listbox.append(row)
                self.rows_map[item["id"]] = row
                self.item_rows.append(row)

            if idx < len(SIDEBAR_GROUPS) - 1:
                sep_row = Gtk.ListBoxRow()
                sep_row.set_selectable(False)
                sep_row.set_activatable(False)
                sep_row.set_can_focus(False)
                sep_row.set_focusable(False)
                sep_row.set_size_request(-1, 1)
                sep_row.set_can_target(False)
                sep_row.is_separator = True
                sep_row.add_css_class("separator-row")

                sep = Gtk.Box()
                sep.add_css_class("sidebar-separator")
                sep_row.set_child(sep)

                self.listbox.append(sep_row)
                self.separator_rows.append(sep_row)

    def _filter_func(self, row):
        if getattr(row, "is_separator", False):
            return self.search_text == ""

        if not self.search_text:
            return True

        q = self.search_text.lower()
        if q in row.title.lower() or q in row.category.lower():
            return True
        for kw in row.keywords:
            if q in kw.lower():
                return True
        return False

    def _on_search_changed(self, entry):
        self.search_text = entry.get_text().strip()
        self.listbox.invalidate_filter()

    def _on_row_activated(self, listbox, row):
        if not row or getattr(row, "is_separator", False):
            return
        if self.on_select_callback and hasattr(row, "page_id"):
            self.on_select_callback(row.page_id)

    def select_page(self, page_id):
        if page_id in self.rows_map:
            row = self.rows_map[page_id]
            self.listbox.select_row(row)
