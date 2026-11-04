import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw
from backend import backend

PRESETS = [
    ("Discord", "discord --start-minimized"),
    ("Spotify", "spotify"),
    ("Telegram Desktop", "telegram-desktop -startintray"),
    ("Steam", "steam -silent"),
    ("Syncthing Tray", "syncthingtray"),
    ("OBS Studio", "obs --minimize-to-tray"),
    ("Clipboard Manager", "cliphist"),
]

class ExecsPage(Gtk.Box):
    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self.set_margin_top(14)
        self.set_margin_bottom(18)
        self.set_margin_start(16)
        self.set_margin_end(16)

        self.user_rows = []
        self.system_rows = []

        self._build_user_execs_group()
        self._build_system_execs_group()

    def refresh_page(self):
        self._refresh_user_rows()
        self._refresh_system_rows()

    # -----------------------------------------------------------------
    # 1. APLIKASI STARTUP PENGGUNA (custom/execs.lua)
    # -----------------------------------------------------------------
    def _build_user_execs_group(self):
        self.user_group = Adw.PreferencesGroup()
        self.user_group.set_title("Startup Applications")
        
        # Header bar button
        add_btn = Gtk.Button.new_from_icon_name("list-add-symbolic")
        add_btn.set_tooltip_text("Add New Startup Application")
        add_btn.add_css_class("flat")
        add_btn.connect("clicked", lambda b: self._show_add_dialog())
        self.user_group.set_header_suffix(add_btn)

        self.append(self.user_group)
        self._refresh_user_rows()

    def _refresh_user_rows(self):
        for row in self.user_rows:
            self.user_group.remove(row)
        self.user_rows.clear()

        execs = backend.get_execs()
        if not execs:
            empty_row = Adw.ActionRow(
                title="No Custom Startup Applications",
                subtitle="Click '+' at the top right to add a startup application"
            )
            empty_row.set_sensitive(False)
            self.user_group.add(empty_row)
            self.user_rows.append(empty_row)
            return

        for idx, item in enumerate(execs):
            row = Adw.ActionRow(
                title=item.get("name", "Application"),
                subtitle=item.get("command", "")
            )

            # Switch enable/disable
            sw = Gtk.Switch()
            sw.set_valign(Gtk.Align.CENTER)
            sw.set_active(item.get("enabled", True))
            sw.connect("notify::active", self._make_toggle_callback(idx))
            row.add_suffix(sw)

            # Action button box
            btn_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
            btn_box.set_valign(Gtk.Align.CENTER)

            # Edit button
            edit_btn = Gtk.Button.new_from_icon_name("document-edit-symbolic")
            edit_btn.add_css_class("flat")
            edit_btn.add_css_class("circular")
            edit_btn.set_tooltip_text("Edit Startup Application")
            edit_btn.connect("clicked", lambda b, i=idx: self._show_edit_dialog(i))
            btn_box.append(edit_btn)

            # Delete button
            del_btn = Gtk.Button.new_from_icon_name("user-trash-symbolic")
            del_btn.add_css_class("flat")
            del_btn.add_css_class("circular")
            del_btn.add_css_class("destructive-action")
            del_btn.set_tooltip_text("Remove from Startup")
            del_btn.connect("clicked", self._make_delete_callback(idx))
            btn_box.append(del_btn)

            row.add_suffix(btn_box)

            self.user_group.add(row)
            self.user_rows.append(row)

    def _make_toggle_callback(self, idx):
        def cb(sw, param):
            execs = backend.get_execs()
            if 0 <= idx < len(execs):
                execs[idx]["enabled"] = sw.get_active()
                backend.save_execs(execs)
        return cb

    def _make_delete_callback(self, idx):
        def cb(btn):
            execs = backend.get_execs()
            if 0 <= idx < len(execs):
                execs.pop(idx)
                backend.save_execs(execs)
                self._refresh_user_rows()
        return cb

    def _show_add_dialog(self):
        root_win = self.get_root()
        dialog = Adw.MessageDialog(
            transient_for=root_win,
            heading="Add Startup Application",
            body="Select a recommended preset or type a custom command:"
        )

        content_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        content_box.set_margin_top(8)

        # Preset dropdown
        preset_names = ["-- Select Recommended Preset --"] + [p[0] for p in PRESETS] + ["Custom (Manual)"]
        preset_model = Gtk.StringList.new(preset_names)
        preset_row = Adw.ComboRow(
            title="Quick Recommendations",
            model=preset_model
        )
        content_box.append(preset_row)

        # Name Entry
        name_entry = Adw.EntryRow(title="Application Name")
        content_box.append(name_entry)

        # Command Entry
        cmd_entry = Adw.EntryRow(title="Execution Command")
        content_box.append(cmd_entry)

        def on_preset_changed(row, param):
            sel = row.get_selected()
            if 1 <= sel <= len(PRESETS):
                name, cmd = PRESETS[sel - 1]
                name_entry.set_text(name)
                cmd_entry.set_text(cmd)

        preset_row.connect("notify::selected", on_preset_changed)

        dialog.set_extra_child(content_box)
        dialog.add_response("cancel", "Cancel")
        dialog.add_response("add", "Add")
        dialog.set_response_appearance("add", Adw.ResponseAppearance.SUGGESTED)

        def on_response(dlg, response):
            if response == "add":
                name = name_entry.get_text().strip() or "New Application"
                cmd = cmd_entry.get_text().strip()
                if cmd:
                    execs = backend.get_execs()
                    execs.append({
                        "name": name,
                        "command": cmd,
                        "enabled": True
                    })
                    backend.save_execs(execs)
                    self._refresh_user_rows()
            dlg.destroy()

        dialog.connect("response", on_response)
        dialog.present()

    def _show_edit_dialog(self, idx):
        execs = backend.get_execs()
        if not (0 <= idx < len(execs)):
            return
        item = execs[idx]

        root_win = self.get_root()
        dialog = Adw.MessageDialog(
            transient_for=root_win,
            heading="Edit Startup Application",
            body="Update the display name or command for this startup application:"
        )

        content_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        content_box.set_margin_top(8)

        name_entry = Adw.EntryRow(title="Application Name")
        name_entry.set_text(item.get("name", ""))
        content_box.append(name_entry)

        cmd_entry = Adw.EntryRow(title="Execution Command")
        cmd_entry.set_text(item.get("command", ""))
        content_box.append(cmd_entry)

        dialog.set_extra_child(content_box)
        dialog.add_response("cancel", "Cancel")
        dialog.add_response("save", "Save Changes")
        dialog.set_response_appearance("save", Adw.ResponseAppearance.SUGGESTED)

        def on_response(dlg, response):
            if response == "save":
                name = name_entry.get_text().strip() or "Aplikasi"
                cmd = cmd_entry.get_text().strip()
                if cmd:
                    current_execs = backend.get_execs()
                    if 0 <= idx < len(current_execs):
                        current_execs[idx]["name"] = name
                        current_execs[idx]["command"] = cmd
                        backend.save_execs(current_execs)
                        self._refresh_user_rows()
            dlg.destroy()

        dialog.connect("response", on_response)
        dialog.present()

    # -----------------------------------------------------------------
    # 2. LAYANAN INTI SISTEM (hyprland/execs.lua) - KONTROL NON-DESTRUKTIF
    # -----------------------------------------------------------------
    def _build_system_execs_group(self):
        self.sys_group = Adw.PreferencesGroup()
        self.sys_group.set_title("System Services")
        self.append(self.sys_group)
        self._refresh_system_rows()

    def _refresh_system_rows(self):
        for row in self.system_rows:
            self.sys_group.remove(row)
        self.system_rows.clear()

        base_services = backend.get_base_execs()
        for s in base_services:
            tag = s.get("id", "")
            row = Adw.ActionRow(
                title=s.get("title", ""),
                subtitle=f"{s.get('desc', '')} • {s.get('command', '')}"
            )

            # Badge status bawaan
            badge = Gtk.Label(label="Core")
            badge.add_css_class("dim-label")
            badge.set_valign(Gtk.Align.CENTER)
            row.add_suffix(badge)

            # Interactive toggle switch
            sw = Gtk.Switch()
            sw.set_valign(Gtk.Align.CENTER)
            sw.set_active(s.get("enabled", True))
            sw.connect("notify::active", self._make_base_toggle_callback(tag))
            row.add_suffix(sw)

            self.sys_group.add(row)
            self.system_rows.append(row)

    def _make_base_toggle_callback(self, tag):
        def cb(sw, param):
            backend.set_base_exec_enabled(tag, sw.get_active())
        return cb
