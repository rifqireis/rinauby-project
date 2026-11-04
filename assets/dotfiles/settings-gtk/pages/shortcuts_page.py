import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw

SHORTCUTS = [
    ("Super + Space / Super + D", "Application Launcher", "Rofi modal with Greek pillar logo and smooth blur"),
    ("Super + K / Ctrl + Super + T", "Wallpaper Selector", "Interactive gallery to choose classical Renaissance artworks"),
    ("Super + Backspace / Super + Esc", "Session Controls", "Power menu for Lock, Suspend, Logout, Reboot, and Shutdown"),
    ("Super + L", "Classical Lock Screen", "Hyprlock with golden aesthetics and Raphael backdrop"),
    ("Super + A", "Control Center", "SwayNC panel with media player, volume sliders, and notifications"),
    ("Super + Shift + S", "Area Screenshot", "Snip region to clipboard with golden notification toast"),
    ("Super + Print", "Screenshot Menu", "Quick menu for full screen, window, or snipping tool"),
    ("Media Keys (Vol / Bri)", "Wayland OSD Indicator", "Sleek bottom-centered pill capsules with Cairo rendering"),
]

class ShortcutsPage(Gtk.Box):
    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self.set_margin_top(14)
        self.set_margin_bottom(18)
        self.set_margin_start(16)
        self.set_margin_end(16)

        title_lbl = Gtk.Label(label="Keyboard Shortcuts")
        title_lbl.set_halign(Gtk.Align.START)
        title_lbl.add_css_class("page-header-title")
        self.append(title_lbl)

        scrolled = Gtk.ScrolledWindow()
        scrolled.set_vexpand(True)
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.append(scrolled)

        group = Adw.PreferencesGroup()
        scrolled.set_child(group)

        for combo, action, desc in SHORTCUTS:
            row = Adw.ActionRow(
                title=action,
                subtitle=desc
            )
            badge = Gtk.Label(label=combo)
            badge.add_css_class("pill-dropdown-button")
            badge.set_valign(Gtk.Align.CENTER)
            row.add_suffix(badge)
            group.add(row)
