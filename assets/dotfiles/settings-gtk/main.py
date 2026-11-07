#!/usr/bin/env python3
"""
Rinauby — GTK4 / Libadwaita Desktop Settings
Digital Humanism & School of Athens Desktop Experience
Fully compatible with Ubuntu Hyprland PPA & Standalone
Sesuai Panduan Desain GTK HIG
"""

import sys
import os

CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, CURRENT_DIR)

if "XDG_DATA_DIRS" in os.environ:
    seen = set()
    os.environ["XDG_DATA_DIRS"] = ":".join(
        d for d in os.environ["XDG_DATA_DIRS"].split(":") if d and not (d in seen or seen.add(d))
    )

import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning)

import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw, Gio, GLib, Gdk

from sidebar import SettingsSidebar
import importlib

PAGE_SPECS = {
    # 1. Connectivity
    "wifi": ("pages.wifi_page", "WifiPage", "Wi-Fi"),
    "bluetooth": ("pages.bluetooth_page", "BluetoothPage", "Bluetooth"),
    # 2. Appearance & Personalization
    "appearance": ("pages.appearance_page", "AppearancePage", "Appearance"),
    "wallpaper": ("pages.wallpaper_page", "WallpaperPage", "Wallpapers"),
    "gtk_theme": ("pages.gtk_theme_page", "GtkThemePage", "GTK Theme & Icons"),
    # 3. Window Manager (Hyprland Core)
    "general": ("pages.general_page", "GeneralPage", "General Settings"),
    "window_rules": ("pages.window_rules_page", "WindowRulesPage", "Window Rules"),
    "default_apps": ("pages.default_apps_page", "DefaultAppsPage", "Default Apps"),
    "execs": ("pages.execs_page", "ExecsPage", "Startup Applications"),
    "env": ("pages.env_page", "EnvPage", "Session Variables"),
    # 4. Panel & System
    "bar": ("pages.bar_page", "BarPage", "Top Status Bar"),
    "dock_lock": ("pages.dock_lock_page", "LockPage", "Lock Screen & Dock"),
    "audio": ("pages.audio_page", "AudioPage", "Sound"),
    "power": ("pages.power_page", "PowerPage", "Power & Battery"),
    "shortcuts": ("pages.shortcuts_page", "ShortcutsPage", "Keyboard Shortcuts"),
    "about": ("pages.about_page", "AboutPage", "About System"),
}

PRELOAD_PRIORITY = [
    "wifi",
    "appearance",
    "general",
    "bar"
]

class SettingsMainWindow(Adw.ApplicationWindow):
    def __init__(self, initial_page="wifi", **kwargs):
        super().__init__(**kwargs)
        self.set_title("Settings")
        self.set_default_size(880, 600)
        self.add_css_class("rinauby-settings")

        self._load_css()

        # Main Split View
        self.split_view = Adw.NavigationSplitView()
        self.split_view.set_min_sidebar_width(240)
        self.split_view.set_max_sidebar_width(270)
        self.split_view.set_sidebar_width_fraction(0.28)

        # 1. Left Sidebar Navigation
        sidebar_tb = Adw.ToolbarView()
        sidebar_hb = Adw.HeaderBar()
        sidebar_hb.set_show_end_title_buttons(False)
        sidebar_hb.set_show_start_title_buttons(False)

        brand_lbl = Gtk.Label()
        brand_lbl.set_markup("<span font='9.5' weight='bold' letter_spacing='2000' color='#db9c5e'>RINAUBY</span>")
        sidebar_hb.set_title_widget(brand_lbl)
        sidebar_tb.add_top_bar(sidebar_hb)

        self.sidebar = SettingsSidebar(on_select_callback=self._on_page_selected)
        sidebar_tb.set_content(self.sidebar)

        sidebar_nav_page = Adw.NavigationPage.new(sidebar_tb, "Settings")
        self.split_view.set_sidebar(sidebar_nav_page)

        # 2. Right Content Navigation
        content_tb = Adw.ToolbarView()
        self.content_hb = Adw.HeaderBar()

        # Judul Headerbar Tidak Terpotong
        target_page = initial_page if initial_page in PAGE_SPECS else "wifi"
        init_title = PAGE_SPECS.get(target_page, (None, None, "Wi-Fi"))[2]
        self.header_title = Gtk.Label(label=init_title)
        self.header_title.add_css_class("header-title")
        self.content_hb.set_title_widget(self.header_title)

        close_btn = Gtk.Button.new_from_icon_name("window-close-symbolic")
        close_btn.add_css_class("flat")
        close_btn.add_css_class("circular")
        close_btn.set_tooltip_text("Close")
        close_btn.connect("clicked", lambda b: self.close())
        self.content_hb.pack_end(close_btn)

        self.refresh_btn = Gtk.Button.new_from_icon_name("view-refresh-symbolic")
        self.refresh_btn.add_css_class("flat")
        self.refresh_btn.add_css_class("circular")
        self.refresh_btn.set_tooltip_text("Refresh Settings (F5)")
        self.refresh_btn.connect("clicked", lambda b: self.refresh_all_settings())
        self.content_hb.pack_end(self.refresh_btn)

        content_tb.add_top_bar(self.content_hb)

        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE)
        self.stack.set_transition_duration(120)

        self.page_instances = {}
        self.page_clamps = {}
        self.preload_queue = []

        # Clamp Simetris & Proporsional (HIG Standard: max 640px)
        for page_id, spec in PAGE_SPECS.items():
            clamp = Adw.Clamp(maximum_size=640, tightening_threshold=520)
            self.page_clamps[page_id] = clamp

            placeholder = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
            placeholder.set_valign(Gtk.Align.CENTER)
            placeholder.set_halign(Gtk.Align.CENTER)
            spinner = Gtk.Spinner()
            spinner.set_size_request(24, 24)
            spinner.start()
            placeholder.append(spinner)
            clamp.set_child(placeholder)

            scrolled = Gtk.ScrolledWindow()
            scrolled.set_vexpand(True)
            scrolled.set_hexpand(True)
            scrolled.set_child(clamp)

            self.stack.add_named(scrolled, page_id)

        self.toast_overlay = Adw.ToastOverlay()
        self.toast_overlay.set_child(self.stack)
        content_tb.set_content(self.toast_overlay)

        self.content_nav_page = Adw.NavigationPage.new(content_tb, init_title)
        self.split_view.set_content(self.content_nav_page)

        self.set_content(self.split_view)

        # Shortcuts: F5 / Ctrl+R untuk refresh, Escape untuk tutup
        shortcut_ctrl = Gtk.ShortcutController.new()
        shortcut_ctrl.set_scope(Gtk.ShortcutScope.GLOBAL)
        trigger_f5 = Gtk.ShortcutTrigger.parse_string("F5")
        action_f5 = Gtk.CallbackAction.new(lambda w, a: self.refresh_all_settings() or True)
        shortcut_ctrl.add_shortcut(Gtk.Shortcut.new(trigger_f5, action_f5))

        trigger_ctrl_r = Gtk.ShortcutTrigger.parse_string("<Primary>r")
        action_ctrl_r = Gtk.CallbackAction.new(lambda w, a: self.refresh_all_settings() or True)
        shortcut_ctrl.add_shortcut(Gtk.Shortcut.new(trigger_ctrl_r, action_ctrl_r))

        trigger_esc = Gtk.ShortcutTrigger.parse_string("Escape")
        action_esc = Gtk.CallbackAction.new(lambda w, a: (self.close() or True))
        shortcut_ctrl.add_shortcut(Gtk.Shortcut.new(trigger_esc, action_esc))
        self.add_controller(shortcut_ctrl)

        # Load initial page
        self._load_page(target_page)
        self.sidebar.select_page(target_page)
        self._on_page_selected(target_page)

        GLib.idle_add(self._start_background_preloader)

    def _load_css(self):
        css_file = os.path.join(CURRENT_DIR, "style.css")
        if os.path.exists(css_file):
            provider = Gtk.CssProvider()
            provider.load_from_path(css_file)
            display = Gdk.Display.get_default()
            if display:
                Gtk.StyleContext.add_provider_for_display(
                    display, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
                )

    def _load_page(self, page_id):
        if page_id in self.page_instances:
            return self.page_instances[page_id]

        if page_id not in PAGE_SPECS:
            return None

        mod_name, cls_name, _ = PAGE_SPECS[page_id]
        try:
            mod = importlib.import_module(mod_name)
            page_cls = getattr(mod, cls_name)
            page_widget = page_cls()
            self.page_instances[page_id] = page_widget

            if page_id in self.page_clamps:
                self.page_clamps[page_id].set_child(page_widget)

            return page_widget
        except Exception as e:
            print(f"Error loading page {page_id}: {e}")
            return None

    def _start_background_preloader(self):
        self.preload_queue = [
            pid for pid in PRELOAD_PRIORITY
            if pid not in self.page_instances and pid in PAGE_SPECS
        ]
        GLib.timeout_add(120, self._process_preload_step)
        return False

    def _process_preload_step(self):
        if not hasattr(self, "preload_queue") or not self.preload_queue:
            return False

        next_page_id = self.preload_queue.pop(0)
        if next_page_id not in self.page_instances:
            self._load_page(next_page_id)

        return len(self.preload_queue) > 0

    def refresh_all_settings(self):
        if hasattr(self, "refresh_btn"):
            self.refresh_btn.set_sensitive(False)

        from backend import backend
        backend.rescan_system()

        for page_id, page_widget in list(self.page_instances.items()):
            if hasattr(page_widget, "refresh_page"):
                try:
                    page_widget.refresh_page()
                except Exception as e:
                    print(f"Error refreshing page {page_id}: {e}")

        if hasattr(self, "toast_overlay"):
            toast = Adw.Toast.new("All settings refreshed successfully")
            toast.set_timeout(2)
            self.toast_overlay.add_toast(toast)

        GLib.timeout_add(300, lambda: self.refresh_btn.set_sensitive(True) if hasattr(self, "refresh_btn") else False)
        return True

    def _on_page_selected(self, page_id):
        if page_id in PAGE_SPECS:
            _, _, title = PAGE_SPECS[page_id]
            if page_id not in self.page_instances:
                if hasattr(self, "preload_queue") and page_id in self.preload_queue:
                    self.preload_queue.remove(page_id)
                self._load_page(page_id)

            self.stack.set_visible_child_name(page_id)
            self.header_title.set_text(title)
            self.content_nav_page.set_title(title)
            self.split_view.set_show_content(True)

class SettingsApp(Adw.Application):
    def __init__(self, initial_page="wifi"):
        super().__init__(
            application_id="org.rinauby.settings",
            flags=Gio.ApplicationFlags.HANDLES_COMMAND_LINE
        )
        self.initial_page = initial_page
        self.win = None

    def do_command_line(self, command_line):
        args = command_line.get_arguments()
        page = self.initial_page
        toggle = False

        for i, arg in enumerate(args):
            if arg == "--toggle":
                toggle = True
            elif arg == "--page" and i + 1 < len(args):
                page = args[i + 1]
            elif arg.startswith("--page="):
                page = arg.split("=", 1)[1]

        if not self.win:
            self.win = SettingsMainWindow(application=self, initial_page=page)

        if toggle:
            if self.win.is_visible():
                self.win.set_visible(False)
                return 0
            else:
                if page:
                    self.win.sidebar.select_page(page)
                    self.win._on_page_selected(page)
                self.win.present()
                return 0

        if page:
            self.win.sidebar.select_page(page)
            self.win._on_page_selected(page)
        self.win.present()
        return 0

    def do_activate(self):
        if not self.win:
            self.win = SettingsMainWindow(application=self, initial_page=self.initial_page)
        self.win.present()

def main():
    GLib.set_prgname("org.system.settings")
    GLib.set_application_name("Settings")
    app = SettingsApp()
    return app.run(sys.argv)

if __name__ == "__main__":
    sys.exit(main())
