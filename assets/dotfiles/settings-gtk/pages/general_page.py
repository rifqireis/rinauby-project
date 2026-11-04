import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw, Gdk
from backend import backend
from widgets import enhance_spin_row

class GeneralPage(Gtk.Box):
    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self.set_margin_top(14)
        self.set_margin_bottom(18)
        self.set_margin_start(16)
        self.set_margin_end(16)

        # View Stack & Switcher
        self.stack = Adw.ViewStack()
        self.stack.set_vexpand(True)

        switcher = Adw.ViewSwitcher()
        switcher.set_stack(self.stack)
        switcher.set_policy(Adw.ViewSwitcherPolicy.WIDE)
        switcher.set_halign(Gtk.Align.CENTER)
        switcher.set_margin_bottom(8)
        self.append(switcher)

        # 1. Tata Letak
        self.stack.add_titled_with_icon(self._build_tiling_page(), "tiling", "Layout", "view-grid-symbolic")

        # 2. Efek Visual
        self.stack.add_titled_with_icon(self._build_effects_page(), "effects", "Visual Effects", "window-maximize-symbolic")

        # 3. Animasi
        self.stack.add_titled_with_icon(self._build_anim_page(), "anim", "Animations", "system-run-symbolic")

        # 4. Kursor & Touchpad
        self.stack.add_titled_with_icon(self._build_input_page(), "input", "Input", "input-mouse-symbolic")

        self.append(self.stack)

    # -----------------------------------------------------------------
    # 1. TATA LETAK
    # -----------------------------------------------------------------
    def _build_tiling_page(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)

        # Susunan
        layout_grp = Adw.PreferencesGroup()
        layout_grp.set_title("Window Layout")
        box.append(layout_grp)

        layout_model = Gtk.StringList.new(["Dwindle (Spiral)", "Master"])
        layout_row = Adw.ComboRow(
            title="Layout",
            model=layout_model
        )
        current_layout = backend.get("hyprland.layout", "dwindle")
        layout_row.set_selected(0 if current_layout == "dwindle" else 1)
        layout_row.connect("notify::selected", self._on_layout_changed)
        layout_grp.add(layout_row)

        tearing_row = Adw.SwitchRow(
            title="Screen Tearing",
            subtitle="Reduce input latency in fullscreen games"
        )
        tearing_row.set_active(backend.get("hyprland.allowTearing", True))
        tearing_row.connect("notify::active", lambda r, p: self._update_bool("hyprland.allowTearing", r.get_active()))
        layout_grp.add(tearing_row)

        # Celah
        gaps_grp = Adw.PreferencesGroup()
        gaps_grp.set_title("Window Gaps")
        box.append(gaps_grp)

        gaps_in_adj = Gtk.Adjustment(value=backend.get("hyprland.gapsIn", 4), lower=0, upper=30, step_increment=1, page_increment=5)
        gaps_in_row = enhance_spin_row(Adw.SpinRow(
            title="Inner Gaps",
            adjustment=gaps_in_adj
        ))
        gaps_in_row.connect("notify::value", lambda r, p: self._update_int("hyprland.gapsIn", r.get_value()))
        gaps_grp.add(gaps_in_row)

        # Celah Antar Jendela Lanjutan (Tiap Sisi)
        gaps_in_adv_row = Adw.ExpanderRow(
            title="Per-Side Inner Gaps"
        )
        gaps_in_adv_row.set_show_enable_switch(True)
        gaps_in_adv_enabled = backend.get("hyprland.gapsInAdvanced", False)
        gaps_in_adv_row.set_enable_expansion(gaps_in_adv_enabled)
        gaps_in_adv_row.connect("notify::enable-expansion", self._on_gaps_in_adv_toggled)

        base_gaps_in = backend.get("hyprland.gapsIn", 4)
        in_top_adj = Gtk.Adjustment(value=backend.get("hyprland.gapsInTop", base_gaps_in), lower=0, upper=40, step_increment=1, page_increment=5)
        in_top_row = enhance_spin_row(Adw.SpinRow(title="Top", adjustment=in_top_adj))
        in_top_row.connect("notify::value", lambda r, p: self._update_int("hyprland.gapsInTop", r.get_value()))
        gaps_in_adv_row.add_row(in_top_row)

        in_right_adj = Gtk.Adjustment(value=backend.get("hyprland.gapsInRight", base_gaps_in), lower=0, upper=40, step_increment=1, page_increment=5)
        in_right_row = enhance_spin_row(Adw.SpinRow(title="Right", adjustment=in_right_adj))
        in_right_row.connect("notify::value", lambda r, p: self._update_int("hyprland.gapsInRight", r.get_value()))
        gaps_in_adv_row.add_row(in_right_row)

        in_bottom_adj = Gtk.Adjustment(value=backend.get("hyprland.gapsInBottom", base_gaps_in), lower=0, upper=40, step_increment=1, page_increment=5)
        in_bottom_row = enhance_spin_row(Adw.SpinRow(title="Bottom", adjustment=in_bottom_adj))
        in_bottom_row.connect("notify::value", lambda r, p: self._update_int("hyprland.gapsInBottom", r.get_value()))
        gaps_in_adv_row.add_row(in_bottom_row)

        in_left_adj = Gtk.Adjustment(value=backend.get("hyprland.gapsInLeft", base_gaps_in), lower=0, upper=40, step_increment=1, page_increment=5)
        in_left_row = enhance_spin_row(Adw.SpinRow(title="Left", adjustment=in_left_adj))
        in_left_row.connect("notify::value", lambda r, p: self._update_int("hyprland.gapsInLeft", r.get_value()))
        gaps_in_adv_row.add_row(in_left_row)
        gaps_grp.add(gaps_in_adv_row)

        gaps_out_adj = Gtk.Adjustment(value=backend.get("hyprland.gapsOut", 10), lower=0, upper=50, step_increment=1, page_increment=5)
        gaps_out_row = enhance_spin_row(Adw.SpinRow(
            title="Outer Gaps",
            adjustment=gaps_out_adj
        ))
        gaps_out_row.connect("notify::value", lambda r, p: self._update_int("hyprland.gapsOut", r.get_value()))
        gaps_grp.add(gaps_out_row)

        # Celah ke Tepi Layar Lanjutan (Tiap Sisi)
        gaps_out_adv_row = Adw.ExpanderRow(
            title="Per-Side Outer Gaps"
        )
        gaps_out_adv_row.set_show_enable_switch(True)
        gaps_out_adv_enabled = backend.get("hyprland.gapsOutAdvanced", False)
        gaps_out_adv_row.set_enable_expansion(gaps_out_adv_enabled)
        gaps_out_adv_row.connect("notify::enable-expansion", self._on_gaps_out_adv_toggled)

        base_gaps_out = backend.get("hyprland.gapsOut", 10)
        out_top_adj = Gtk.Adjustment(value=backend.get("hyprland.gapsOutTop", base_gaps_out), lower=0, upper=60, step_increment=1, page_increment=5)
        out_top_row = enhance_spin_row(Adw.SpinRow(title="Top", adjustment=out_top_adj))
        out_top_row.connect("notify::value", lambda r, p: self._update_int("hyprland.gapsOutTop", r.get_value()))
        gaps_out_adv_row.add_row(out_top_row)

        out_right_adj = Gtk.Adjustment(value=backend.get("hyprland.gapsOutRight", base_gaps_out), lower=0, upper=60, step_increment=1, page_increment=5)
        out_right_row = enhance_spin_row(Adw.SpinRow(title="Right", adjustment=out_right_adj))
        out_right_row.connect("notify::value", lambda r, p: self._update_int("hyprland.gapsOutRight", r.get_value()))
        gaps_out_adv_row.add_row(out_right_row)

        out_bottom_adj = Gtk.Adjustment(value=backend.get("hyprland.gapsOutBottom", base_gaps_out), lower=0, upper=60, step_increment=1, page_increment=5)
        out_bottom_row = enhance_spin_row(Adw.SpinRow(title="Bottom", adjustment=out_bottom_adj))
        out_bottom_row.connect("notify::value", lambda r, p: self._update_int("hyprland.gapsOutBottom", r.get_value()))
        gaps_out_adv_row.add_row(out_bottom_row)

        out_left_adj = Gtk.Adjustment(value=backend.get("hyprland.gapsOutLeft", base_gaps_out), lower=0, upper=60, step_increment=1, page_increment=5)
        out_left_row = enhance_spin_row(Adw.SpinRow(title="Left", adjustment=out_left_adj))
        out_left_row.connect("notify::value", lambda r, p: self._update_int("hyprland.gapsOutLeft", r.get_value()))
        gaps_out_adv_row.add_row(out_left_row)
        gaps_grp.add(gaps_out_adv_row)

        # Bingkai
        border_grp = Adw.PreferencesGroup()
        border_grp.set_title("Garis Tepi")
        box.append(border_grp)

        border_adj = Gtk.Adjustment(value=backend.get("hyprland.borderSize", 2), lower=0, upper=10, step_increment=1, page_increment=2)
        border_row = enhance_spin_row(Adw.SpinRow(
            title="Ketebalan Garis Tepi",
            adjustment=border_adj
        ))
        border_row.connect("notify::value", lambda r, p: self._update_int("hyprland.borderSize", r.get_value()))
        border_grp.add(border_row)

        resize_row = Adw.SwitchRow(
            title="Ubah Ukuran pada Garis Tepi",
            subtitle="Seret garis tepi jendela untuk mengubah ukuran"
        )
        resize_row.set_active(backend.get("hyprland.resizeOnBorder", True))
        resize_row.connect("notify::active", lambda r, p: self._update_bool("hyprland.resizeOnBorder", r.get_active()))
        border_grp.add(resize_row)

        grab_adj = Gtk.Adjustment(value=backend.get("hyprland.extendBorderGrabArea", 15), lower=0, upper=40, step_increment=1, page_increment=5)
        grab_row = enhance_spin_row(Adw.SpinRow(
            title="Area Tangkapan Garis Tepi",
            adjustment=grab_adj
        ))
        grab_row.connect("notify::value", lambda r, p: self._update_int("hyprland.extendBorderGrabArea", r.get_value()))
        border_grp.add(grab_row)

        hover_row = Adw.SwitchRow(
            title="Kursor Ubah Ukuran",
            subtitle="Tampilkan kursor panah saat melayang di atas garis tepi"
        )
        hover_row.set_active(backend.get("hyprland.hoverIconOnBorder", True))
        hover_row.connect("notify::active", lambda r, p: self._update_bool("hyprland.hoverIconOnBorder", r.get_active()))
        border_grp.add(hover_row)

        # Warna Garis Tepi
        color_grp = Adw.PreferencesGroup()
        color_grp.set_title("Warna Garis Tepi")
        box.append(color_grp)

        custom_border_row = Adw.SwitchRow(
            title="Gunakan Warna Kustom",
            subtitle="Tentukan warna sendiri alih-alih warna dinamis wallpaper"
        )
        custom_borders_active = backend.get("hyprland.customBorders", True)
        custom_border_row.set_active(custom_borders_active)
        color_grp.add(custom_border_row)

        self.border_color_rows = []

        act_dark_row, self.btn_act_dark = self._create_color_row(
            title="Jendela Aktif (Mode Gelap)",
            subtitle=None,
            key="hyprland.activeBorderDark",
            default_val="rgba(33ffdcc6)"
        )
        color_grp.add(act_dark_row)
        self.border_color_rows.append(act_dark_row)

        act_light_row, self.btn_act_light = self._create_color_row(
            title="Jendela Aktif (Mode Terang)",
            subtitle=None,
            key="hyprland.activeBorderLight",
            default_val="rgba(88f700f7)"
        )
        color_grp.add(act_light_row)
        self.border_color_rows.append(act_light_row)

        inact_dark_row, self.btn_inact_dark = self._create_color_row(
            title="Jendela Tidak Aktif (Mode Gelap)",
            subtitle=None,
            key="hyprland.inactiveBorderDark",
            default_val="rgba(23191933)"
        )
        color_grp.add(inact_dark_row)
        self.border_color_rows.append(inact_dark_row)

        inact_light_row, self.btn_inact_light = self._create_color_row(
            title="Jendela Tidak Aktif (Mode Terang)",
            subtitle=None,
            key="hyprland.inactiveBorderLight",
            default_val="rgba(8839ef33)"
        )
        color_grp.add(inact_light_row)
        self.border_color_rows.append(inact_light_row)

        reset_row = Adw.ActionRow(
            title="Reset Warna ke Bawaan"
        )
        reset_btn = Gtk.Button(label="Reset")
        reset_btn.set_valign(Gtk.Align.CENTER)
        reset_btn.connect("clicked", self._on_reset_border_colors)
        reset_row.add_suffix(reset_btn)
        color_grp.add(reset_row)
        self.border_color_rows.append(reset_row)

        custom_border_row.connect("notify::active", self._on_custom_borders_toggled)
        for r in self.border_color_rows:
            r.set_sensitive(custom_borders_active)

        return box

    # -----------------------------------------------------------------
    # 2. EFEK VISUAL
    # -----------------------------------------------------------------
    def _build_effects_page(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)

        # Sudut
        round_grp = Adw.PreferencesGroup()
        round_grp.set_title("Sudut Jendela")
        box.append(round_grp)

        round_adj = Gtk.Adjustment(value=min(20, backend.get("hyprland.rounding", 10)), lower=0, upper=20, step_increment=1, page_increment=5)
        round_row = enhance_spin_row(Adw.SpinRow(
            title="Radius Sudut",
            adjustment=round_adj
        ))
        round_row.connect("notify::value", lambda r, p: self._update_int("hyprland.rounding", r.get_value()))
        round_grp.add(round_row)

        pwr_adj = Gtk.Adjustment(value=backend.get("hyprland.roundingPower", 2.0), lower=2.0, upper=3.0, step_increment=0.1, page_increment=0.5)
        pwr_row = enhance_spin_row(Adw.SpinRow(
            title="Gaya Sudut",
            subtitle="2.0 untuk lingkaran standar, 3.0 untuk squircle modern",
            digits=1,
            adjustment=pwr_adj
        ))
        pwr_row.connect("notify::value", lambda r, p: self._update_float("hyprland.roundingPower", r.get_value()))
        round_grp.add(pwr_row)

        # Opacity
        op_grp = Adw.PreferencesGroup()
        op_grp.set_title("Opasitas &amp; Redup")
        box.append(op_grp)

        act_adj = Gtk.Adjustment(value=backend.get("hyprland.activeOpacity", 1.0), lower=0.5, upper=1.0, step_increment=0.05, page_increment=0.1)
        act_row = enhance_spin_row(Adw.SpinRow(
            title="Active Window Opacity",
            digits=2,
            adjustment=act_adj
        ))
        act_row.connect("notify::value", lambda r, p: self._update_float("hyprland.activeOpacity", r.get_value()))
        op_grp.add(act_row)

        inact_adj = Gtk.Adjustment(value=backend.get("hyprland.inactiveOpacity", 0.95), lower=0.5, upper=1.0, step_increment=0.05, page_increment=0.1)
        inact_row = enhance_spin_row(Adw.SpinRow(
            title="Opasitas Jendela Tidak Aktif",
            digits=2,
            adjustment=inact_adj
        ))
        inact_row.connect("notify::value", lambda r, p: self._update_float("hyprland.inactiveOpacity", r.get_value()))
        op_grp.add(inact_row)

        dim_row = Adw.SwitchRow(
            title="Redupkan Jendela Tidak Aktif"
        )
        dim_row.set_active(backend.get("hyprland.dimInactive", False))
        dim_row.connect("notify::active", lambda r, p: self._update_bool("hyprland.dimInactive", r.get_active()))
        op_grp.add(dim_row)

        # Blur
        blur_grp = Adw.PreferencesGroup()
        blur_grp.set_title("Blur")
        box.append(blur_grp)

        blur_row = Adw.SwitchRow(
            title="Aktifkan Blur",
            subtitle="Efek buram di balik jendela transparan"
        )
        blur_row.set_active(backend.get("hyprland.blurEnabled", True))
        blur_row.connect("notify::active", lambda r, p: self._update_bool("hyprland.blurEnabled", r.get_active()))
        blur_grp.add(blur_row)

        size_adj = Gtk.Adjustment(value=backend.get("hyprland.blurSize", 6), lower=1, upper=20, step_increment=1, page_increment=2)
        size_row = enhance_spin_row(Adw.SpinRow(
            title="Ukuran Blur",
            adjustment=size_adj
        ))
        size_row.connect("notify::value", lambda r, p: self._update_int("hyprland.blurSize", r.get_value()))
        blur_grp.add(size_row)

        passes_adj = Gtk.Adjustment(value=backend.get("hyprland.blurPasses", 3), lower=1, upper=5, step_increment=1, page_increment=1)
        passes_row = enhance_spin_row(Adw.SpinRow(
            title="Iterasi Blur",
            adjustment=passes_adj
        ))
        passes_row.connect("notify::value", lambda r, p: self._update_int("hyprland.blurPasses", r.get_value()))
        blur_grp.add(passes_row)

        noise_adj = Gtk.Adjustment(
            value=float(backend.get("hyprland.blurNoise", 0.0117)),
            lower=0.0,
            upper=0.10,
            step_increment=0.005,
            page_increment=0.01
        )
        noise_row = enhance_spin_row(Adw.SpinRow(
            title="Noise Blur",
            digits=4,
            adjustment=noise_adj
        ))
        noise_row.connect("notify::value", lambda r, p: self._update_float("hyprland.blurNoise", r.get_value(), digits=4))
        blur_grp.add(noise_row)

        # Bayangan
        shadow_grp = Adw.PreferencesGroup()
        shadow_grp.set_title("Bayangan")
        box.append(shadow_grp)

        shadow_row = Adw.SwitchRow(
            title="Window Shadow"
        )
        shadow_row.set_active(backend.get("hyprland.shadowEnabled", True))
        shadow_row.connect("notify::active", lambda r, p: self._update_bool("hyprland.shadowEnabled", r.get_active()))
        shadow_grp.add(shadow_row)

        range_adj = Gtk.Adjustment(value=backend.get("hyprland.shadowRange", 20), lower=0, upper=60, step_increment=2, page_increment=10)
        range_row = enhance_spin_row(Adw.SpinRow(
            title="Ukuran Bayangan",
            adjustment=range_adj
        ))
        range_row.connect("notify::value", lambda r, p: self._update_int("hyprland.shadowRange", r.get_value()))
        shadow_grp.add(range_row)

        return box

    # -----------------------------------------------------------------
    # 3. ANIMASI
    # -----------------------------------------------------------------
    def _build_anim_page(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)

        anim_grp = Adw.PreferencesGroup()
        anim_grp.set_title("Animations")
        box.append(anim_grp)

        master_row = Adw.SwitchRow(
            title="Aktifkan Animasi"
        )
        master_row.set_active(backend.get("hyprland.animationsEnabled", True))
        master_row.connect("notify::active", lambda r, p: self._update_bool("hyprland.animationsEnabled", r.get_active()))
        anim_grp.add(master_row)

        resize_row = Adw.SwitchRow(
            title="Animasi Ubah Ukuran"
        )
        resize_row.set_active(backend.get("hyprland.animateManualResizes", False))
        resize_row.connect("notify::active", lambda r, p: self._update_bool("hyprland.animateManualResizes", r.get_active()))
        anim_grp.add(resize_row)

        drag_row = Adw.SwitchRow(
            title="Animasi Seret Jendela"
        )
        drag_row.set_active(backend.get("hyprland.animateMouseWindowDragging", False))
        drag_row.connect("notify::active", lambda r, p: self._update_bool("hyprland.animateMouseWindowDragging", r.get_active()))
        anim_grp.add(drag_row)

        return box

    # -----------------------------------------------------------------
    # 4. KURSOR & TOUCHPAD
    # -----------------------------------------------------------------
    def _build_input_page(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)

        mouse_grp = Adw.PreferencesGroup()
        mouse_grp.set_title("Tetikus (Mouse)")
        box.append(mouse_grp)

        focus_options = [
            "Click to Focus",
            "Fokus Mengikuti Kursor",
            "Fokus Terpisah dari Klik",
            "Kursor Terkunci pada Jendela"
        ]
        focus_model = Gtk.StringList.new(focus_options)
        focus_row = Adw.ComboRow(
            title="Window Focus",
            model=focus_model
        )
        current_focus = backend.get("hyprland.followMouse", 1)
        if isinstance(current_focus, int) and 0 <= current_focus < len(focus_options):
            focus_row.set_selected(current_focus)
        else:
            focus_row.set_selected(1)
        focus_row.connect("notify::selected", lambda r, p: self._update_int("hyprland.followMouse", r.get_selected()))
        mouse_grp.add(focus_row)

        sens_val = backend.get("hyprland.mouseSensitivity", 0.0)
        sens_adj = Gtk.Adjustment(value=float(sens_val), lower=-1.0, upper=1.0, step_increment=0.1, page_increment=0.2)
        sens_row = enhance_spin_row(Adw.SpinRow(
            title="Kecepatan Kursor",
            digits=2,
            adjustment=sens_adj
        ))
        sens_row.connect("notify::value", lambda r, p: self._update_float("hyprland.mouseSensitivity", r.get_value()))
        mouse_grp.add(sens_row)

        touch_grp = Adw.PreferencesGroup()
        touch_grp.set_title("Touchpad")
        box.append(touch_grp)

        natural_row = Adw.SwitchRow(
            title="Natural Scrolling",
            subtitle="Arah gulir mengikuti gerakan jari"
        )
        natural_row.set_active(backend.get("hyprland.touchpadNaturalScroll", True))
        natural_row.connect("notify::active", lambda r, p: self._update_bool("hyprland.touchpadNaturalScroll", r.get_active()))
        touch_grp.add(natural_row)

        tap_row = Adw.SwitchRow(
            title="Tap to Click"
        )
        tap_row.set_active(backend.get("hyprland.touchpadTapToClick", True))
        tap_row.connect("notify::active", lambda r, p: self._update_bool("hyprland.touchpadTapToClick", r.get_active()))
        touch_grp.add(tap_row)

        dwt_row = Adw.SwitchRow(
            title="Nonaktifkan Saat Mengetik",
            subtitle="Cegah sentuhan touchpad tidak disengaja saat mengetik"
        )
        dwt_row.set_active(backend.get("hyprland.touchpadDisableWhileTyping", True))
        dwt_row.connect("notify::active", lambda r, p: self._update_bool("hyprland.touchpadDisableWhileTyping", r.get_active()))
        touch_grp.add(dwt_row)

        return box

    # -----------------------------------------------------------------
    # HELPERS
    # -----------------------------------------------------------------
    def _on_layout_changed(self, row, param):
        val = "dwindle" if row.get_selected() == 0 else "master"
        backend.set("hyprland.layout", val)
        backend.apply_hyprland()

    def _update_int(self, key, val):
        backend.set(key, int(val))
        backend.apply_hyprland()

    def _update_float(self, key, val, digits=2):
        backend.set(key, round(float(val), digits))
        backend.apply_hyprland()

    def _update_bool(self, key, val):
        backend.set(key, bool(val))
        backend.apply_hyprland()

    def _on_gaps_in_adv_toggled(self, row, param):
        is_active = row.get_enable_expansion()
        backend.set("hyprland.gapsInAdvanced", is_active)
        backend.apply_hyprland()

    def _on_gaps_out_adv_toggled(self, row, param):
        is_active = row.get_enable_expansion()
        backend.set("hyprland.gapsOutAdvanced", is_active)
        backend.apply_hyprland()

    def _on_custom_borders_toggled(self, row, param):
        is_active = row.get_active()
        backend.set("hyprland.customBorders", is_active)
        for r in self.border_color_rows:
            r.set_sensitive(is_active)
        backend.apply_hyprland()

    def _create_color_row(self, title, subtitle, key, default_val):
        row = Adw.ActionRow(title=title)
        if subtitle:
            row.set_subtitle(subtitle)
        color_dialog = Gtk.ColorDialog()
        color_dialog.set_title(title)
        color_dialog.set_with_alpha(True)

        btn = Gtk.ColorDialogButton(dialog=color_dialog)
        btn.set_valign(Gtk.Align.CENTER)

        cur_val = backend.get(key, default_val)
        init_rgba = self._parse_hypr_color(cur_val)
        btn.set_rgba(init_rgba)

        def on_color_picked(button, param):
            rgba = button.get_rgba()
            hypr_color = self._rgba_to_hypr_color(rgba)
            backend.set(key, hypr_color)
            backend.apply_hyprland()

        btn.connect("notify::rgba", on_color_picked)
        row.add_suffix(btn)
        return row, btn

    def _on_reset_border_colors(self, button):
        defaults = {
            "hyprland.activeBorderDark": "rgba(33ffdcc6)",
            "hyprland.activeBorderLight": "rgba(88f700f7)",
            "hyprland.inactiveBorderDark": "rgba(23191933)",
            "hyprland.inactiveBorderLight": "rgba(8839ef33)",
        }
        for k, v in defaults.items():
            backend.set(k, v)

        self.btn_act_dark.set_rgba(self._parse_hypr_color(defaults["hyprland.activeBorderDark"]))
        self.btn_act_light.set_rgba(self._parse_hypr_color(defaults["hyprland.activeBorderLight"]))
        self.btn_inact_dark.set_rgba(self._parse_hypr_color(defaults["hyprland.inactiveBorderDark"]))
        self.btn_inact_light.set_rgba(self._parse_hypr_color(defaults["hyprland.inactiveBorderLight"]))

        backend.apply_hyprland()

    def _parse_hypr_color(self, color_str):
        if not color_str:
            return Gdk.RGBA(red=0.5, green=0.5, blue=0.5, alpha=1.0)
        s = str(color_str).strip()
        if s.startswith("rgba(") and s.endswith(")"):
            hex_val = s[5:-1]
        elif s.startswith("rgb(") and s.endswith(")"):
            hex_val = s[4:-1]
        elif s.startswith("#"):
            hex_val = s[1:]
        elif s.startswith("0x"):
            hex_val = s[2:]
        else:
            hex_val = s

        if len(hex_val) == 8:
            r = int(hex_val[0:2], 16) / 255.0
            g = int(hex_val[2:4], 16) / 255.0
            b = int(hex_val[4:6], 16) / 255.0
            a = int(hex_val[6:8], 16) / 255.0
            return Gdk.RGBA(red=r, green=g, blue=b, alpha=a)
        elif len(hex_val) == 6:
            r = int(hex_val[0:2], 16) / 255.0
            g = int(hex_val[2:4], 16) / 255.0
            b = int(hex_val[4:6], 16) / 255.0
            a = int(hex_val[6:8], 16) / 255.0
            return Gdk.RGBA(red=r, green=g, blue=b, alpha=1.0)
        else:
            c = Gdk.RGBA()
            if c.parse(color_str):
                return c
            return Gdk.RGBA(red=0.2, green=1.0, blue=0.86, alpha=0.78)

    def _rgba_to_hypr_color(self, rgba):
        r = int(round(rgba.red * 255))
        g = int(round(rgba.green * 255))
        b = int(round(rgba.blue * 255))
        a = int(round(rgba.alpha * 255))
        return f"rgba({r:02x}{g:02x}{b:02x}{a:02x})"
