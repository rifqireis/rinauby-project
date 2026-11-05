import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw
import platform
import subprocess

class AboutPage(Gtk.Box):
    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self.set_margin_top(14)
        self.set_margin_bottom(18)
        self.set_margin_start(16)
        self.set_margin_end(16)

        title_lbl = Gtk.Label(label="About System")
        title_lbl.set_halign(Gtk.Align.START)
        title_lbl.add_css_class("page-header-title")
        self.append(title_lbl)

        group = Adw.PreferencesGroup()
        self.append(group)

        # Hero Row
        hero_row = Adw.ActionRow(
            title="Desktop Environment",
            subtitle="Clean, Elegant & Cohesive Desktop Experience"
        )
        badge_hero = Gtk.Label(label="v1.0")
        badge_hero.add_css_class("pill-dropdown-button")
        badge_hero.set_valign(Gtk.Align.CENTER)
        hero_row.add_suffix(badge_hero)
        group.add(hero_row)

        # Kernel
        kernel_str = platform.release()
        k_row = Adw.ActionRow(
            title="Linux Kernel",
            subtitle="High performance Linux kernel with Wayland DRM/KMS"
        )
        badge_k = Gtk.Label(label=kernel_str)
        badge_k.add_css_class("pill-dropdown-button")
        badge_k.set_valign(Gtk.Align.CENTER)
        k_row.add_suffix(badge_k)
        group.add(k_row)

        # Window Manager / Compositor
        wm_row = Adw.ActionRow(
            title="Window Manager",
            subtitle="Hyprland Wayland Compositor with dynamic animations &amp; blur"
        )
        badge_wm = Gtk.Label(label="Hyprland 0.54+")
        badge_wm.add_css_class("pill-dropdown-button")
        badge_wm.set_valign(Gtk.Align.CENTER)
        wm_row.add_suffix(badge_wm)
        group.add(wm_row)

        # Architecture & Target ISO
        arch_row = Adw.ActionRow(
            title="Target Distribution",
            subtitle="Custom Ubuntu 26.04 Noble LTS built via Cubic ISO builder"
        )
        badge_arch = Gtk.Label(label="x86_64 EFI")
        badge_arch.add_css_class("pill-dropdown-button")
        badge_arch.set_valign(Gtk.Align.CENTER)
        arch_row.add_suffix(badge_arch)
        group.add(arch_row)
