import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw
from backend import backend
from widgets import enhance_spin_row

class PowerPage(Gtk.Box):
    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self.set_margin_top(14)
        self.set_margin_bottom(18)
        self.set_margin_start(16)
        self.set_margin_end(16)

        self._build_warnings_group()
        self._build_suspend_group()

    def _build_warnings_group(self):
        group = Adw.PreferencesGroup()
        group.set_title("Battery Alerts")
        self.append(group)

        # Low warning
        low_val = backend.get("battery.low", 20)
        low_adj = Gtk.Adjustment(value=float(low_val), lower=10, upper=40, step_increment=1, page_increment=5)
        low_row = enhance_spin_row(Adw.SpinRow(
            title="Low Battery Threshold (%)",
            subtitle="Reminder when battery level is running low",
            adjustment=low_adj
        ))
        low_row.connect("notify::value", lambda r, p: backend.set("battery.low", int(r.get_value())))
        group.add(low_row)

        # Critical warning
        crit_val = backend.get("battery.critical", 5)
        crit_adj = Gtk.Adjustment(value=float(crit_val), lower=3, upper=15, step_increment=1, page_increment=2)
        crit_row = enhance_spin_row(Adw.SpinRow(
            title="Critical Battery Threshold (%)",
            subtitle="Urgent alert before power runs out",
            adjustment=crit_adj
        ))
        crit_row.connect("notify::value", lambda r, p: backend.set("battery.critical", int(r.get_value())))
        group.add(crit_row)

        # Full charge warning (101 = disabled)
        full_val = backend.get("battery.full", 101)
        full_adj = Gtk.Adjustment(value=float(full_val), lower=50, upper=101, step_increment=1, page_increment=5)
        full_row = enhance_spin_row(Adw.SpinRow(
            title="Full Charge Threshold (%)",
            subtitle="Unplug notification (set 101 to disable)",
            adjustment=full_adj
        ))
        full_row.connect("notify::value", lambda r, p: backend.set("battery.full", int(r.get_value())))
        group.add(full_row)

    def _build_suspend_group(self):
        group = Adw.PreferencesGroup()
        group.set_title("Power Saving")
        self.append(group)

        # Automatic suspend switch
        auto_suspend_row = Adw.SwitchRow(
            title="Automatic Suspend",
            subtitle="Put system to sleep when battery reaches critical level"
        )
        auto_suspend_row.set_active(backend.get("battery.automaticSuspend", True))
        auto_suspend_row.connect("notify::active", lambda r, p: backend.set("battery.automaticSuspend", r.get_active()))
        group.add(auto_suspend_row)

        # Suspend threshold
        suspend_val = backend.get("battery.suspend", 3)
        suspend_adj = Gtk.Adjustment(value=float(suspend_val), lower=1, upper=10, step_increment=1, page_increment=1)
        suspend_row = enhance_spin_row(Adw.SpinRow(
            title="Suspend Threshold (%)",
            adjustment=suspend_adj
        ))
        suspend_row.connect("notify::value", lambda r, p: backend.set("battery.suspend", int(r.get_value())))
        group.add(suspend_row)
