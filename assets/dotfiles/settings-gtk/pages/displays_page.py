import json
import subprocess
import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw

class DisplaysPage(Gtk.Box):
    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self.set_margin_top(14)
        self.set_margin_bottom(18)
        self.set_margin_start(16)
        self.set_margin_end(16)

        title_lbl = Gtk.Label(label="Displays & Hardware")
        title_lbl.set_halign(Gtk.Align.START)
        title_lbl.add_css_class("page-header-title")
        self.append(title_lbl)

        monitors = self._get_monitors_data()
        group = Adw.PreferencesGroup()
        group.set_title("Active Wayland Displays")
        self.append(group)

        if monitors:
            for m in monitors:
                name = m.get("name", "Display")
                desc = m.get("description", "")
                w = m.get("width", 1920)
                h = m.get("height", 1080)
                hz = round(float(m.get("refreshRate", 60.0)), 1)
                scale = float(m.get("scale", 1.0))
                scale_pct = int(scale * 100)

                disp_row = Adw.ActionRow(
                    title=f"{name} ({desc})" if desc else name,
                    subtitle=f"Resolution: {w}x{h} @ {hz}Hz • Scale: {scale_pct}% ({scale}x)"
                )
                badge = Gtk.Label(label=f"{w}x{h} @ {hz}Hz")
                badge.add_css_class("pill-dropdown-button")
                badge.set_valign(Gtk.Align.CENTER)
                disp_row.add_suffix(badge)
                group.add(disp_row)
        else:
            fallback_row = Adw.ActionRow(
                title="Default Display",
                subtitle="1920x1200 (16:10) • 60Hz"
            )
            badge_res = Gtk.Label(label="1920 x 1200 @ 60Hz")
            badge_res.add_css_class("pill-dropdown-button")
            badge_res.set_valign(Gtk.Align.CENTER)
            fallback_row.add_suffix(badge_res)
            group.add(fallback_row)

        # 2. VirtualBox / Virtualization Check
        virt_group = Adw.PreferencesGroup()
        virt_group.set_title("Virtualization &amp; GPU Environment")
        self.append(virt_group)

        is_vm, vm_type = self._detect_virtualization()
        vbox_row = Adw.ActionRow(
            title="Virtualization Status",
            subtitle="VirtualBox Guest Additions and safe software rendering layer" if is_vm else "Native Hardware Execution (Direct DRM/KMS Acceleration)"
        )
        badge_vbox = Gtk.Label(label=f"VM: {vm_type}" if is_vm else "Bare Metal (Host)")
        badge_vbox.add_css_class("pill-dropdown-button")
        badge_vbox.set_valign(Gtk.Align.CENTER)
        vbox_row.add_suffix(badge_vbox)
        virt_group.add(vbox_row)

    def _get_monitors_data(self) -> list:
        try:
            out = subprocess.check_output(["hyprctl", "monitors", "-j"], text=True, stderr=subprocess.DEVNULL)
            return json.loads(out)
        except Exception:
            return []

    def _detect_virtualization(self) -> tuple[bool, str]:
        try:
            out = subprocess.check_output(["systemd-detect-virt"], text=True, stderr=subprocess.DEVNULL).strip()
            if out and out != "none":
                return True, out.capitalize()
        except Exception:
            pass
        try:
            with open("/sys/class/dmi/id/product_name", "r") as f:
                prod = f.read()
                if "virtualbox" in prod.lower():
                    return True, "VirtualBox"
                elif "kvm" in prod.lower() or "qemu" in prod.lower():
                    return True, "KVM/QEMU"
        except Exception:
            pass
        return False, "None"
