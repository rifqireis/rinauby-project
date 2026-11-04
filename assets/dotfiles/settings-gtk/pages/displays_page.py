import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw
import subprocess

class DisplaysPage(Gtk.Box):
    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=12)

        title_lbl = Gtk.Label(label="Displays &amp; VirtualBox")
        title_lbl.set_halign(Gtk.Align.START)
        title_lbl.add_css_class("page-header-title")
        self.append(title_lbl)

        group = Adw.PreferencesGroup()
        self.append(group)

        # 1. Active Resolution
        res_row = Adw.ActionRow(
            title="Display Resolution",
            subtitle="Optimal 1920x1200 (16:10) for host &amp; VirtualBox guest environments"
        )
        badge_res = Gtk.Label(label="1920 x 1200 @ 60Hz")
        badge_res.add_css_class("pill-dropdown-button")
        badge_res.set_valign(Gtk.Align.CENTER)
        res_row.add_suffix(badge_res)
        group.add(res_row)

        # 2. VirtualBox Guest Additions
        vbox_row = Adw.ActionRow(
            title="VirtualBox Integration",
            subtitle="Seamless auto-resizing, shared clipboard, and bidirectional drag &amp; drop"
        )
        badge_vbox = Gtk.Label(label="Guest Additions Ready")
        badge_vbox.add_css_class("pill-dropdown-button")
        badge_vbox.set_valign(Gtk.Align.CENTER)
        vbox_row.add_suffix(badge_vbox)
        group.add(vbox_row)

        # 3. UI Scaling
        scale_row = Adw.ActionRow(
            title="Interface Scale",
            subtitle="Wayland display fractional scaling factor"
        )
        badge_scale = Gtk.Label(label="100% (1.0x)")
        badge_scale.add_css_class("pill-dropdown-button")
        badge_scale.set_valign(Gtk.Align.CENTER)
        scale_row.add_suffix(badge_scale)
        group.add(scale_row)
