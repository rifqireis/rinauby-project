import os
import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw, GdkPixbuf, Gdk
from backend import backend, ASSETS_DIR

WALLPAPERS = [
    ("apotheosis.jpg", "The Apotheosis"),
    ("school_of_athens.jpg", "The School of Athens"),
    ("the_creation_of_adam.jpg", "The Creation of Adam"),
    ("the_last_supper.jpg", "The Last Supper"),
    ("birth_of_venus.jpg", "The Birth of Venus"),
    ("primavera.jpg", "Primavera"),
    ("tower_of_babel.jpg", "The Tower of Babel"),
    ("annunciation.jpg", "The Annunciation")
]

class WallpaperPage(Gtk.Box):
    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self.set_margin_top(14)
        self.set_margin_bottom(18)
        self.set_margin_start(16)
        self.set_margin_end(16)

        title_lbl = Gtk.Label(label="Classical Art Gallery")
        title_lbl.set_halign(Gtk.Align.START)
        title_lbl.add_css_class("page-header-title")
        self.append(title_lbl)

        # Scrolled Window
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_vexpand(True)
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.append(scrolled)

        # FlowBox Grid
        self.flowbox = Gtk.FlowBox()
        self.flowbox.set_valign(Gtk.Align.START)
        self.flowbox.set_max_children_per_line(3)
        self.flowbox.set_min_children_per_line(2)
        self.flowbox.set_selection_mode(Gtk.SelectionMode.NONE)
        self.flowbox.set_column_spacing(16)
        self.flowbox.set_row_spacing(16)
        scrolled.set_child(self.flowbox)

        self.cards = {}
        active_wp = backend.get("active_wallpaper", "apotheosis.jpg")

        wp_dir = os.path.join(ASSETS_DIR, "wallpapers") if os.path.isdir(os.path.join(ASSETS_DIR, "wallpapers")) else (
            ASSETS_DIR if os.path.isdir(ASSETS_DIR) else "/usr/share/backgrounds/rinauby"
        )
        thumb_dir = os.path.join(wp_dir, ".thumbs")

        for filename, title in WALLPAPERS:
            card = Gtk.Button()
            card.add_css_class("wallpaper-card")
            if filename == active_wp:
                card.add_css_class("active")

            vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
            card.set_child(vbox)

            # Thumbnail image
            thumb_path = os.path.join(thumb_dir, f"thumb_{filename}")
            full_path = os.path.join(wp_dir, filename)
            img_path = thumb_path if os.path.exists(thumb_path) else full_path

            pic = Gtk.Picture()
            pic.set_size_request(160, 100)
            pic.set_content_fit(Gtk.ContentFit.COVER)
            try:
                pb = GdkPixbuf.Pixbuf.new_from_file_at_scale(img_path, 200, 130, True)
                if pb:
                    pic.set_paintable(Gdk.Texture.new_for_pixbuf(pb))
            except Exception:
                pass

            vbox.append(pic)

            lbl = Gtk.Label(label=title)
            lbl.add_css_class("wallpaper-card-title")
            vbox.append(lbl)

            card.connect("clicked", lambda b, fn=filename, t=title: self._on_select_wallpaper(fn, t))
            self.flowbox.append(card)
            self.cards[filename] = card

    def _on_select_wallpaper(self, filename, title):
        backend.set_wallpaper(filename, title)
        for fn, c in self.cards.items():
            if fn == filename:
                c.add_css_class("active")
            else:
                c.remove_css_class("active")
