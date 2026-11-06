import subprocess
import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw
from backend import backend
from widgets import enhance_spin_row

class BarPage(Gtk.Box):
    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self.set_margin_top(14)
        self.set_margin_bottom(18)
        self.set_margin_start(16)
        self.set_margin_end(16)

        self._build_layout_group()
        self._build_content_group()
        self._build_action_group()

    def _build_layout_group(self):
        group = Adw.PreferencesGroup()
        group.set_title("Layout")
        self.append(group)

        # Bar Position
        pos_model = Gtk.StringList.new(["Top", "Bottom"])
        pos_row = Adw.ComboRow(title="Panel Position", model=pos_model)
        cur_pos = str(backend.get("waybar.position", "top")).lower()
        pos_row.set_selected(1 if cur_pos == "bottom" else 0)
        pos_row.connect("notify::selected", self._on_position_changed)
        group.add(pos_row)

        # Bar Height
        cur_height = int(backend.get("waybar.height", 34) or 34)
        cur_height = max(24, min(48, cur_height))
        height_adj = Gtk.Adjustment(value=cur_height, lower=24, upper=48, step_increment=2, page_increment=4)
        height_row = enhance_spin_row(Adw.SpinRow(
            title="Panel Height",
            adjustment=height_adj
        ))
        height_row.connect("notify::value", self._on_height_changed)
        group.add(height_row)

    def _on_position_changed(self, row, _param):
        pos = "bottom" if row.get_selected() == 1 else "top"
        backend.set("waybar.position", pos)
        self._on_reload_waybar()

    def _on_height_changed(self, row, _param):
        val = int(row.get_value())
        backend.set("waybar.height", val)
        self._on_reload_waybar()

    def _build_content_group(self):
        group = Adw.PreferencesGroup()
        group.set_title("Content &amp; Applets")
        self.append(group)

        # Motto rotator
        motto_row = Adw.SwitchRow(title="Rotate Humanism Mottos")
        motto_row.set_active(backend.get("waybar.rotate_quotes", True))
        motto_row.connect("notify::active", self._on_toggle_rotate_quotes)
        group.add(motto_row)

        # Artwork title when idle
        art_row = Adw.SwitchRow(title="Artwork Title When Idle")
        art_row.set_active(backend.get("waybar_show_title", True))
        art_row.connect("notify::active", self._on_toggle_show_title)
        group.add(art_row)

        # Roman numerals for workspaces
        roman_row = Adw.SwitchRow(title="Classical Roman Workspaces")
        roman_row.set_active(backend.get("rinauby.roman_workspaces", True))
        roman_row.connect("notify::active", self._on_toggle_roman_workspaces)
        group.add(roman_row)

        # Hardware telemetry
        telem_row = Adw.SwitchRow(title="Hardware Telemetry")
        telem_row.set_active(backend.get("waybar_telemetry", True))
        telem_row.connect("notify::active", self._on_toggle_telemetry)
        group.add(telem_row)

    def _on_toggle_rotate_quotes(self, row, _param):
        backend.set("waybar.rotate_quotes", row.get_active())
        self._on_reload_waybar()

    def _on_toggle_show_title(self, row, _param):
        backend.set("waybar_show_title", row.get_active())
        self._on_reload_waybar()

    def _on_toggle_roman_workspaces(self, row, _param):
        backend.set_roman_workspaces(row.get_active())
        self._on_reload_waybar()

    def _on_toggle_telemetry(self, row, _param):
        backend.set("waybar_telemetry", row.get_active())
        self._on_reload_waybar()

    def _build_action_group(self):
        group = Adw.PreferencesGroup()
        group.set_title("Maintenance")
        self.append(group)

        reload_row = Adw.ActionRow(title="Reload Waybar Panel")
        reload_btn = Gtk.Button(label="Reload")
        reload_btn.add_css_class("flat")
        reload_btn.set_valign(Gtk.Align.CENTER)
        reload_btn.connect("clicked", self._on_reload_waybar)
        reload_row.add_suffix(reload_btn)
        group.add(reload_row)

    def _on_reload_waybar(self, *_args):
        subprocess.run(["quickshell", "ipc", "call", "waybar", "reload"], stderr=subprocess.DEVNULL)
        subprocess.run(["pkill", "-RTMIN+8", "waybar"], stderr=subprocess.DEVNULL)
        subprocess.run(["pkill", "-USR2", "waybar"], stderr=subprocess.DEVNULL)
