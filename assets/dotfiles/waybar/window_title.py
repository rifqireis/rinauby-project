#!/usr/bin/env python3
"""
School of Athens — Dynamic Waybar Window / Wallpaper Title
Displays active application window title, or current wallpaper title when empty.
Outputs JSON stream for Waybar custom module.
"""

import sys
import os
import json
import time
import socket
import signal
import subprocess

WALLPAPER_TITLE_FILE = "/tmp/current_wallpaper_title"

def get_wallpaper_title():
    try:
        if os.path.exists(WALLPAPER_TITLE_FILE):
            with open(WALLPAPER_TITLE_FILE, "r") as f:
                val = f.read().strip()
                if val:
                    return val
    except Exception:
        pass
    return "Desktop"

def get_window_info():
    try:
        out = subprocess.check_output(["hyprctl", "activewindow", "-j"], stderr=subprocess.DEVNULL).decode()
        data = json.loads(out)
        title = data.get("title", "").strip()
        app_class = data.get("class", "").strip()
        if title:
            return title, app_class
    except Exception:
        pass
    return None, None

def truncate(text, max_len=40):
    if len(text) > max_len:
        return text[:max_len - 1] + "…"
    return text

last_output = ""

def emit_status():
    global last_output
    title, app_class = get_window_info()

    if title:
        display_text = truncate(title, 36)
        tooltip = f"{app_class}: {title}" if app_class else title
    else:
        wp = get_wallpaper_title()
        display_text = wp
        tooltip = f"Wallpaper: {wp}"

    payload = json.dumps({
        "text": display_text,
        "tooltip": tooltip,
        "class": "active-app" if title else "active-wallpaper"
    })

    if payload != last_output:
        last_output = payload
        print(payload, flush=True)

def handle_signal(signum, frame):
    emit_status()

def main():
    signal.signal(signal.SIGUSR1, handle_signal)
    signal.signal(signal.SIGUSR2, handle_signal)

    # Initial emission
    emit_status()

    # Locate Hyprland socket2
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    xdg = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    sock_path = f"{xdg}/hypr/{sig}/.socket2.sock" if sig else None

    sock = None
    if sock_path and os.path.exists(sock_path):
        try:
            sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            sock.connect(sock_path)
            sock.settimeout(2.0)
        except Exception:
            sock = None

    while True:
        if sock:
            try:
                data = sock.recv(1024).decode(errors="ignore")
                if not data:
                    # Reconnect if closed
                    sock.close()
                    sock = None
                else:
                    # React to window or workspace changes
                    if any(ev in data for ev in ["activewindow>>", "closewindow>>", "workspace>>", "focusedmon>>"]):
                        emit_status()
            except socket.timeout:
                # Periodic verification
                emit_status()
            except Exception:
                if sock:
                    sock.close()
                sock = None
        else:
            time.sleep(1.0)
            emit_status()
            # Try to reconnect socket
            if sock_path and os.path.exists(sock_path):
                try:
                    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                    sock.connect(sock_path)
                    sock.settimeout(2.0)
                except Exception:
                    sock = None

if __name__ == "__main__":
    main()
