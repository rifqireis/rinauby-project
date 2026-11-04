#!/usr/bin/env python3
"""
School of Athens — OSD Indicator Daemon & CLI
Matches ui/renaissance_osd.png with Wayland Layer-Shell and Cairo rendering.
"""

import sys
import os
import socket
import subprocess
import threading
import time

SOCKET_PATH = "/tmp/school_of_athens_osd.sock"

# ------------------------------------------------------------------------------
# Helper functions for querying and setting hardware levels
# ------------------------------------------------------------------------------

def get_volume_info():
    """Returns (volume_percentage: int, is_muted: bool)"""
    try:
        out = subprocess.check_output(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"], stderr=subprocess.DEVNULL).decode()
        # Output format: "Volume: 0.28" or "Volume: 0.28 [MUTED]"
        parts = out.strip().split()
        val = 0
        is_muted = "[MUTED]" in out
        for part in parts:
            try:
                val = int(round(float(part) * 100))
                break
            except ValueError:
                continue
        return val, is_muted
    except Exception:
        # Fallback to amixer
        try:
            out = subprocess.check_output(["amixer", "get", "Master"], stderr=subprocess.DEVNULL).decode()
            import re
            m_pct = re.search(r"\[(\d+)%\]", out)
            m_mute = re.search(r"\[(off)\]", out)
            pct = int(m_pct.group(1)) if m_pct else 50
            muted = bool(m_mute)
            return pct, muted
        except Exception:
            return 50, False

def get_brightness_info():
    """Returns brightness_percentage: int"""
    try:
        out = subprocess.check_output(["brightnessctl", "info"], stderr=subprocess.DEVNULL).decode()
        import re
        m = re.search(r"\((\d+)%\)", out)
        if m:
            return int(m.group(1))
        # Direct calculation
        curr = int(subprocess.check_output(["brightnessctl", "get"]).strip())
        max_b = int(subprocess.check_output(["brightnessctl", "max"]).strip())
        return int(round((curr / max_b) * 100))
    except Exception:
        return 50

def send_to_daemon(message):
    """Sends a message to the running OSD daemon. Returns True on success."""
    if not os.path.exists(SOCKET_PATH):
        return False
    try:
        client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        client.connect(SOCKET_PATH)
        client.sendall((message + "\n").encode())
        client.close()
        return True
    except Exception:
        return False

# ------------------------------------------------------------------------------
# GUI & Layer-Shell Daemon
# ------------------------------------------------------------------------------

def run_daemon():
    # Remove stale socket
    if os.path.exists(SOCKET_PATH):
        try:
            os.remove(SOCKET_PATH)
        except OSError:
            pass

    import gi
    gi.require_version('Gtk', '3.0')
    gi.require_version('GtkLayerShell', '0.1')
    from gi.repository import Gtk, GtkLayerShell, GLib, Gdk
    import cairo

    class CapsuleWidget(Gtk.DrawingArea):
        def __init__(self, icon_type='volume'):
            super().__init__()
            self.icon_type = icon_type
            self.value = 50
            self.is_muted = False
            self.set_size_request(340, 46)
            self.connect('draw', self.on_draw)

        def update(self, value, is_muted=False):
            self.value = value
            self.is_muted = is_muted
            self.queue_draw()

        def on_draw(self, widget, cr):
            width = widget.get_allocated_width()
            height = widget.get_allocated_height()

            # Pill Capsule outline
            r = height / 2.0
            cr.new_sub_path()
            cr.arc(width - r, r, r, -1.570796, 1.570796)
            cr.arc(r, r, r, 1.570796, 4.712389)
            cr.close_path()

            # Background: dark charcoal semi-transparent
            cr.set_source_rgba(0.094, 0.106, 0.122, 0.94)
            cr.fill_preserve()

            # Fine Renaissance Gold Hairline Border (#db9c5e)
            cr.set_source_rgba(0.859, 0.612, 0.369, 0.55)
            cr.set_line_width(1.5)
            cr.stroke()

            # Left Circular Icon Badge
            badge_cx = 24.0
            badge_cy = height / 2.0
            badge_r = 15.0
            cr.arc(badge_cx, badge_cy, badge_r, 0, 6.283185)
            cr.set_source_rgba(0.165, 0.188, 0.220, 0.9)
            cr.fill_preserve()
            cr.set_source_rgba(0.859, 0.612, 0.369, 0.25)
            cr.set_line_width(1.0)
            cr.stroke()

            # Icon inside badge
            cr.select_font_face('JetBrainsMono Nerd Font', cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
            cr.set_font_size(15)
            if self.icon_type == 'volume':
                if self.is_muted:
                    icon = '󰝟'
                    cr.set_source_rgb(0.88, 0.42, 0.46) # Soft red
                else:
                    icon = '󰕾'
                    cr.set_source_rgb(0.34, 0.71, 0.76) # Cyan/aquamarine accent
            else:
                icon = '󰃠'
                cr.set_source_rgb(0.90, 0.75, 0.48) # Warm golden accent

            ext = cr.text_extents(icon)
            cr.move_to(badge_cx - ext.width/2 - ext.x_bearing, badge_cy - ext.height/2 - ext.y_bearing)
            cr.show_text(icon)

            # Progress Slider Bar
            bar_x = 50.0
            bar_y = height / 2.0 - 3.5
            bar_w = width - 110.0
            bar_h = 7.0
            bar_r = 3.5

            # Trough (unfilled)
            cr.new_sub_path()
            cr.arc(bar_x + bar_w - bar_r, bar_y + bar_r, bar_r, -1.570796, 1.570796)
            cr.arc(bar_x + bar_r, bar_y + bar_r, bar_r, 1.570796, 4.712389)
            cr.close_path()
            cr.set_source_rgba(0.18, 0.20, 0.24, 0.95)
            cr.fill()

            # Filled Progress (Renaissance Gold #db9c5e)
            fill_pct = max(0.0, min(1.0, self.value / 100.0))
            if fill_pct > 0.03:
                fill_w = max(bar_r * 2, bar_w * fill_pct)
                cr.new_sub_path()
                cr.arc(bar_x + fill_w - bar_r, bar_y + bar_r, bar_r, -1.570796, 1.570796)
                cr.arc(bar_x + bar_r, bar_y + bar_r, bar_r, 1.570796, 4.712389)
                cr.close_path()
                cr.set_source_rgb(0.859, 0.612, 0.369)
                cr.fill()

            # Percentage Text Label
            cr.select_font_face('Inter', cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
            cr.set_font_size(11)
            cr.set_source_rgb(0.98, 0.95, 0.86) # Warm cream
            text = f"{int(self.value)}%"
            text_ext = cr.text_extents(text)
            text_x = width - 16.0 - text_ext.width
            text_y = height / 2.0 - text_ext.height/2 - text_ext.y_bearing
            cr.move_to(text_x, text_y)
            cr.show_text(text)

            return False

    # Initialize Wayland Layer Shell Window
    win = Gtk.Window()
    GtkLayerShell.init_for_window(win)
    GtkLayerShell.set_layer(win, GtkLayerShell.Layer.OVERLAY)
    GtkLayerShell.set_namespace(win, 'school-of-athens-osd')
    GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.BOTTOM, True)
    GtkLayerShell.set_margin(win, GtkLayerShell.Edge.BOTTOM, 65)

    screen = win.get_screen()
    visual = screen.get_rgba_visual()
    if visual:
        win.set_visual(visual)
    win.set_app_paintable(True)

    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
    vol_capsule = CapsuleWidget('volume')
    bri_capsule = CapsuleWidget('brightness')

    box.pack_start(vol_capsule, False, False, 0)
    box.pack_start(bri_capsule, False, False, 0)
    win.add(box)

    # State tracking
    state = {
        'timer_id': None,
        'active_widgets': set()
    }

    def hide_osd():
        win.hide()
        state['timer_id'] = None
        state['active_widgets'].clear()
        return False

    def show_osd_type(target_type, val, is_muted=False):
        # Reset dismiss timer
        if state['timer_id']:
            GLib.source_remove(state['timer_id'])

        state['active_widgets'].add(target_type)

        if target_type == 'volume':
            vol_capsule.update(val, is_muted)
            vol_capsule.show()
            if 'brightness' not in state['active_widgets']:
                bri_capsule.hide()
        elif target_type == 'brightness':
            bri_capsule.update(val)
            bri_capsule.show()
            if 'volume' not in state['active_widgets']:
                vol_capsule.hide()

        win.show_all()
        # Keep non-active hidden
        if 'volume' not in state['active_widgets']:
            vol_capsule.hide()
        if 'brightness' not in state['active_widgets']:
            bri_capsule.hide()

        # Auto hide after 1.5 seconds
        state['timer_id'] = GLib.timeout_add(1500, hide_osd)

    # UNIX Socket Server Thread
    def server_thread():
        server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        server.bind(SOCKET_PATH)
        server.listen(10)

        while True:
            try:
                conn, _ = server.accept()
                data = conn.recv(1024).decode().strip()
                conn.close()

                if not data:
                    continue

                # Protocol: SHOW:<type>:<val>[:muted]
                parts = data.split(':')
                if parts[0] == "SHOW":
                    t_type = parts[1]
                    val = int(parts[2])
                    muted = (len(parts) > 3 and parts[3] == "1")
                    GLib.idle_add(show_osd_type, t_type, val, muted)
                elif parts[0] == "QUIT":
                    GLib.idle_add(Gtk.main_quit)
                    break
            except Exception as e:
                time.sleep(0.1)

    t = threading.Thread(target=server_thread, daemon=True)
    t.start()

    Gtk.main()

# ------------------------------------------------------------------------------
# Entry Point & CLI Dispatcher
# ------------------------------------------------------------------------------

def ensure_daemon():
    """Starts the daemon if not running."""
    if not os.path.exists(SOCKET_PATH):
        subprocess.Popen([sys.executable, os.path.abspath(__file__), "daemon"],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(0.2)

def main():
    if len(sys.argv) < 2:
        print("Usage: osd.py [daemon | volume-up | volume-down | volume-mute | brightness-up | brightness-down]")
        sys.exit(1)

    action = sys.argv[1].lower()

    if action == "daemon":
        run_daemon()
        return

    # Trigger action
    if action in ["vol-up", "volume-up", "volume+"]:
        subprocess.run(["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", "5%+"], stderr=subprocess.DEVNULL)
        ensure_daemon()
        val, muted = get_volume_info()
        send_to_daemon(f"SHOW:volume:{val}:{1 if muted else 0}")

    elif action in ["vol-down", "volume-down", "volume-"]:
        subprocess.run(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"], stderr=subprocess.DEVNULL)
        ensure_daemon()
        val, muted = get_volume_info()
        send_to_daemon(f"SHOW:volume:{val}:{1 if muted else 0}")

    elif action in ["vol-mute", "volume-mute", "mute"]:
        subprocess.run(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"], stderr=subprocess.DEVNULL)
        ensure_daemon()
        val, muted = get_volume_info()
        send_to_daemon(f"SHOW:volume:{val}:{1 if muted else 0}")

    elif action in ["bri-up", "brightness-up", "brightness+"]:
        subprocess.run(["brightnessctl", "set", "5%+"], stderr=subprocess.DEVNULL)
        ensure_daemon()
        val = get_brightness_info()
        send_to_daemon(f"SHOW:brightness:{val}")

    elif action in ["bri-down", "brightness-down", "brightness-"]:
        subprocess.run(["brightnessctl", "set", "5%-"], stderr=subprocess.DEVNULL)
        ensure_daemon()
        val = get_brightness_info()
        send_to_daemon(f"SHOW:brightness:{val}")

    elif action == "show-volume":
        ensure_daemon()
        val, muted = get_volume_info()
        send_to_daemon(f"SHOW:volume:{val}:{1 if muted else 0}")

    elif action == "show-brightness":
        ensure_daemon()
        val = get_brightness_info()
        send_to_daemon(f"SHOW:brightness:{val}")

    elif action == "quit":
        send_to_daemon("QUIT")

if __name__ == "__main__":
    main()
