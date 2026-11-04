import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw
from backend import backend

class EnvPage(Gtk.Box):
    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self.set_margin_top(14)
        self.set_margin_bottom(18)
        self.set_margin_start(16)
        self.set_margin_end(16)

        self.env_data = backend.get_env()

        self._build_cursor_group()
        self._build_gpu_group()
        self._build_custom_vars_group()

    def refresh_page(self):
        self.env_data = backend.get_env()
        self._refresh_custom_vars()

    # -----------------------------------------------------------------
    # 1. KURSOR & ANTARMUKA
    # -----------------------------------------------------------------
    def _build_cursor_group(self):
        grp = Adw.PreferencesGroup()
        grp.set_title("Cursor &amp; Toolkits")
        self.append(grp)

        # Cursor size
        cur_size = self.env_data.get("xcursor_size", 24)
        cursor_adj = Gtk.Adjustment(value=float(cur_size), lower=16, upper=64, step_increment=4, page_increment=8)
        cursor_row = Adw.SpinRow(
            title="Cursor Size",
            adjustment=cursor_adj
        )
        cursor_row.connect("notify::value", self._on_cursor_size_changed)
        grp.add(cursor_row)

        # Electron Ozone Hint
        el_options = ["Automatic", "Force Wayland"]
        el_model = Gtk.StringList.new(el_options)
        el_row = Adw.ComboRow(
            title="Electron Platform",
            model=el_model
        )
        el_row.set_use_subtitle(True)
        cur_el = self.env_data.get("electron_platform", "auto")
        el_row.set_selected(0 if cur_el == "auto" else 1)
        el_row.connect("notify::selected", self._on_electron_changed)
        grp.add(el_row)

        # Moz Wayland
        moz_row = Adw.SwitchRow(
            title="Firefox Wayland Acceleration",
            subtitle="Enable pure Wayland backend for Firefox for power-efficient rendering"
        )
        moz_row.set_active(self.env_data.get("moz_wayland", True))
        moz_row.connect("notify::active", self._on_moz_changed)
        grp.add(moz_row)

    # -----------------------------------------------------------------
    # 2. AKSELERASI GPU
    # -----------------------------------------------------------------
    def _build_gpu_group(self):
        grp = Adw.PreferencesGroup()
        grp.set_title("GPU Acceleration")
        self.append(grp)

        drivers = [
            ("Intel Iris Xe / Gen 8+ (iHD)", "iHD"),
            ("AMD Radeon (radeonsi)", "radeonsi"),
            ("NVIDIA Proprietary (nvidia)", "nvidia"),
            ("System Auto Detection", "auto")
        ]
        driver_model = Gtk.StringList.new([d[0] for d in drivers])
        driver_row = Adw.ComboRow(
            title="Video Driver (LIBVA)",
            model=driver_model
        )
        driver_row.set_use_subtitle(True)

        cur_driver = self.env_data.get("libva_driver", "iHD")
        sel_idx = 0
        for idx, (_, val) in enumerate(drivers):
            if val == cur_driver:
                sel_idx = idx
                break
        driver_row.set_selected(sel_idx)

        def on_driver_changed(row, param):
            idx = row.get_selected()
            self.env_data["libva_driver"] = drivers[idx][1]
            backend.save_env(self.env_data)

        driver_row.connect("notify::selected", on_driver_changed)
        grp.add(driver_row)

    # -----------------------------------------------------------------
    # 3. VARIABEL KUSTOM
    # -----------------------------------------------------------------
    def _build_custom_vars_group(self):
        self.custom_grp = Adw.PreferencesGroup()
        self.custom_grp.set_title("Additional Session Variables")
        
        add_btn = Gtk.Button.new_from_icon_name("list-add-symbolic")
        add_btn.set_tooltip_text("Add Custom Variable")
        add_btn.add_css_class("flat")
        add_btn.connect("clicked", lambda b: self._show_add_var_dialog())
        self.custom_grp.set_header_suffix(add_btn)

        self.append(self.custom_grp)
        self.custom_rows = []
        self._refresh_custom_vars()

    def _refresh_custom_vars(self):
        for row in self.custom_rows:
            self.custom_grp.remove(row)
        self.custom_rows.clear()

        vars_list = self.env_data.get("custom_vars", [])
        if not vars_list:
            empty_row = Adw.ActionRow(
                title="No Custom Variables",
                subtitle="Click '+' to add a new environment session variable"
            )
            empty_row.set_sensitive(False)
            self.custom_grp.add(empty_row)
            self.custom_rows.append(empty_row)
            return

        for idx, v in enumerate(vars_list):
            row = Adw.ActionRow(
                title=v.get("key", ""),
                subtitle=v.get("val", "")
            )

            del_btn = Gtk.Button.new_from_icon_name("user-trash-symbolic")
            del_btn.set_valign(Gtk.Align.CENTER)
            del_btn.add_css_class("flat")
            del_btn.add_css_class("circular")
            del_btn.add_css_class("destructive-action")
            del_btn.set_tooltip_text("Delete Variable")
            del_btn.connect("clicked", self._make_delete_var_callback(idx))
            row.add_suffix(del_btn)

            self.custom_grp.add(row)
            self.custom_rows.append(row)

    def _make_delete_var_callback(self, idx):
        def cb(btn):
            vars_list = self.env_data.get("custom_vars", [])
            if 0 <= idx < len(vars_list):
                vars_list.pop(idx)
                backend.save_env(self.env_data)
                self._refresh_custom_vars()
        return cb

    def _show_add_var_dialog(self):
        root_win = self.get_root()
        dialog = Adw.MessageDialog(
            transient_for=root_win,
            heading="Add Session Variable",
            body="Enter variable name (KEY) and its value (VALUE):"
        )

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        box.set_margin_top(8)

        key_entry = Adw.EntryRow(title="Variable Name (KEY)")
        val_entry = Adw.EntryRow(title="Value (VALUE)")
        box.append(key_entry)
        box.append(val_entry)

        dialog.set_extra_child(box)
        dialog.add_response("cancel", "Cancel")
        dialog.add_response("add", "Add")
        dialog.set_response_appearance("add", Adw.ResponseAppearance.SUGGESTED)

        def on_response(dlg, response):
            if response == "add":
                k = key_entry.get_text().strip()
                v = val_entry.get_text().strip()
                if k:
                    vars_list = self.env_data.get("custom_vars", [])
                    vars_list.append({"key": k, "val": v})
                    self.env_data["custom_vars"] = vars_list
                    backend.save_env(self.env_data)
                    self._refresh_custom_vars()
            dlg.destroy()

        dialog.connect("response", on_response)
        dialog.present()

    # -----------------------------------------------------------------
    # CALLBACKS
    # -----------------------------------------------------------------
    def _on_cursor_size_changed(self, row, param):
        self.env_data["xcursor_size"] = int(row.get_value())
        backend.save_env(self.env_data)

    def _on_electron_changed(self, row, param):
        self.env_data["electron_platform"] = "auto" if row.get_selected() == 0 else "wayland"
        backend.save_env(self.env_data)

    def _on_moz_changed(self, row, param):
        self.env_data["moz_wayland"] = row.get_active()
        backend.save_env(self.env_data)
