#!/usr/bin/env bash

# ==============================================================================
# SCHOOL OF ATHENS — POWER MENU / SESSION CONTROLS
# Matches ui/renaissance_power_menu.png
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROFI_DIR="$(dirname "$SCRIPT_DIR")/rofi"
HYPR_DIR="$(dirname "$SCRIPT_DIR")/hypr"
ICONS_DIR="$ROFI_DIR/icons"
THEME_FILE="$ROFI_DIR/powermenu.rasi"
LOCK_CONF="$HYPR_DIR/hyprlock.conf"

# Entries format: LABEL\0icon\x1fPATH
OPTIONS="LOCK\0icon\x1f$ICONS_DIR/lock.svg
SUSPEND\0icon\x1f$ICONS_DIR/suspend.svg
LOGOUT\0icon\x1f$ICONS_DIR/logout.svg
REBOOT\0icon\x1f$ICONS_DIR/reboot.svg
SHUTDOWN\0icon\x1f$ICONS_DIR/shutdown.svg"

CHOSEN=$(echo -en "$OPTIONS" | rofi -dmenu -show-icons -theme "$THEME_FILE")

case "$CHOSEN" in
    "LOCK")
        if command -v hyprlock >/dev/null 2>&1; then
            hyprlock -c "$LOCK_CONF" &
        elif command -v gtklock >/dev/null 2>&1; then
            gtklock &
        elif command -v swaylock >/dev/null 2>&1; then
            swaylock &
        fi
        ;;
    "SUSPEND")
        systemctl suspend
        ;;
    "LOGOUT")
        hyprctl dispatch exit 2>/dev/null || pkill -KILL -u "$USER"
        ;;
    "REBOOT")
        systemctl reboot
        ;;
    "SHUTDOWN")
        systemctl poweroff
        ;;
    *)
        exit 0
        ;;
esac
