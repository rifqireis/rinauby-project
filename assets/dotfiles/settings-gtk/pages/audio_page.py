import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw
from backend import backend

class AudioPage(Gtk.Box):
    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self.set_margin_top(14)
        self.set_margin_bottom(18)
        self.set_margin_start(16)
        self.set_margin_end(16)

        self._build_protection_group()
        self._build_sounds_group()

    def _build_protection_group(self):
        group = Adw.PreferencesGroup()
        group.set_title("Volume Protection")
        self.append(group)

        # Enable protection
        prot_row = Adw.SwitchRow(
            title="Volume Spike Limit",
            subtitle="Prevent abrupt high-volume spikes"
        )
        prot_row.set_active(backend.get("audio.protection.enable", False))
        prot_row.connect("notify::active", lambda r, p: backend.set("audio.protection.enable", r.get_active()))
        group.add(prot_row)

        # Max allowed increase
        inc_val = backend.get("audio.protection.maxAllowedIncrease", 10)
        inc_adj = Gtk.Adjustment(value=float(inc_val), lower=1, upper=50, step_increment=1, page_increment=5)
        inc_row = Adw.SpinRow(
            title="Max Increase per Step (%)",
            adjustment=inc_adj
        )
        inc_row.connect("notify::value", lambda r, p: backend.set("audio.protection.maxAllowedIncrease", int(r.get_value())))
        group.add(inc_row)

        # Max allowed absolute
        max_val = backend.get("audio.protection.maxAllowed", 99)
        max_adj = Gtk.Adjustment(value=float(max_val), lower=50, upper=153, step_increment=1, page_increment=5)
        max_row = Adw.SpinRow(
            title="Absolute Max Volume (%)",
            adjustment=max_adj
        )
        max_row.connect("notify::value", lambda r, p: backend.set("audio.protection.maxAllowed", int(r.get_value())))
        group.add(max_row)

    def _build_sounds_group(self):
        group = Adw.PreferencesGroup()
        group.set_title("Sound Effects")
        self.append(group)

        # Battery sound
        bat_sound_row = Adw.SwitchRow(
            title="Charger Connection Sound",
            subtitle="Play chime when power cable is plugged or unplugged"
        )
        bat_sound_row.set_active(backend.get("sounds.battery", True))
        bat_sound_row.connect("notify::active", lambda r, p: backend.set("sounds.battery", r.get_active()))
        group.add(bat_sound_row)

        # Pomodoro sound
        pomo_sound_row = Adw.SwitchRow(
            title="Pomodoro Timer Sound",
            subtitle="Play alert when focus or break session completes"
        )
        pomo_sound_row.set_active(backend.get("sounds.pomodoro", True))
        pomo_sound_row.connect("notify::active", lambda r, p: backend.set("sounds.pomodoro", r.get_active()))
        group.add(pomo_sound_row)
