import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw
from backend import backend

class GtkThemePage(Gtk.Box):
    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self.set_margin_top(14)
        self.set_margin_bottom(18)
        self.set_margin_start(16)
        self.set_margin_end(16)

        self.installed_themes = backend.get_installed_gtk_themes()
        if not self.installed_themes:
            self.installed_themes = ["Adwaita", "Adwaita-dark", "WhiteSur-Dark", "WhiteSur-Light"]

        self.installed_icon_themes = backend.get_installed_icon_themes()
        if not self.installed_icon_themes:
            self.installed_icon_themes = ["Adwaita", "WhiteSur-light", "WhiteSur-dark", "Yaru-magenta", "Yaru-magenta-dark"]

        self._build_theme_selection_group()
        self._build_icon_selection_group()
        self._build_palette_group()
        self._build_theming_harmony_group()
        self._build_terminal_props_group()

    def _build_theme_selection_group(self):
        group = Adw.PreferencesGroup()
        group.set_title("GTK Theme")
        self.append(group)

        # Light GTK Theme
        light_model = Gtk.StringList.new(self.installed_themes)
        self.light_combo = Adw.ComboRow(title="Light Mode Theme", model=light_model)
        self.light_combo.set_use_subtitle(True)
        cur_light = backend.get("appearance.lightGtkTheme", "")
        if cur_light in self.installed_themes:
            self.light_combo.set_selected(self.installed_themes.index(cur_light))
        def _on_light_theme_selected(r, p):
            theme = self.installed_themes[r.get_selected()]
            backend.set("appearance.lightGtkTheme", theme)
            if backend.get_current_color_scheme() == "light":
                backend.apply_gtk_theme("light")
        self.light_combo.connect("notify::selected", _on_light_theme_selected)
        group.add(self.light_combo)

        # Dark GTK Theme
        dark_model = Gtk.StringList.new(self.installed_themes)
        self.dark_combo = Adw.ComboRow(title="Dark Mode Theme", model=dark_model)
        self.dark_combo.set_use_subtitle(True)
        cur_dark = backend.get("appearance.darkGtkTheme", "")
        if cur_dark in self.installed_themes:
            self.dark_combo.set_selected(self.installed_themes.index(cur_dark))
        def _on_dark_theme_selected(r, p):
            theme = self.installed_themes[r.get_selected()]
            backend.set("appearance.darkGtkTheme", theme)
            if backend.get_current_color_scheme() == "dark":
                backend.apply_gtk_theme("dark")
        self.dark_combo.connect("notify::selected", _on_dark_theme_selected)
        group.add(self.dark_combo)

    def _build_icon_selection_group(self):
        group = Adw.PreferencesGroup()
        group.set_title("Icon Theme")
        self.append(group)

        # Light Icon Theme
        light_icon_model = Gtk.StringList.new(self.installed_icon_themes)
        self.light_icon_combo = Adw.ComboRow(title="Light Mode Icons", model=light_icon_model)
        self.light_icon_combo.set_use_subtitle(True)
        cur_light_icon = backend.get("appearance.lightIconTheme", "Yaru-magenta")
        if cur_light_icon in self.installed_icon_themes:
            self.light_icon_combo.set_selected(self.installed_icon_themes.index(cur_light_icon))
        elif "Yaru-magenta" in self.installed_icon_themes:
            self.light_icon_combo.set_selected(self.installed_icon_themes.index("Yaru-magenta"))

        def _on_light_icon_selected(r, p):
            theme = self.installed_icon_themes[r.get_selected()]
            backend.set("appearance.lightIconTheme", theme)
            if backend.get_current_color_scheme() == "light":
                backend.apply_icon_theme(theme)

        self.light_icon_combo.connect("notify::selected", _on_light_icon_selected)
        group.add(self.light_icon_combo)

        # Dark Icon Theme
        dark_icon_model = Gtk.StringList.new(self.installed_icon_themes)
        self.dark_icon_combo = Adw.ComboRow(title="Dark Mode Icons", model=dark_icon_model)
        self.dark_icon_combo.set_use_subtitle(True)
        cur_dark_icon = backend.get("appearance.darkIconTheme", "Yaru-magenta-dark")
        if cur_dark_icon in self.installed_icon_themes:
            self.dark_icon_combo.set_selected(self.installed_icon_themes.index(cur_dark_icon))
        elif "Yaru-magenta-dark" in self.installed_icon_themes:
            self.dark_icon_combo.set_selected(self.installed_icon_themes.index("Yaru-magenta-dark"))

        def _on_dark_icon_selected(r, p):
            theme = self.installed_icon_themes[r.get_selected()]
            backend.set("appearance.darkIconTheme", theme)
            if backend.get_current_color_scheme() == "dark":
                backend.apply_icon_theme(theme)

        self.dark_icon_combo.connect("notify::selected", _on_dark_icon_selected)
        group.add(self.dark_icon_combo)

    def _build_palette_group(self):
        group = Adw.PreferencesGroup()
        group.set_title("Palette &amp; Theming")
        self.append(group)

        # Palette Type
        palette_labels = [
            "Automatic",
            "Tonal Spot (Balanced)",
            "Expressive",
            "Content",
            "Fidelity",
            "Monochrome",
            "Neutral",
            "Rainbow"
        ]
        palette_values = [
            "auto",
            "scheme-tonal-spot",
            "scheme-expressive",
            "scheme-content",
            "scheme-fidelity",
            "scheme-monochrome",
            "scheme-neutral",
            "scheme-rainbow"
        ]
        palette_model = Gtk.StringList.new(palette_labels)
        palette_row = Adw.ComboRow(
            title="Palette Style (Matugen)",
            model=palette_model
        )
        palette_row.set_use_subtitle(True)
        cur_palette = backend.get("appearance.palette.type", "auto")
        if cur_palette in palette_values:
            palette_row.set_selected(palette_values.index(cur_palette))
        else:
            palette_row.set_selected(0)
        def _on_palette_selected(r, p):
            backend.set("appearance.palette.type", palette_values[r.get_selected()])
            backend.apply_gtk_theme()
        palette_row.connect("notify::selected", _on_palette_selected)
        group.add(palette_row)

        # Apply GTK Theme Action Row
        apply_row = Adw.ActionRow(title="Reload Theme", subtitle="Apply current theme and icon configurations across apps")
        btn_apply = Gtk.Button(label="Apply")
        btn_apply.set_valign(Gtk.Align.CENTER)
        btn_apply.add_css_class("suggested-action")
        btn_apply.set_tooltip_text("Apply theme and icons now")
        btn_apply.connect("clicked", lambda b: backend.apply_gtk_theme())
        apply_row.add_suffix(btn_apply)
        group.add(apply_row)

    def _build_theming_harmony_group(self):
        group = Adw.PreferencesGroup()
        group.set_title("Color Synchronization")
        self.append(group)

        # Shell and Utilities
        shell_row = Adw.SwitchRow(title="Panels &amp; Menus", subtitle="Synchronize bar and menu colors with wallpaper")
        shell_row.set_active(backend.get("appearance.wallpaperTheming.enableAppsAndShell", True))
        shell_row.connect("notify::active", lambda r, p: (backend.set("appearance.wallpaperTheming.enableAppsAndShell", r.get_active()), backend.apply_gtk_theme()))
        group.add(shell_row)

        # Qt / KDE
        qt_row = Adw.SwitchRow(title="Qt Applications", subtitle="Synchronize Qt6 and KDE application themes")
        qt_row.set_active(backend.get("appearance.wallpaperTheming.enableQtApps", True))
        qt_row.connect("notify::active", lambda r, p: (backend.set("appearance.wallpaperTheming.enableQtApps", r.get_active()), backend.apply_gtk_theme()))
        group.add(qt_row)

        # Terminal
        term_row = Adw.SwitchRow(title="Terminal (Kitty)", subtitle="Automatically harmonize terminal colors")
        term_row.set_active(backend.get("appearance.wallpaperTheming.enableTerminal", True))
        term_row.connect("notify::active", lambda r, p: (backend.set("appearance.wallpaperTheming.enableTerminal", r.get_active()), backend.apply_gtk_theme()))
        group.add(term_row)

        # Force Dark Terminal
        dark_term_row = Adw.SwitchRow(title="Force Dark Terminal")
        dark_term_row.set_active(backend.get("appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode", False))
        dark_term_row.connect("notify::active", lambda r, p: (backend.set("appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode", r.get_active()), backend.apply_gtk_theme()))
        group.add(dark_term_row)

    def _build_terminal_props_group(self):
        group = Adw.PreferencesGroup()
        group.set_title("Terminal Fine-Tuning")
        self.append(group)

        # Harmony
        harmony_val = int(backend.get("appearance.wallpaperTheming.terminalGenerationProps.harmony", 0.6) * 100)
        harmony_adj = Gtk.Adjustment(value=float(harmony_val), lower=0, upper=100, step_increment=5, page_increment=10)
        harmony_row = Adw.SpinRow(
            title="Harmony Level (%)",
            adjustment=harmony_adj
        )
        harmony_row.connect("notify::value", lambda r, p: backend.set("appearance.wallpaperTheming.terminalGenerationProps.harmony", round(r.get_value() / 100.0, 2)))
        group.add(harmony_row)

        # Threshold
        thresh_val = int(backend.get("appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold", 100))
        thresh_adj = Gtk.Adjustment(value=float(thresh_val), lower=0, upper=100, step_increment=5, page_increment=10)
        thresh_row = Adw.SpinRow(
            title="Adjustment Threshold",
            adjustment=thresh_adj
        )
        thresh_row.connect("notify::value", lambda r, p: backend.set("appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold", int(r.get_value())))
        group.add(thresh_row)

        # Fg Boost
        boost_val = int(backend.get("appearance.wallpaperTheming.terminalGenerationProps.termFgBoost", 0.35) * 100)
        boost_adj = Gtk.Adjustment(value=float(boost_val), lower=0, upper=100, step_increment=5, page_increment=10)
        boost_row = Adw.SpinRow(
            title="Text Brightness Boost (%)",
            adjustment=boost_adj
        )
        boost_row.connect("notify::value", lambda r, p: backend.set("appearance.wallpaperTheming.terminalGenerationProps.termFgBoost", round(r.get_value() / 100.0, 2)))
        group.add(boost_row)
