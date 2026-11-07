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

        self._build_dock_group()
        self._build_display_group()
        self._build_action_group()

    def _build_dock_group(self):
        group = Adw.PreferencesGroup()
        group.set_title("Desktop Application Dock")
        group.set_description("Floating desktop bottom dock with application pins and active indicators")
        self.append(group)

        # Enable Dock
        dock_row = Adw.SwitchRow(title="Enable Desktop Dock", subtitle="Display bottom application dock")
        dock_row.set_active(backend.get("rinauby.dock_enabled", True))
        dock_row.connect("notify::active", self._on_toggle_dock)
        group.add(dock_row)

        # Autohide Dock
        autohide_row = Adw.SwitchRow(title="Autohide Dock", subtitle="Automatically hide dock when windows overlap")
        autohide_row.set_active(backend.get("rinauby.dock_autohide", False))
        autohide_row.connect("notify::active", self._on_toggle_dock_autohide)
        group.add(autohide_row)

    def _on_toggle_dock(self, row, _param):
        is_active = row.get_active()
        backend.set("rinauby.dock_enabled", is_active)
        state_str = "enable" if is_active else "disable"
        subprocess.run(["quickshell", "-c", "rs", "ipc", "call", "main", "handleCommand", "dock", state_str, ""], stderr=subprocess.DEVNULL)
        subprocess.run(["quickshell", "-c", "rs", "ipc", "call", "rinaubybar", "reload"], stderr=subprocess.DEVNULL)

    def _on_toggle_dock_autohide(self, row, _param):
        backend.set("rinauby.dock_autohide", row.get_active())
        subprocess.run(["quickshell", "-c", "rs", "ipc", "call", "rinaubybar", "reload"], stderr=subprocess.DEVNULL)

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
