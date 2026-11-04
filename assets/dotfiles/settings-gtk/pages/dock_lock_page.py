import subprocess
import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw
from backend import backend

class LockPage(Gtk.Box):
    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self.set_margin_top(14)
        self.set_margin_bottom(18)
        self.set_margin_start(16)
        self.set_margin_end(16)

        self._build_display_group()
        self._build_action_group()

    def _build_display_group(self):
        group = Adw.PreferencesGroup()
        group.set_title("Lock Screen Appearance")
        self.append(group)

        # Blur lockscreen
        blur_row = Adw.SwitchRow(title="Background Blur")
        blur_row.set_active(backend.get("lock.blur.enable", True))
        blur_row.connect("notify::active", lambda r, p: backend.set("lock.blur.enable", r.get_active()))
        group.add(blur_row)

        # Center clock
        center_row = Adw.SwitchRow(title="Center Clock")
        center_row.set_active(backend.get("lock.centerClock", True))
        center_row.connect("notify::active", lambda r, p: backend.set("lock.centerClock", r.get_active()))
        group.add(center_row)

        # Show locked text
        locked_text_row = Adw.SwitchRow(title="Show Locked Status Text")
        locked_text_row.set_active(backend.get("lock.showLockedText", True))
        locked_text_row.connect("notify::active", lambda r, p: backend.set("lock.showLockedText", r.get_active()))
        group.add(locked_text_row)

        # Unlock keyring
        keyring_row = Adw.SwitchRow(title="Automatic Keyring Unlock")
        keyring_row.set_active(backend.get("lock.security.unlockKeyring", True))
        keyring_row.connect("notify::active", lambda r, p: backend.set("lock.security.unlockKeyring", r.get_active()))
        group.add(keyring_row)

    def _build_action_group(self):
        group = Adw.PreferencesGroup()
        group.set_title("Testing")
        self.append(group)

        test_row = Adw.ActionRow(title="Test Lock Screen Now")
        test_btn = Gtk.Button(label="Lock Screen")
        test_btn.add_css_class("flat")
        test_btn.set_valign(Gtk.Align.CENTER)
        test_btn.connect("clicked", lambda b: subprocess.Popen(["hyprlock"]))
        test_row.add_suffix(test_btn)
        group.add(test_row)

DockLockPage = LockPage
