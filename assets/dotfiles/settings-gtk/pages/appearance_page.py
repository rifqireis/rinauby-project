import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw
from backend import backend

class AppearancePage(Gtk.Box):
    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self.set_margin_top(14)
        self.set_margin_bottom(18)
        self.set_margin_start(16)
        self.set_margin_end(16)

        # Header Title
        title_lbl = Gtk.Label(label="Appearance Customizer")
        title_lbl.set_halign(Gtk.Align.START)
        title_lbl.add_css_class("page-header-title")
        self.append(title_lbl)

        # Preferences Group matching ui/renaissance_settings_gtk.png
        group = Adw.PreferencesGroup()
        self.append(group)

        # 1. Color Scheme Row
        color_row = Adw.ActionRow(
            title="Color Scheme",
            subtitle="Everforest Dark Slate with Renaissance Gold accents"
        )
        # Dropdown / Pill Button
        self.scheme_btn = Gtk.MenuButton()
        self.scheme_btn.set_label(backend.get("color_scheme", "Everforest Warm"))
        self.scheme_btn.add_css_class("pill-dropdown-button")
        self.scheme_btn.set_valign(Gtk.Align.CENTER)

        # Popover menu for schemes
        popover = Gtk.Popover()
        pop_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        pop_box.set_margin_top(8)
        pop_box.set_margin_bottom(8)
        pop_box.set_margin_start(8)
        pop_box.set_margin_end(8)

        schemes = [
            "Everforest Warm",
            "Classical Athens Gold",
            "Florence Dark Slate",
            "Vatican Humanism"
        ]
        for s in schemes:
            btn = Gtk.Button(label=s)
            btn.add_css_class("flat")
            btn.connect("clicked", lambda b, name=s: self._on_select_scheme(name, popover))
            pop_box.append(btn)

        popover.set_child(pop_box)
        self.scheme_btn.set_popover(popover)
        color_row.add_suffix(self.scheme_btn)
        group.add(color_row)

        # 2. Classical Roman Workspaces Row
        roman_row = Adw.ActionRow(
            title="Classical Roman Workspaces",
            subtitle="Render workspace labels as Roman Numerals (I, II, III, IV)"
        )
        self.roman_switch = Gtk.Switch()
        self.roman_switch.set_active(backend.get("roman_workspaces", True))
        self.roman_switch.set_valign(Gtk.Align.CENTER)
        self.roman_switch.connect("notify::active", self._on_roman_toggle)
        roman_row.add_suffix(self.roman_switch)
        group.add(roman_row)

        # 3. Active Window Border Glow Row
        glow_row = Adw.ActionRow(
            title="Active Window Border Glow",
            subtitle="Display 2px #db9c5e gold border on focused windows"
        )
        self.glow_switch = Gtk.Switch()
        self.glow_switch.set_active(backend.get("border_glow", True))
        self.glow_switch.set_valign(Gtk.Align.CENTER)
        self.glow_switch.connect("notify::active", self._on_glow_toggle)
        glow_row.add_suffix(self.glow_switch)
        group.add(glow_row)

        # 4. Parallax Wallpaper Transition Row
        trans_row = Adw.ActionRow(
            title="Parallax Wallpaper Transition",
            subtitle="Smooth fade transition when switching artworks"
        )
        self.trans_switch = Gtk.Switch()
        self.trans_switch.set_active(backend.get("wallpaper_transition", True))
        self.trans_switch.set_valign(Gtk.Align.CENTER)
        self.trans_switch.connect("notify::active", self._on_trans_toggle)
        trans_row.add_suffix(self.trans_switch)
        group.add(trans_row)

    def _on_select_scheme(self, name, popover):
        self.scheme_btn.set_label(name)
        backend.set_color_scheme(name)
        popover.popdown()

    def _on_roman_toggle(self, switch, gparam):
        backend.set_roman_workspaces(switch.get_active())

    def _on_glow_toggle(self, switch, gparam):
        backend.set_border_glow(switch.get_active())

    def _on_trans_toggle(self, switch, gparam):
        backend.set("wallpaper_transition", switch.get_active())
