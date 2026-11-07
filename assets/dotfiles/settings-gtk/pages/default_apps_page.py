import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
gi.require_version("Pango", "1.0")
from gi.repository import Gtk, Adw, Gio, GLib, GObject, Pango
from backend import backend

class AppItem(GObject.Object):
    def __init__(self, app_id, name, icon, exec_bin):
        super().__init__()
        self.app_id = app_id
        self.name = name
        self.icon = icon
        self.exec_bin = exec_bin

def _create_app_factory():
    factory = Gtk.SignalListItemFactory()

    def _setup(f, list_item):
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        box.set_margin_top(4)
        box.set_margin_bottom(4)
        box.set_margin_start(4)
        box.set_margin_end(4)

        img = Gtk.Image()
        img.set_pixel_size(20)

        lbl = Gtk.Label(xalign=0)
        lbl.set_ellipsize(Pango.EllipsizeMode.END)
        lbl.set_wrap(False)
        lbl.set_max_width_chars(24)

        box.append(img)
        box.append(lbl)
        list_item.set_child(box)

    def _bind(f, list_item):
        item = list_item.get_item()
        if not item:
            return
        box = list_item.get_child()
        img = box.get_first_child()
        lbl = img.get_next_sibling()
        lbl.set_text(item.name)

        icon_str = item.icon or "application-x-executable"
        try:
            gicon = Gio.Icon.new_for_string(icon_str)
            img.set_from_gicon(gicon)
        except Exception:
            img.set_from_icon_name("application-x-executable")

    factory.connect("setup", _setup)
    factory.connect("bind", _bind)
    return factory


class DefaultAppsPage(Gtk.Box):
    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self.set_margin_top(14)
        self.set_margin_bottom(18)
        self.set_margin_start(16)
        self.set_margin_end(16)

        self.is_loading = False
        self.cat_defs = {}
        self.groups_widgets = {}
        self.rows_widgets = {}

        self._build_category_groups()
        GLib.idle_add(lambda: self._load_data(force_reload=False) or False)

    def _build_category_groups(self):
        group_specs = [
            ("core", "Core Applications", "Terminal, web browser, and file manager"),
            ("productivity", "Documents & Text", "Word processor, text editor, code, spreadsheets, and presentations"),
            ("media", "Multimedia", "Photos, video playback, and music player"),
            ("utility", "Utilities", "Archive manager and email client")
        ]

        for idx, (gid, gtitle, gdesc) in enumerate(group_specs):
            group = Adw.PreferencesGroup()
            group.set_title(GLib.markup_escape_text(gtitle))
            
            # Tombol Segarkan di pojok kanan judul grup pertama
            if idx == 0:
                self.refresh_btn = Gtk.Button()
                self.refresh_btn.set_valign(Gtk.Align.CENTER)
                self.refresh_btn.add_css_class("flat")
                refresh_btn_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
                refresh_icon = Gtk.Image.new_from_icon_name("view-refresh-symbolic")
                self.refresh_label = Gtk.Label(label="Refresh")
                refresh_btn_box.append(refresh_icon)
                refresh_btn_box.append(self.refresh_label)
                self.refresh_btn.set_child(refresh_btn_box)
                self.refresh_btn.set_tooltip_text("Rescan installed applications on system")
                self.refresh_btn.connect("clicked", self._on_refresh_clicked)
                group.set_header_suffix(self.refresh_btn)

            self.append(group)
            self.groups_widgets[gid] = group

    def _on_refresh_clicked(self, btn):
        if hasattr(self, "refresh_label"):
            self.refresh_label.set_text("Scanning...")
        if hasattr(self, "refresh_btn"):
            self.refresh_btn.set_sensitive(False)
        self._load_data(force_reload=True)
        GLib.timeout_add(500, self._reset_refresh_button)

    def _reset_refresh_button(self):
        if hasattr(self, "refresh_label"):
            self.refresh_label.set_text("Refresh")
        if hasattr(self, "refresh_btn"):
            self.refresh_btn.set_sensitive(True)
        return False

    def refresh_page(self):
        self._load_data(force_reload=True)

    def _load_data(self, force_reload=False):
        self.is_loading = True
        data = backend.get_default_apps_data(force_reload=force_reload)

        # Hapus baris lama jika ada
        for row in self.rows_widgets.values():
            parent = row.get_parent()
            if parent:
                parent.remove(row)
        self.rows_widgets.clear()
        self.cat_defs.clear()

        for cat_entry in data:
            definition = cat_entry["definition"]
            cat_id = definition["id"]
            group_id = definition.get("group_id", "core")
            current_default_id = cat_entry["current_default_id"]
            apps = cat_entry["apps"]

            self.cat_defs[cat_id] = definition
            group = self.groups_widgets.get(group_id)
            if not group:
                continue

            row = Adw.ComboRow()
            row.set_title_lines(0)
            row.set_subtitle_lines(0)
            row.set_title(GLib.markup_escape_text(definition["title"]))
            row.set_subtitle(GLib.markup_escape_text(definition.get("subtitle", "")))

            prefix_icon = Gtk.Image.new_from_icon_name(definition.get("icon", "application-x-executable"))
            prefix_icon.set_pixel_size(20)
            row.add_prefix(prefix_icon)

            store = Gio.ListStore(item_type=AppItem)
            selected_idx = 0

            if not apps:
                placeholder = AppItem("", "No applications detected", "dialog-warning-symbolic", "")
                store.append(placeholder)
                row.set_sensitive(False)
                row.set_subtitle("No matching applications found")
            else:
                match_found = False
                for idx, app in enumerate(apps):
                    item = AppItem(app["id"], app["name"], app["icon"], app.get("exec", ""))
                    store.append(item)
                    if not match_found and (app["id"] == current_default_id or app["id"].split(".")[0] == current_default_id):
                        selected_idx = idx
                        match_found = True

                row.set_sensitive(True)

            row.set_model(store)
            row.set_factory(_create_app_factory())
            row.set_list_factory(_create_app_factory())

            if apps:
                row.set_selected(selected_idx)
                row.connect("notify::selected", self._on_app_selected, cat_id, store)

            group.add(row)
            self.rows_widgets[cat_id] = row

        self.is_loading = False

    def _on_app_selected(self, row, param, cat_id, store):
        if self.is_loading:
            return

        sel_idx = row.get_selected()
        if sel_idx < 0 or sel_idx >= store.get_n_items():
            return

        item = store.get_item(sel_idx)
        if not item or not item.app_id:
            return

        app_info = {
            "id": item.app_id,
            "name": item.name,
            "icon": item.icon,
            "exec": item.exec_bin
        }

        backend.set_default_app(cat_id, item.app_id, app_info)
