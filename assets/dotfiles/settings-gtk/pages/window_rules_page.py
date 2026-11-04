import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw, Gio, GLib
from backend import backend
from app_detector import AppDetector, WORKFLOW_CATEGORIES
from widgets import NumericSlider, NumericSliderRow, enhance_spin_row

class RuleEditorDialog(Adw.Window):
    def __init__(self, parent_window, existing_rule=None, on_save_callback=None):
        super().__init__()
        self.set_transient_for(parent_window)
        self.set_modal(True)
        self.set_default_size(580, 680)
        self.on_save_callback = on_save_callback
        self.existing_rule = existing_rule

        self.is_edit = existing_rule is not None
        title_text = "Sunting Aturan Jendela" if self.is_edit else "Tambah Aturan Jendela"
        self.set_title(title_text)

        # Main Layout
        tb = Adw.ToolbarView()
        hb = Adw.HeaderBar()
        tb.add_top_bar(hb)

        cancel_btn = Gtk.Button(label="Cancel")
        cancel_btn.connect("clicked", lambda b: self.close())
        hb.pack_start(cancel_btn)

        save_btn = Gtk.Button(label="Save")
        save_btn.add_css_class("suggested-action")
        save_btn.connect("clicked", self._on_save_clicked)
        hb.pack_end(save_btn)

        content_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        content_box.set_margin_top(16)
        content_box.set_margin_bottom(24)
        content_box.set_margin_start(20)
        content_box.set_margin_end(20)

        clamp = Adw.Clamp(maximum_size=560)
        clamp.set_child(content_box)

        scrolled = Gtk.ScrolledWindow()
        scrolled.set_vexpand(True)
        scrolled.set_child(clamp)
        tb.set_content(scrolled)
        self.set_content(tb)

        # Source Switcher (Terpasang vs Kustom)
        source_group = Adw.PreferencesGroup()
        content_box.append(source_group)

        self.source_row = Adw.ComboRow(
            title="Application Source"
        )
        self.source_row.set_use_subtitle(True)
        self.source_model = Gtk.StringList.new([
            "Choose from Installed Apps",
            "Manual Custom Rule"
        ])
        self.source_row.set_model(self.source_model)
        source_group.add(self.source_row)

        # --- CONTAINER 1: Aplikasi Terpasang ---
        self.installed_group = Adw.PreferencesGroup()
        self.installed_group.set_title("Desktop Application Selection")
        content_box.append(self.installed_group)

        # Workflow Filter
        self.cat_filter_row = Adw.ComboRow(
            title="Application Category"
        )
        self.cat_filter_row.set_use_subtitle(True)
        self.cat_keys = ["all", "development", "internet", "productivity", "multimedia", "system", "gaming"]
        self.cat_labels = [
            "All Applications",
            "Development & Code",
            "Internet & Communication",
            "Productivity & Documents",
            "Multimedia & Graphics",
            "System & Utilities",
            "Games & Entertainment"
        ]
        self.cat_filter_row.set_model(Gtk.StringList.new(self.cat_labels))
        self.cat_filter_row.connect("notify::selected", self._on_category_filter_changed)
        self.installed_group.add(self.cat_filter_row)

        # Search Entry for App
        self.app_search_entry = Gtk.SearchEntry()
        self.app_search_entry.set_placeholder_text("Type to search installed applications...")
        self.app_search_entry.connect("search-changed", self._on_app_search_changed)
        self.installed_group.add(self.app_search_entry)

        # App Dropdown Row
        self.app_row = Adw.ComboRow(title="Selected Application")
        self.app_row.connect("notify::selected", lambda r, p: self._update_class_hint(r.get_selected()))
        self.installed_group.add(self.app_row)

        # Detected Class Preview
        self.class_hint_row = Adw.ActionRow(
            title="Detected Window Class",
            subtitle="Class pattern mapped to Hyprland window rule"
        )
        self.installed_group.add(self.class_hint_row)

        # --- CONTAINER 2: Kustom Manual ---
        self.custom_group = Adw.PreferencesGroup()
        self.custom_group.set_title("Custom Rule Identity")
        content_box.append(self.custom_group)

        self.custom_name_row = Adw.EntryRow(title="Rule Label Name")
        self.custom_name_row.set_text(existing_rule.get("name", "") if existing_rule else "")
        self.custom_group.add(self.custom_name_row)

        self.custom_class_row = Adw.EntryRow(title="Window Class (Class Regex)")
        self.custom_class_row.set_text(existing_rule.get("class", "") if existing_rule else "")
        self.custom_group.add(self.custom_class_row)

        class_example_row = Adw.ActionRow(
            title="Example Class Patterns",
            subtitle="^(Spotify)$ atau ^(dev\\.warp\\.Warp)$ atau ^steam_app_.*$\n(Cek kelas jendela aktif lewat perintah 'hyprctl activewindow')"
        )
        self.custom_group.add(class_example_row)

        self.custom_title_row = Adw.EntryRow(title="Window Title (Title Regex - Optional)")
        self.custom_title_row.set_text(existing_rule.get("title", "") if existing_rule else "")
        self.custom_group.add(self.custom_title_row)

        title_example_row = Adw.ActionRow(
            title="Example Title Patterns",
            subtitle="^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture).*$ atau ^(Pilih Berkas).*$\n(Kosongkan jika ingin berlaku ke semua jendela dari aplikasi ini)"
        )
        self.custom_group.add(title_example_row)

        self.custom_cat_row = Adw.ComboRow(title="Workflow Category")
        self.custom_cat_row.set_use_subtitle(True)
        self.custom_cat_keys = ["development", "internet", "productivity", "multimedia", "system", "gaming", "custom"]
        self.custom_cat_labels = [
            "Development & Code",
            "Internet & Communication",
            "Productivity & Documents",
            "Multimedia & Graphics",
            "System & Utilities",
            "Games & Entertainment",
            "Custom Rule"
        ]
        self.custom_cat_row.set_model(Gtk.StringList.new(self.custom_cat_labels))
        self.custom_group.add(self.custom_cat_row)

        # --- KONFIGURASI TATA LETAK & MODE ---
        mode_group = Adw.PreferencesGroup()
        mode_group.set_title("Window Geometry &amp; Mode")
        content_box.append(mode_group)

        self.mode_row = Adw.ComboRow(
            title="Display Mode"
        )
        self.mode_row.set_use_subtitle(True)
        self.mode_row.set_model(Gtk.StringList.new([
            "Floating Mode",
            "Automatic Tiling"
        ]))
        self.mode_row.connect("notify::selected", self._on_mode_changed)
        mode_group.add(self.mode_row)

        # Floating settings (Slider interaktif + input angka langsung)
        self.size_w_adj = Gtk.Adjustment(value=60, lower=20, upper=100, step_increment=1, page_increment=10)
        self.size_w_row = NumericSliderRow(
            title="Screen Width (%)",
            adjustment=self.size_w_adj,
            suffix="%",
            min_width=170
        )
        mode_group.add(self.size_w_row)

        self.size_h_adj = Gtk.Adjustment(value=60, lower=20, upper=100, step_increment=1, page_increment=10)
        self.size_h_row = NumericSliderRow(
            title="Screen Height (%)",
            adjustment=self.size_h_adj,
            suffix="%",
            min_width=170
        )
        mode_group.add(self.size_h_row)

        self.center_row = Adw.SwitchRow(
            title="Center on Screen"
        )
        self.center_row.set_active(True)
        mode_group.add(self.center_row)

        self.aspect_row = Adw.SwitchRow(
            title="Lock Aspect Ratio"
        )
        self.aspect_row.set_active(False)
        mode_group.add(self.aspect_row)

        # --- EFEK VISUAL & TRANSPARANSI ---
        visual_group = Adw.PreferencesGroup()
        visual_group.set_title("Visual Effects")
        content_box.append(visual_group)

        # Efek Buram (Blur) Slider 0 - 100% dengan input angka interaktif
        self.blur_adj = Gtk.Adjustment(
            value=0.0,
            lower=0.0,
            upper=100.0,
            step_increment=1.0,
            page_increment=10.0
        )
        self.blur_slider = NumericSlider(
            adjustment=self.blur_adj,
            suffix="%",
            zero_label="Off",
            min_width=170
        )
        self.blur_scale = self.blur_slider.scale

        self.blur_row = Adw.ActionRow(
            title="Transparency Blur"
        )
        self.blur_switch = Gtk.Switch()
        self.blur_switch.set_valign(Gtk.Align.CENTER)
        self.blur_row.add_prefix(self.blur_switch)
        self.blur_row.add_suffix(self.blur_slider)
        self.blur_switch.connect("notify::active", self._on_blur_switch_toggled)
        self.blur_slider.connect("value-changed", self._on_blur_scale_changed)
        visual_group.add(self.blur_row)

        # Kustomisasi Transparansi Expander
        self.opacity_expander = Adw.ExpanderRow(
            title="Customize Opacity"
        )
        self.opacity_expander.set_show_enable_switch(True)
        self.opacity_expander.set_enable_expansion(False)
        visual_group.add(self.opacity_expander)

        # Pilihan Mode Transparansi
        self.opacity_mode_row = Adw.ComboRow(
            title="Opacity Mode"
        )
        self.opacity_mode_row.set_model(Gtk.StringList.new([
            "Slider Opasitas Kustom (0 - 100%)",
            "Paksa Pekat Penuh (Opaque 100%)"
        ]))
        self.opacity_mode_row.connect("notify::selected", self._on_opacity_mode_changed)
        self.opacity_expander.add_row(self.opacity_mode_row)

        # Slider Opasitas Jendela Aktif (0 - 100%) dengan input angka interaktif
        self.opacity_act_adj = Gtk.Adjustment(
            value=88.0,
            lower=0.0,
            upper=100.0,
            step_increment=1.0,
            page_increment=10.0
        )
        self.opacity_act_slider = NumericSlider(
            adjustment=self.opacity_act_adj,
            suffix="%",
            min_width=170
        )
        self.opacity_act_scale = self.opacity_act_slider.scale

        self.opacity_act_row = Adw.ActionRow(
            title="Active Window Opacity",
            subtitle="Opacity level when window is focused (0% = transparent, 100% = opaque)"
        )
        self.opacity_act_row.add_suffix(self.opacity_act_slider)
        self.opacity_expander.add_row(self.opacity_act_row)

        # Slider Opasitas Jendela Pasif (0 - 100%) dengan input angka interaktif
        self.opacity_inact_adj = Gtk.Adjustment(
            value=85.0,
            lower=0.0,
            upper=100.0,
            step_increment=1.0,
            page_increment=10.0
        )
        self.opacity_inact_slider = NumericSlider(
            adjustment=self.opacity_inact_adj,
            suffix="%",
            min_width=170
        )
        self.opacity_inact_scale = self.opacity_inact_slider.scale

        self.opacity_inact_row = Adw.ActionRow(
            title="Inactive Window Opacity",
            subtitle="Opacity level when window is inactive in background"
        )
        self.opacity_inact_row.add_suffix(self.opacity_inact_slider)
        self.opacity_expander.add_row(self.opacity_inact_row)

        # --- PERILAKU & TAMPILAN LANJUTAN ---
        behavior_group = Adw.PreferencesGroup()
        behavior_group.set_title("Advanced Behavior &amp; Styling")
        behavior_group.set_description("Workspace pinning, shadow, corner rounding, and border adjustments")
        content_box.append(behavior_group)

        # Sematkan di Semua Ruang Kerja (Pin)
        self.pin_row = Adw.SwitchRow(
            title="Pin Across All Workspaces",
            subtitle="Keep window visible across all workspaces (ideal for notes or calculators)"
        )
        self.pin_row.set_active(False)
        behavior_group.add(self.pin_row)

        # Redupkan Layar Sekeliling (Dim Around)
        self.dim_row = Adw.SwitchRow(
            title="Dim Background Around Window",
            subtitle="Dim background surroundings when this window is focused"
        )
        self.dim_row.set_active(False)
        behavior_group.add(self.dim_row)

        # Hilangkan Bayangan Jendela (No Shadow)
        self.no_shadow_row = Adw.SwitchRow(
            title="Disable Window Shadow",
            subtitle="Turn off drop shadow effects for this application"
        )
        self.no_shadow_row.set_active(False)
        behavior_group.add(self.no_shadow_row)

        # Sudut Lengkung Khusus Expander
        self.rounding_expander = Adw.ExpanderRow(
            title="Custom Corner Rounding",
            subtitle="Override corner rounding radius (0 for sharp right angles)"
        )
        self.rounding_expander.set_show_enable_switch(True)
        self.rounding_expander.set_enable_expansion(False)
        behavior_group.add(self.rounding_expander)

        self.rounding_adj = Gtk.Adjustment(value=10, lower=0, upper=20, step_increment=1, page_increment=2)
        self.rounding_row = NumericSliderRow(
            title="Corner Radius (px)",
            subtitle="0 = sudut siku-siku tajam, 10 = membulat standar, 20 = batas maksimal Hyprland",
            adjustment=self.rounding_adj,
            suffix=" px",
            min_width=150
        )
        self.rounding_expander.add_row(self.rounding_row)

        # Garis Batas Khusus Expander
        self.border_expander = Adw.ExpanderRow(
            title="Custom Border Size",
            subtitle="Override border thickness (0 for borderless)"
        )
        self.border_expander.set_show_enable_switch(True)
        self.border_expander.set_enable_expansion(False)
        behavior_group.add(self.border_expander)

        self.border_adj = Gtk.Adjustment(value=2, lower=0, upper=10, step_increment=1, page_increment=2)
        self.border_row = NumericSliderRow(
            title="Border Width (px)",
            subtitle="0 = tanpa garis border, 2 = tebal standar",
            adjustment=self.border_adj,
            suffix=" px",
            min_width=150
        )
        self.border_expander.add_row(self.border_row)

        # Populate apps
        self.all_apps = AppDetector.get_all_apps()
        self.filtered_apps = []
        self._update_app_dropdown()

        # Wire up source switcher
        self.source_row.connect("notify::selected", self._on_source_changed)

        # Load existing rule if editing
        if self.existing_rule:
            is_cust = self.existing_rule.get("is_custom", True)
            self.source_row.set_selected(1 if is_cust else 0)
            mode_val = self.existing_rule.get("mode", "float")
            self.mode_row.set_selected(0 if mode_val == "float" else 1)
            self.size_w_adj.set_value(float(self.existing_rule.get("size_w", 0.60)) * 100)
            self.size_h_adj.set_value(float(self.existing_rule.get("size_h", 0.60)) * 100)
            self.center_row.set_active(bool(self.existing_rule.get("center", True)))
            self.aspect_row.set_active(bool(self.existing_rule.get("keep_aspect_ratio", False)))

            # Visual
            b_active = bool(self.existing_rule.get("blur", False))
            b_strength = float(self.existing_rule.get("blur_strength", 60.0 if b_active else 0.0))
            if not b_active:
                b_strength = 0.0
            self._blur_syncing = True
            self.blur_adj.set_value(b_strength)
            self.blur_switch.set_active(b_active)
            self._blur_syncing = False

            has_op = bool(self.existing_rule.get("custom_opacity", False))
            self.opacity_expander.set_enable_expansion(has_op)
            op_mode = self.existing_rule.get("opacity_mode", "custom")
            self.opacity_mode_row.set_selected(1 if op_mode == "opaque" else 0)
            self.opacity_act_adj.set_value(float(self.existing_rule.get("opacity_active", 0.88)) * 100.0)
            self.opacity_inact_adj.set_value(float(self.existing_rule.get("opacity_inactive", 0.85)) * 100.0)
            self._on_opacity_mode_changed(self.opacity_mode_row, None)

            # Behavior
            self.pin_row.set_active(bool(self.existing_rule.get("pin", False)))
            self.dim_row.set_active(bool(self.existing_rule.get("dim_around", False)))
            self.no_shadow_row.set_active(bool(self.existing_rule.get("no_shadow", False)))

            # Rounding & Border
            has_rnd = bool(self.existing_rule.get("custom_rounding", False))
            self.rounding_expander.set_enable_expansion(has_rnd)
            self.rounding_adj.set_value(int(self.existing_rule.get("rounding", 10)))

            has_bdr = bool(self.existing_rule.get("custom_border", False))
            self.border_expander.set_enable_expansion(has_bdr)
            self.border_adj.set_value(int(self.existing_rule.get("border_size", 2)))

            cat = self.existing_rule.get("category", "custom")
            if cat in self.custom_cat_keys:
                self.custom_cat_row.set_selected(self.custom_cat_keys.index(cat))

            if not is_cust:
                target_name = self.existing_rule.get("name", "").lower()
                target_icon = self.existing_rule.get("icon", "")
                target_class = self.existing_rule.get("class", "").strip("^()$")
                matched_idx = -1
                for idx, a in enumerate(self.filtered_apps):
                    if (a["name"].lower() == target_name or
                        (target_icon and a["icon"] == target_icon) or
                        (target_class and target_class in a["detected_class"])):
                        matched_idx = idx
                        break
                if matched_idx >= 0:
                    self.app_row.set_selected(matched_idx)
                    self._update_class_hint(matched_idx)
        else:
            self.source_row.set_selected(0)
            self.mode_row.set_selected(0)
            self._blur_syncing = True
            self.blur_adj.set_value(0.0)
            self.blur_switch.set_active(False)
            self._blur_syncing = False
            self.opacity_act_adj.set_value(88.0)
            self.opacity_inact_adj.set_value(85.0)
            self._on_opacity_mode_changed(self.opacity_mode_row, None)

        self._on_source_changed(self.source_row, None)
        self._on_mode_changed(self.mode_row, None)

    def _on_source_changed(self, row, param):
        is_custom = row.get_selected() == 1
        self.installed_group.set_visible(not is_custom)
        self.custom_group.set_visible(is_custom)
        if is_custom:
            sel_idx = self.app_row.get_selected()
            if 0 <= sel_idx < len(self.filtered_apps):
                app = self.filtered_apps[sel_idx]
                if not self.custom_name_row.get_text().strip():
                    self.custom_name_row.set_text(app["name"])
                if not self.custom_class_row.get_text().strip():
                    self.custom_class_row.set_text(f"^({app['detected_class']})$")
                cat = app.get("workflow_category", "custom")
                if cat in self.custom_cat_keys:
                    self.custom_cat_row.set_selected(self.custom_cat_keys.index(cat))

    def _on_mode_changed(self, row, param):
        is_float = row.get_selected() == 0
        self.size_w_row.set_visible(is_float)
        self.size_h_row.set_visible(is_float)
        self.center_row.set_visible(is_float)
        self.aspect_row.set_visible(is_float)

    def _on_opacity_mode_changed(self, row, param):
        is_custom_val = row.get_selected() == 0
        self.opacity_act_row.set_visible(is_custom_val)
        self.opacity_inact_row.set_visible(is_custom_val)

    def _on_blur_switch_toggled(self, switch, param):
        if getattr(self, "_blur_syncing", False):
            return
        self._blur_syncing = True
        if switch.get_active():
            if self.blur_adj.get_value() <= 0:
                self.blur_adj.set_value(60.0)
        else:
            self.blur_adj.set_value(0.0)
        self._blur_syncing = False

    def _on_blur_scale_changed(self, scale):
        if getattr(self, "_blur_syncing", False):
            return
        val = scale.get_value()
        self._blur_syncing = True
        self.blur_switch.set_active(val > 0)
        self._blur_syncing = False

    def _on_category_filter_changed(self, row, param):
        self._update_app_dropdown()

    def _on_app_search_changed(self, entry):
        self._update_app_dropdown()

    def _update_app_dropdown(self):
        cat_idx = self.cat_filter_row.get_selected()
        selected_cat = self.cat_keys[cat_idx] if cat_idx < len(self.cat_keys) else "all"
        search_query = self.app_search_entry.get_text().lower().strip()

        filtered = []
        for a in self.all_apps:
            if selected_cat != "all" and a["workflow_category"] != selected_cat:
                continue
            if search_query:
                if search_query not in a["name"].lower() and search_query not in a["detected_class"].lower():
                    continue
            filtered.append(a)

        self.filtered_apps = filtered
        app_names = [f"{a['name']} ({a['detected_class']})" for a in filtered]
        if not app_names:
            app_names = ["(Tidak ada aplikasi cocok)"]

        self.app_row.set_model(Gtk.StringList.new(app_names))
        if filtered:
            self.app_row.set_selected(0)
            self._update_class_hint(0)
        else:
            self.class_hint_row.set_subtitle("-")

    def _update_class_hint(self, index):
        if 0 <= index < len(self.filtered_apps):
            app = self.filtered_apps[index]
            self.class_hint_row.set_subtitle(f"^({app['detected_class']})$")
            if self.source_row.get_selected() == 0:
                self.custom_name_row.set_text(app["name"])
                self.custom_class_row.set_text(f"^({app['detected_class']})$")
                cat = app.get("workflow_category", "custom")
                if cat in self.custom_cat_keys:
                    self.custom_cat_row.set_selected(self.custom_cat_keys.index(cat))

    def _on_save_clicked(self, button):
        is_custom = self.source_row.get_selected() == 1
        mode = "float" if self.mode_row.get_selected() == 0 else "tile"
        size_w = round(self.size_w_adj.get_value() / 100.0, 2)
        size_h = round(self.size_h_adj.get_value() / 100.0, 2)
        center = self.center_row.get_active()
        keep_aspect_ratio = self.aspect_row.get_active()

        # Visual
        blur = self.blur_switch.get_active() or (self.blur_adj.get_value() > 0)
        blur_strength = int(round(self.blur_adj.get_value()))
        custom_opacity = self.opacity_expander.get_enable_expansion()
        opacity_mode = "opaque" if self.opacity_mode_row.get_selected() == 1 else "custom"
        opacity_active = round(self.opacity_act_adj.get_value() / 100.0, 2)
        opacity_inactive = round(self.opacity_inact_adj.get_value() / 100.0, 2)

        # Behavior
        pin = self.pin_row.get_active()
        dim_around = self.dim_row.get_active()
        no_shadow = self.no_shadow_row.get_active()

        # Rounding & Border
        custom_rounding = self.rounding_expander.get_enable_expansion()
        rounding_val = max(0, min(20, int(self.rounding_adj.get_value())))
        custom_border = self.border_expander.get_enable_expansion()
        border_val = max(0, min(20, int(self.border_adj.get_value())))

        if is_custom:
            name = self.custom_name_row.get_text().strip()
            cls = self.custom_class_row.get_text().strip()
            title = self.custom_title_row.get_text().strip()
            cat_idx = self.custom_cat_row.get_selected()
            category = self.custom_cat_keys[cat_idx] if cat_idx < len(self.custom_cat_keys) else "custom"
            if not name:
                name = cls if cls else "Aturan Kustom"
            icon = "preferences-other-symbolic"
        else:
            sel_idx = self.app_row.get_selected()
            if not self.filtered_apps or sel_idx >= len(self.filtered_apps):
                self.close()
                return
            app = self.filtered_apps[sel_idx]
            name = app["name"]
            cls = f"^({app['detected_class']})$"
            title = ""
            category = app["workflow_category"]
            icon = app["icon"]

        rule_data = {
            "id": self.existing_rule.get("id") if self.existing_rule else f"rule_{GLib.uuid_string_random()[:8]}",
            "name": name,
            "category": category,
            "class": cls,
            "title": title,
            "mode": mode,
            "size_w": size_w,
            "size_h": size_h,
            "center": center,
            "keep_aspect_ratio": keep_aspect_ratio,
            "blur": blur,
            "blur_strength": blur_strength,
            "custom_opacity": custom_opacity,
            "opacity_mode": opacity_mode,
            "opacity_active": opacity_active,
            "opacity_inactive": opacity_inactive,
            "pin": pin,
            "dim_around": dim_around,
            "no_shadow": no_shadow,
            "custom_rounding": custom_rounding,
            "rounding": rounding_val,
            "custom_border": custom_border,
            "border_size": border_val,
            "icon": icon,
            "is_custom": is_custom
        }

        if self.on_save_callback:
            self.on_save_callback(rule_data)
        self.close()


class WindowRulesPage(Gtk.Box):
    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self.set_margin_top(14)
        self.set_margin_bottom(18)
        self.set_margin_start(16)
        self.set_margin_end(16)

        self.current_category_filter = "all"
        self.search_text = ""

        self._build_global_group()
        self._build_rules_group()

    def _build_global_group(self):
        group = Adw.PreferencesGroup()
        group.set_title("Global Tiling Behavior")
        group.set_description("Base workspace layout behavior and active window indicators")
        self.append(group)

        # New workspace behavior
        self.behavior_row = Adw.ComboRow(
            title="New Workspace Behavior"
        )
        self.behavior_row.set_use_subtitle(True)
        self.behavior_row.set_model(Gtk.StringList.new([
            "Automatic Tiling",
            "Floating Mode"
        ]))
        current_behavior = backend.get("hyprland.tiling.newWorkspaceBehavior", "tiled")
        self.behavior_row.set_selected(1 if current_behavior == "floating" else 0)
        self.behavior_row.connect("notify::selected", self._on_behavior_changed)
        group.add(self.behavior_row)

        # Active hint
        self.active_hint_row = Adw.SwitchRow(
            title="Active Window Glow",
            subtitle="Accent color on focused window borders"
        )
        self.active_hint_row.set_active(backend.get("hyprland.tiling.activeHint", True))
        self.active_hint_row.connect("notify::active", self._on_active_hint_changed)
        group.add(self.active_hint_row)

    def _build_rules_group(self):
        self.rules_group = Adw.PreferencesGroup()
        self.rules_group.set_title("Application-Specific Rules")
        
        # Tombol Segarkan di pojok kanan judul grup (header suffix)
        self.refresh_btn = Gtk.Button()
        self.refresh_btn.set_valign(Gtk.Align.CENTER)
        self.refresh_btn.add_css_class("flat")
        refresh_btn_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        refresh_icon = Gtk.Image.new_from_icon_name("view-refresh-symbolic")
        self.refresh_label = Gtk.Label(label="Refresh")
        refresh_btn_box.append(refresh_icon)
        refresh_btn_box.append(self.refresh_label)
        self.refresh_btn.set_child(refresh_btn_box)
        self.refresh_btn.set_tooltip_text("Pindai ulang daftar aplikasi terpasang di sistem")
        self.refresh_btn.connect("clicked", self._on_refresh_clicked)
        self.rules_group.set_header_suffix(self.refresh_btn)

        self.append(self.rules_group)

        # Header Box with Add Button
        header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        header_box.set_margin_bottom(8)

        # Category Filter DropDown
        cat_labels = [
            "Semua Kategori",
            "Development & Code",
            "Internet & Communication",
            "Productivity & Documents",
            "Multimedia & Graphics",
            "System & Utilities",
            "Games & Entertainment",
            "Aturan Kustom"
        ]
        self.cat_filter_keys = ["all", "development", "internet", "productivity", "multimedia", "system", "gaming", "custom"]
        self.cat_dropdown = Gtk.DropDown.new_from_strings(cat_labels)
        self.cat_dropdown.connect("notify::selected", self._on_filter_dropdown_changed)
        header_box.append(self.cat_dropdown)

        # Search Entry
        self.search_entry = Gtk.SearchEntry()
        self.search_entry.set_hexpand(True)
        self.search_entry.set_placeholder_text("Search window rules...")
        self.search_entry.connect("search-changed", self._on_search_changed)
        header_box.append(self.search_entry)

        # Add Button
        add_btn = Gtk.Button.new_from_icon_name("list-add-symbolic")
        add_btn.add_css_class("suggested-action")
        add_btn.set_tooltip_text("Tambah Aturan Aplikasi Baru")
        add_btn.connect("clicked", lambda b: self._open_rule_editor(None))
        header_box.append(add_btn)

        self.rules_group.add(header_box)

        # Boxed List for Rules
        self.rules_list_box = Gtk.ListBox()
        self.rules_list_box.add_css_class("boxed-list")
        self.rules_list_box.set_selection_mode(Gtk.SelectionMode.NONE)
        self.rules_group.add(self.rules_list_box)

        self._refresh_rules_list()

    def refresh_page(self):
        AppDetector.get_all_apps(force_reload=True)
        self._refresh_rules_list()

    def _on_refresh_clicked(self, btn):
        if hasattr(self, "refresh_label"):
            self.refresh_label.set_text("Memindai...")
        if hasattr(self, "refresh_btn"):
            self.refresh_btn.set_sensitive(False)
        AppDetector.get_all_apps(force_reload=True)
        self._refresh_rules_list()
        GLib.timeout_add(500, self._reset_refresh_button)

    def _reset_refresh_button(self):
        if hasattr(self, "refresh_label"):
            self.refresh_label.set_text("Refresh")
        if hasattr(self, "refresh_btn"):
            self.refresh_btn.set_sensitive(True)
        return False

    def _on_behavior_changed(self, row, param):
        val = "floating" if row.get_selected() == 1 else "tiled"
        backend.set("hyprland.tiling.newWorkspaceBehavior", val, auto_apply=False)
        backend.generate_rules_lua()

    def _on_active_hint_changed(self, row, param):
        backend.set("hyprland.tiling.activeHint", row.get_active())
        backend.apply_hyprland()

    def _on_filter_dropdown_changed(self, dropdown, param):
        idx = dropdown.get_selected()
        self.current_category_filter = self.cat_filter_keys[idx] if idx < len(self.cat_filter_keys) else "all"
        self._refresh_rules_list()

    def _on_search_changed(self, entry):
        self.search_text = entry.get_text().lower().strip()
        self._refresh_rules_list()

    def _refresh_rules_list(self):
        # Clear existing rows
        while True:
            child = self.rules_list_box.get_first_child()
            if child is None:
                break
            self.rules_list_box.remove(child)

        rules = backend.get_window_rules()
        count = 0

        for r in rules:
            cat = r.get("category", "custom")
            if self.current_category_filter != "all" and cat != self.current_category_filter:
                continue

            name = r.get("name", "Aturan")
            cls = r.get("class", "")
            if self.search_text:
                if self.search_text not in name.lower() and self.search_text not in cls.lower():
                    continue

            count += 1
            row = self._create_rule_row(r)
            self.rules_list_box.append(row)

        if count == 0:
            empty_row = Adw.ActionRow(
                title="No Window Rules Found",
                subtitle="Click '+' at the top right to add a new rule"
            )
            empty_row.set_sensitive(False)
            self.rules_list_box.append(empty_row)

    def _create_rule_row(self, rule_data):
        row = Adw.ActionRow()
        row.set_title(rule_data.get("name", "Aturan"))

        mode = rule_data.get("mode", "float")
        cls = rule_data.get("class", "")
        size_w = int(float(rule_data.get("size_w", 0.60)) * 100)
        size_h = int(float(rule_data.get("size_h", 0.60)) * 100)
        center = rule_data.get("center", True)

        tags = []
        if mode == "float":
            center_txt = ", Tengah" if center else ""
            tags.append(f"Melayang ({size_w}% × {size_h}%{center_txt})")
        else:
            tags.append("Tiling (Ubin)")

        if rule_data.get("custom_opacity"):
            if rule_data.get("opacity_mode") == "opaque":
                tags.append("Pekat 100%")
            else:
                act = int(round(float(rule_data.get("opacity_active", 0.88)) * 100))
                inact = int(round(float(rule_data.get("opacity_inactive", 0.85)) * 100))
                tags.append(f"Opasitas {act}%/{inact}%")

        if rule_data.get("blur"):
            b_str = rule_data.get("blur_strength")
            if b_str and int(b_str) > 0:
                tags.append(f"Blur {int(b_str)}%")
            else:
                tags.append("Blur")

        if rule_data.get("pin"):
            tags.append("Disematkan")

        if rule_data.get("dim_around"):
            tags.append("Redupkan Sekeliling")

        if rule_data.get("no_shadow"):
            tags.append("Tanpa Bayangan")

        if rule_data.get("custom_rounding"):
            tags.append(f"Sudut {rule_data.get('rounding', 10)}px")

        if rule_data.get("custom_border"):
            tags.append(f"Border {rule_data.get('border_size', 2)}px")

        sub = " • ".join(tags)
        if cls:
            sub += f" | Kelas: {cls}"
        row.set_subtitle(sub)

        # Icon prefix
        icon_name = rule_data.get("icon", "preferences-system-windows-symbolic")
        icon_img = Gtk.Image.new_from_icon_name(icon_name)
        icon_img.set_pixel_size(24)
        row.add_prefix(icon_img)

        # Edit button
        edit_btn = Gtk.Button.new_from_icon_name("document-edit-symbolic")
        edit_btn.add_css_class("flat")
        edit_btn.set_valign(Gtk.Align.CENTER)
        edit_btn.set_tooltip_text("Sunting Aturan")
        edit_btn.connect("clicked", lambda b, r=rule_data: self._open_rule_editor(r))
        row.add_suffix(edit_btn)

        # Delete button
        del_btn = Gtk.Button.new_from_icon_name("user-trash-symbolic")
        del_btn.add_css_class("flat")
        del_btn.add_css_class("destructive-action")
        del_btn.set_valign(Gtk.Align.CENTER)
        del_btn.set_tooltip_text("Hapus Aturan")
        del_btn.connect("clicked", lambda b, r=rule_data: self._delete_rule(r))
        row.add_suffix(del_btn)

        return row

    def _open_rule_editor(self, rule_data):
        root_win = self.get_root()
        dialog = RuleEditorDialog(root_win, existing_rule=rule_data, on_save_callback=self._on_save_rule)
        dialog.present()

    def _on_save_rule(self, rule_data):
        rules = backend.get_window_rules()
        existing_idx = None
        for idx, r in enumerate(rules):
            if r.get("id") == rule_data.get("id"):
                existing_idx = idx
                break

        if existing_idx is not None:
            rules[existing_idx] = rule_data
        else:
            rules.append(rule_data)

        backend.save_window_rules(rules)
        self._refresh_rules_list()

    def _delete_rule(self, rule_data):
        rules = backend.get_window_rules()
        rules = [r for r in rules if r.get("id") != rule_data.get("id")]
        backend.save_window_rules(rules)
        self._refresh_rules_list()
