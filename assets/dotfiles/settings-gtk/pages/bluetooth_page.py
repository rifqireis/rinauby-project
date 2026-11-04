import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw, GLib
from backend import backend

class BluetoothPage(Gtk.Box):
    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self.set_margin_top(14)
        self.set_margin_bottom(18)
        self.set_margin_start(16)
        self.set_margin_end(16)

        self.connected_rows = []
        self.paired_rows = []

        self._build_header_group()
        self._build_connected_group()
        self._build_paired_group()
        self._build_visibility_group()

        self.refresh_page()

    def _build_header_group(self):
        group = Adw.PreferencesGroup()
        self.append(group)

        self.bt_switch_row = Adw.SwitchRow(title="Bluetooth")
        self.bt_switch_row.set_icon_name("bluetooth-symbolic")
        self.bt_switch_row.set_active(backend.get_bluetooth_enabled())
        self.bt_switch_row.connect("notify::active", self._on_bt_toggled)

        self.refresh_btn = Gtk.Button.new_from_icon_name("view-refresh-symbolic")
        self.refresh_btn.add_css_class("flat")
        self.refresh_btn.add_css_class("circular")
        self.refresh_btn.set_tooltip_text("Scan Devices")
        self.refresh_btn.connect("clicked", lambda b: self.refresh_page())
        self.bt_switch_row.add_suffix(self.refresh_btn)

        group.add(self.bt_switch_row)

    def _build_connected_group(self):
        self.connected_group = Adw.PreferencesGroup()
        self.connected_group.set_title("Connected Devices")
        self.append(self.connected_group)

    def _build_paired_group(self):
        self.paired_group = Adw.PreferencesGroup()
        self.paired_group.set_title("Paired Devices")
        self.append(self.paired_group)

    def _build_visibility_group(self):
        group = Adw.PreferencesGroup()
        group.set_title("Visibility")
        self.append(group)

        self.disc_row = Adw.SwitchRow(title="Discoverable")
        self.disc_row.set_active(backend.get_bluetooth_discoverable())
        self.disc_row.connect("notify::active", lambda r, p: backend.set_bluetooth_discoverable(r.get_active()))
        group.add(self.disc_row)

    def _on_bt_toggled(self, row, param):
        enabled = row.get_active()
        backend.set_bluetooth_enabled(enabled)
        self.connected_group.set_sensitive(enabled)
        self.paired_group.set_sensitive(enabled)
        self.disc_row.set_sensitive(enabled)
        self.refresh_btn.set_sensitive(enabled)
        if enabled:
            GLib.timeout_add(1000, self.refresh_page)

    def refresh_page(self):
        enabled = backend.get_bluetooth_enabled()
        self.bt_switch_row.set_active(enabled)
        self.connected_group.set_sensitive(enabled)
        self.paired_group.set_sensitive(enabled)
        self.disc_row.set_sensitive(enabled)
        self.refresh_btn.set_sensitive(enabled)

        # Clear existing rows safely
        for r in self.connected_rows:
            try:
                self.connected_group.remove(r)
            except Exception:
                pass
        self.connected_rows.clear()

        for r in self.paired_rows:
            try:
                self.paired_group.remove(r)
            except Exception:
                pass
        self.paired_rows.clear()

        devices = backend.get_bluetooth_devices() if enabled else []

        for dev in devices:
            row = Adw.ActionRow(
                title=dev["name"],
                subtitle=dev["mac"]
            )
            row.set_title_lines(0)
            row.set_subtitle_lines(0)
            icon = Gtk.Image.new_from_icon_name(dev.get("icon", "bluetooth-symbolic"))
            row.add_prefix(icon)

            if dev.get("connected"):
                disc_btn = Gtk.Button(label="Disconnect")
                disc_btn.add_css_class("flat")
                disc_btn.set_valign(Gtk.Align.CENTER)
                disc_btn.connect("clicked", lambda b, m=dev["mac"]: self._disconnect(m))
                row.add_suffix(disc_btn)
                self.connected_group.add(row)
                self.connected_rows.append(row)
            else:
                conn_btn = Gtk.Button(label="Connect")
                conn_btn.add_css_class("flat")
                conn_btn.set_valign(Gtk.Align.CENTER)
                conn_btn.connect("clicked", lambda b, m=dev["mac"]: self._connect(m))
                row.add_suffix(conn_btn)

                del_btn = Gtk.Button.new_from_icon_name("user-trash-symbolic")
                del_btn.add_css_class("flat")
                del_btn.add_css_class("circular")
                del_btn.set_valign(Gtk.Align.CENTER)
                del_btn.set_tooltip_text("Forget Device")
                del_btn.connect("clicked", lambda b, m=dev["mac"]: self._remove(m))
                row.add_suffix(del_btn)

                self.paired_group.add(row)
                self.paired_rows.append(row)

        self.connected_group.set_visible(len(self.connected_rows) > 0)
        self.paired_group.set_visible(len(self.paired_rows) > 0)
        return False

    def _connect(self, mac: str):
        backend.connect_bluetooth(mac)
        GLib.timeout_add(1500, self.refresh_page)

    def _disconnect(self, mac: str):
        backend.disconnect_bluetooth(mac)
        GLib.timeout_add(1000, self.refresh_page)

    def _remove(self, mac: str):
        backend.remove_bluetooth(mac)
        GLib.timeout_add(1000, self.refresh_page)
