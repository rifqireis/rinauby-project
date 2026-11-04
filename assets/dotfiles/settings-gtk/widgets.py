import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw, GLib, Gdk


class NumericSlider(Gtk.Box):
    """
    Komponen slider horizontal yang dilengkapi dengan kotak angka interaktif (editable pill).
    Pengguna dapat menggeser slider secara visual ATAU langsung mengklik angka untuk mengetik
    nilai yang diinginkan secara presisi.
    """
    def __init__(
        self,
        adjustment: Gtk.Adjustment,
        suffix: str = "%",
        digits: int = 0,
        min_width: int = 170,
        zero_label: str = None,
        tooltip_entry: str = "Klik untuk mengetik angka langsung (tekan Enter untuk menerapkan)",
        tooltip_scale: str = "Geser untuk menyesuaikan nilai"
    ):
        super().__init__(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        self.adjustment = adjustment
        self.suffix_text = suffix
        self.digits = digits
        self.zero_label = zero_label
        self._is_editing = False

        self.set_valign(Gtk.Align.CENTER)

        # 1. Slider (Gtk.Scale)
        self.scale = Gtk.Scale(orientation=Gtk.Orientation.HORIZONTAL, adjustment=adjustment)
        self.scale.set_draw_value(False)  # Nilai angka digambar oleh interactive entry
        self.scale.set_size_request(min_width, -1)
        self.scale.set_hexpand(True)
        self.scale.set_valign(Gtk.Align.CENTER)
        if tooltip_scale:
            self.scale.set_tooltip_text(tooltip_scale)
        self.append(self.scale)

        # 2. Interactive Numeric Pill Entry
        self.entry = Gtk.Entry()
        self.entry.set_valign(Gtk.Align.CENTER)
        self.entry.set_alignment(0.5)
        self.entry.set_max_width_chars(8)
        self.entry.set_width_chars(6)
        self.entry.add_css_class("numeric-pill-entry")
        if tooltip_entry:
            self.entry.set_tooltip_text(tooltip_entry)
        self.append(self.entry)

        # Sinkronisasi nilai awal
        self._update_display()

        # Listeners
        self.adjustment.connect("value-changed", self._on_adj_value_changed)
        self.entry.connect("activate", self._on_entry_activate)

        # Focus controller untuk inline editing
        focus_ctrl = Gtk.EventControllerFocus()
        focus_ctrl.connect("enter", self._on_focus_enter)
        focus_ctrl.connect("leave", self._on_focus_leave)
        self.entry.add_controller(focus_ctrl)

        # Keyboard controller (Escape untuk batal)
        key_ctrl = Gtk.EventControllerKey()
        key_ctrl.connect("key-pressed", self._on_key_pressed)
        self.entry.add_controller(key_ctrl)

    def _format_value(self, val: float) -> str:
        if self.zero_label and round(val, self.digits) == 0:
            return self.zero_label
        if self.digits == 0:
            num_str = str(int(round(val)))
        else:
            num_str = f"{val:.{self.digits}f}"
        return f"{num_str}{self.suffix_text}" if self.suffix_text else num_str

    def _update_display(self):
        if not self._is_editing:
            self.entry.set_text(self._format_value(self.adjustment.get_value()))

    def _on_adj_value_changed(self, adj):
        if not self._is_editing:
            self._update_display()

    def _select_all_text(self):
        if self._is_editing:
            self.entry.select_region(0, -1)
        return False

    def _on_focus_enter(self, controller):
        self._is_editing = True
        val = self.adjustment.get_value()
        if self.digits == 0:
            raw_text = str(int(round(val)))
        else:
            raw_text = f"{val:.{self.digits}f}"
        self.entry.set_text(raw_text)
        # Otomatis blokir/pilih semua teks saat diklik agar bisa langsung ditimpa ketikan baru
        GLib.timeout_add(60, self._select_all_text)

    def _on_key_pressed(self, controller, keyval, keycode, state):
        if keyval == Gdk.KEY_Escape:
            self._is_editing = False
            self._update_display()
            self.scale.grab_focus()
            return True
        return False

    def _commit_value(self):
        text = self.entry.get_text().strip()
        if self.suffix_text:
            text = text.replace(self.suffix_text.strip(), "")
        text = text.replace("%", "").replace("px", "").replace("ms", "").replace(",", ".").strip()

        # Tangani kata "mati" / "off" jika zero_label aktif
        if self.zero_label and text.lower() in ["mati", "off", "nonaktif", "none"]:
            self.adjustment.set_value(self.adjustment.get_lower())
            self._is_editing = False
            self._update_display()
            return

        try:
            val = float(text)
            lower = self.adjustment.get_lower()
            upper = self.adjustment.get_upper()
            val = max(lower, min(upper, val))
            if self.digits == 0:
                val = round(val)
            self.adjustment.set_value(val)
        except ValueError:
            # Revert jika masukan tidak valid
            pass

        self._is_editing = False
        self._update_display()

    def _on_entry_activate(self, entry):
        self._commit_value()
        self.scale.grab_focus()

    def _on_focus_leave(self, controller):
        self._commit_value()

    def get_value(self) -> float:
        return self.adjustment.get_value()

    def set_value(self, val: float):
        self.adjustment.set_value(val)

    def get_adjustment(self) -> Gtk.Adjustment:
        return self.adjustment

    def connect(self, detailed_signal: str, handler, *args):
        # Delegasikan value-changed ke scale / adjustment jika dipanggil langsung
        if detailed_signal == "value-changed":
            return self.scale.connect(detailed_signal, handler, *args)
        return super().connect(detailed_signal, handler, *args)


class NumericSliderRow(Adw.ActionRow):
    """
    Adw.ActionRow dengan kontrol slider horizontal dan kotak angka interaktif bawaan.
    """
    def __init__(
        self,
        title: str,
        subtitle: str = None,
        adjustment: Gtk.Adjustment = None,
        suffix: str = "%",
        digits: int = 0,
        min_width: int = 170,
        zero_label: str = None
    ):
        super().__init__(title=title, subtitle=subtitle)
        if adjustment is None:
            adjustment = Gtk.Adjustment(value=50, lower=0, upper=100, step_increment=1, page_increment=10)

        self.slider = NumericSlider(
            adjustment=adjustment,
            suffix=suffix,
            digits=digits,
            min_width=min_width,
            zero_label=zero_label
        )
        self.add_suffix(self.slider)

        # Properti akses cepat
        self.scale = self.slider.scale
        self.entry = self.slider.entry
        self.adjustment = adjustment

    def get_value(self) -> float:
        return self.slider.get_value()

    def set_value(self, val: float):
        self.slider.set_value(val)


def enhance_spin_row(spin_row: Adw.SpinRow):
    """
    Meningkatkan Adw.SpinRow agar ketika area angkanya diklik/fokus, seluruh teks
    langsung terblokir (selected) sehingga pengguna dapat langsung mengetikkan angka baru
    tanpa harus menghapus satu per satu secara manual.
    """
    try:
        delegate = spin_row.get_delegate()
        if delegate:
            delegate.set_tooltip_text("Ketik angka langsung atau gunakan tombol +/-")
            focus_ctrl = Gtk.EventControllerFocus()
            def _select_spin(ctrl):
                def _do_select():
                    delegate.select_region(0, -1)
                    return False
                GLib.timeout_add(60, _do_select)
            focus_ctrl.connect("enter", _select_spin)
            delegate.add_controller(focus_ctrl)
    except Exception:
        pass
    return spin_row
