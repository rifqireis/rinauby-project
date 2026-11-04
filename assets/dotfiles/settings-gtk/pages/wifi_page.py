import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw, GLib
from backend import backend

def get_signal_icon(signal: int, security: str) -> str:
    if signal >= 75:
        return "network-wireless-signal-excellent-symbolic"
    elif signal >= 50:
        return "network-wireless-signal-good-symbolic"
    elif signal >= 25:
        return "network-wireless-signal-ok-symbolic"
    return "network-wireless-signal-weak-symbolic"

class WifiPasswordDialog(Adw.Window):
    def __init__(self, parent_window, ssid: str, on_connect_cb):
        super().__init__()
        self.set_transient_for(parent_window)
        self.set_modal(True)
        self.set_default_size(360, 220)
        self.set_title(f"Connect to {ssid}")
        self.on_connect_cb = on_connect_cb
        self.ssid = ssid

        tb = Adw.ToolbarView()
        hb = Adw.HeaderBar()
        tb.add_top_bar(hb)

        cancel_btn = Gtk.Button(label="Cancel")
        cancel_btn.connect("clicked", lambda b: self.close())
        hb.pack_start(cancel_btn)

        connect_btn = Gtk.Button(label="Connect")
        connect_btn.add_css_class("suggested-action")
        connect_btn.connect("clicked", self._on_connect)
        hb.pack_end(connect_btn)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        box.set_margin_top(20)
        box.set_margin_bottom(20)
        box.set_margin_start(20)
        box.set_margin_end(20)

        group = Adw.PreferencesGroup()
        group.set_title("Security")
        self.pwd_entry = Adw.PasswordEntryRow(title="Password")
        self.pwd_entry.connect("entry-activated", lambda e: self._on_connect(None))
        group.add(self.pwd_entry)

        box.append(group)
        tb.set_content(box)
        self.set_content(tb)

    def _on_connect(self, button):
        pwd = self.pwd_entry.get_text()
        self.close()
        if self.on_connect_cb:
            self.on_connect_cb(self.ssid, pwd)

class WifiPage(Gtk.Box):
    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self.set_margin_top(14)
        self.set_margin_bottom(18)
        self.set_margin_start(16)
        self.set_margin_end(16)

        self.connected_rows = []
        self.available_rows = []

        self._build_header_group()
        self._build_connected_group()
        self._build_available_group()
        self._build_airplane_group()

        self.refresh_page()

    def _build_header_group(self):
        group = Adw.PreferencesGroup()
        self.append(group)

        self.wifi_switch_row = Adw.SwitchRow(title="Wi-Fi")
        self.wifi_switch_row.set_icon_name("network-wireless-symbolic")
        self.wifi_switch_row.set_active(backend.get_wifi_enabled())
        self.wifi_switch_row.connect("notify::active", self._on_wifi_toggled)

        self.scan_btn = Gtk.Button.new_from_icon_name("view-refresh-symbolic")
        self.scan_btn.add_css_class("flat")
        self.scan_btn.add_css_class("circular")
        self.scan_btn.set_tooltip_text("Scan Networks")
        self.scan_btn.connect("clicked", lambda b: self.refresh_page())
        self.wifi_switch_row.add_suffix(self.scan_btn)

        group.add(self.wifi_switch_row)

    def _build_connected_group(self):
        self.connected_group = Adw.PreferencesGroup()
        self.connected_group.set_title("Connected Network")
        self.append(self.connected_group)

    def _build_available_group(self):
        self.available_group = Adw.PreferencesGroup()
        self.available_group.set_title("Available Networks")
        self.append(self.available_group)

    def _build_airplane_group(self):
        group = Adw.PreferencesGroup()
        group.set_title("Additional Connection")
        self.append(group)

        self.airplane_row = Adw.SwitchRow(title="Airplane Mode")
        self.airplane_row.set_icon_name("airplane-mode-symbolic")
        self.airplane_row.set_active(backend.get_airplane_mode())
        self.airplane_row.connect("notify::active", self._on_airplane_toggled)
        group.add(self.airplane_row)

    def _on_wifi_toggled(self, row, param):
        enabled = row.get_active()
        backend.set_wifi_enabled(enabled)
        self.connected_group.set_sensitive(enabled)
        self.available_group.set_sensitive(enabled)
        self.scan_btn.set_sensitive(enabled)
        if enabled:
            GLib.timeout_add(800, self.refresh_page)

    def _on_airplane_toggled(self, row, param):
        backend.set_airplane_mode(row.get_active())
        self.wifi_switch_row.set_active(backend.get_wifi_enabled())

    def refresh_page(self):
        enabled = backend.get_wifi_enabled()
        self.wifi_switch_row.set_active(enabled)
        self.connected_group.set_sensitive(enabled)
        self.available_group.set_sensitive(enabled)
        self.scan_btn.set_sensitive(enabled)

        # Clear existing rows safely
        for r in self.connected_rows:
            try:
                self.connected_group.remove(r)
            except Exception:
                pass
        self.connected_rows.clear()

        for r in self.available_rows:
            try:
                self.available_group.remove(r)
            except Exception:
                pass
        self.available_rows.clear()

        networks = backend.get_wifi_networks() if enabled else []

        connected_net = next((n for n in networks if n.get("in_use")), None)

        if connected_net:
            conn_row = Adw.ActionRow(
                title=connected_net["ssid"],
                subtitle=f"Signal {connected_net['signal']}% • {connected_net['security']}"
            )
            conn_row.set_title_lines(0)
            conn_row.set_subtitle_lines(0)
            icon = Gtk.Image.new_from_icon_name(get_signal_icon(connected_net["signal"], connected_net["security"]))
            conn_row.add_prefix(icon)

            check = Gtk.Image.new_from_icon_name("object-select-symbolic")
            check.add_css_class("accent")
            conn_row.add_suffix(check)

            disc_btn = Gtk.Button(label="Disconnect")
            disc_btn.add_css_class("flat")
            disc_btn.set_valign(Gtk.Align.CENTER)
            disc_btn.connect("clicked", lambda b, s=connected_net["ssid"]: self._disconnect(s))
            conn_row.add_suffix(disc_btn)

            self.connected_group.add(conn_row)
            self.connected_rows.append(conn_row)
            self.connected_group.set_visible(True)
        else:
            self.connected_group.set_visible(False)

        # Populate available networks
        for net in networks:
            if net.get("in_use"):
                continue

            row = Adw.ActionRow(title=net["ssid"])
            row.set_title_lines(0)
            row.set_subtitle_lines(0)
            icon = Gtk.Image.new_from_icon_name(get_signal_icon(net["signal"], net["security"]))
            row.add_prefix(icon)

            if net["security"] and "--" not in net["security"]:
                lock = Gtk.Image.new_from_icon_name("channel-secure-symbolic")
                lock.set_opacity(0.6)
                row.add_suffix(lock)

            btn = Gtk.Button(label="Connect")
            btn.add_css_class("flat")
            btn.set_valign(Gtk.Align.CENTER)
            btn.connect("clicked", lambda b, n=net: self._on_connect_clicked(n))
            row.add_suffix(btn)

            self.available_group.add(row)
            self.available_rows.append(row)

        self.available_group.set_visible(len(self.available_rows) > 0)
        return False

    def _on_connect_clicked(self, net: dict):
        ssid = net["ssid"]
        security = net.get("security", "")
        if not security or "--" in security:
            backend.connect_wifi(ssid)
            GLib.timeout_add(1500, self.refresh_page)
        else:
            win = self.get_root()
            dialog = WifiPasswordDialog(win, ssid, self._connect_with_password)
            dialog.present()

    def _connect_with_password(self, ssid: str, password: str):
        backend.connect_wifi(ssid, password)
        GLib.timeout_add(2000, self.refresh_page)

    def _disconnect(self, ssid: str):
        backend.disconnect_wifi(ssid)
        GLib.timeout_add(1000, self.refresh_page)
