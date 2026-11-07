import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import ".."

Scope {
    id: root

    readonly property string homeDir: Quickshell.env("HOME") || "/home/rifqi"
    readonly property string stateDir: (typeof Caching !== "undefined" && Caching.stateDir)
        ? Caching.stateDir
        : (homeDir + "/.local/state/serpantinum")

    // =========================================================================
    // 1. THEME & USER CONFIGURATION STATE
    // =========================================================================
    property string rawThemeMode: ""
    property string tmpThemeMode: "modern"
    readonly property string themeMode: {
        let m = (rawThemeMode !== "" ? rawThemeMode : tmpThemeMode).toLowerCase().trim();
        return m === "classic" ? "classic" : "modern";
    }
    readonly property bool isClassic: themeMode === "classic"

    property var themeJson: ({})

    // Permanent Dark Shell Bar invariant (Aturan 10): barBg must NEVER be light/white
    function sanitizeDarkHex(candidate, fallbackHex) {
        if (!candidate || typeof candidate !== "string") return fallbackHex;
        let s = candidate.trim();
        let m6 = /^#([0-9a-fA-F]{6})$/.exec(s);
        if (m6) {
            let hex = m6[1];
            let r = parseInt(hex.slice(0, 2), 16);
            let g = parseInt(hex.slice(2, 4), 16);
            let b = parseInt(hex.slice(4, 6), 16);
            let lum = 0.299 * r + 0.587 * g + 0.114 * b;
            if (lum > 85) return fallbackHex;
            return "#" + hex.toLowerCase();
        }
        let m8 = /^#([0-9a-fA-F]{8})$/.exec(s);
        if (m8) {
            let hex = m8[1];
            let r = parseInt(hex.slice(2, 4), 16);
            let g = parseInt(hex.slice(4, 6), 16);
            let b = parseInt(hex.slice(6, 8), 16);
            let lum = 0.299 * r + 0.587 * g + 0.114 * b;
            if (lum > 85) return fallbackHex;
            return "#" + hex.toLowerCase();
        }
        return fallbackHex;
    }

    function pickStr(key, modernDef, classicDef) {
        let defVal = root.isClassic ? classicDef : modernDef;
        if (root.themeJson && typeof root.themeJson[key] === "string" && root.themeJson[key].trim() !== "") {
            return root.themeJson[key].trim();
        }
        return defVal;
    }

    function pickNum(key, modernDef, classicDef) {
        let defVal = root.isClassic ? classicDef : modernDef;
        if (root.themeJson && root.themeJson[key] !== undefined && root.themeJson[key] !== null) {
            let n = Number(root.themeJson[key]);
            if (!isNaN(n)) return n;
        }
        return defVal;
    }

    readonly property string barBg: sanitizeDarkHex(
        root.themeJson ? root.themeJson.barBg : "",
        root.isClassic ? "#1c2125" : "#111416"
    )
    readonly property real barBgAlpha: pickNum("barBgAlpha", 0.85, 0.82)
    readonly property string barFg: pickStr("barFg", "#e2e2e6", "#d3c6aa")
    readonly property string barFgBright: pickStr("barFgBright", "#ffffff", "#fbf2db")
    readonly property string barBorderSide: pickStr("barBorderSide", "transparent", "#38b8864e")
    readonly property string barBorderBottom: pickStr("barBorderBottom", "transparent", "#db9c5e")
    readonly property string accent: pickStr("accent", "#9accf9", "#db9c5e")
    readonly property string accentGold: pickStr("accentGold", "#9accf9", "#e5c07b")
    readonly property string wsActive: pickStr("wsActive", "#003351", "#e5c07b")
    readonly property string wsInactive: pickStr("wsInactive", "#8b9199", "#859289")
    readonly property string wsHoverBg: pickStr("wsHoverBg", "#9accf9", "#e5c07b")
    readonly property real wsHoverBgAlpha: pickNum("wsHoverBgAlpha", 0.14, 0.10)
    readonly property string wsActiveBg: pickStr("wsActiveBg", "#9accf9", "#e5c07b")
    readonly property real wsActiveBgAlpha: pickNum("wsActiveBgAlpha", 1.0, 0.15)
    readonly property string sepColor: pickStr("sepColor", "#1fffffff", "#4db8864e")
    readonly property string tooltipBg: sanitizeDarkHex(
        root.themeJson ? root.themeJson.tooltipBg : "",
        root.isClassic ? "#181c1f" : "#111416"
    )
    readonly property real tooltipBgAlpha: pickNum("tooltipBgAlpha", 0.95, 0.95)
    readonly property string tooltipBorder: pickStr("tooltipBorder", "#9accf9", "#b8864e")
    readonly property real tooltipBorderAlpha: pickNum("tooltipBorderAlpha", 0.30, 0.45)
    readonly property string windowTitleAppColor: pickStr("windowTitleAppColor", "#ffffff", "#a7c080")
    readonly property string mutedColor: pickStr("mutedColor", "#f38ba8", "#e67e80")
    readonly property string criticalColor: pickStr("criticalColor", "#f38ba8", "#e67e80")

    readonly property color barBgColor: root.barBg
    readonly property color wsActiveBgColor: root.wsActiveBg
    readonly property color wsHoverBgColor: root.wsHoverBg
    readonly property color tooltipBgColor: root.tooltipBg
    readonly property color tooltipBorderColor: root.tooltipBorder

    // User preferences from ~/.config/rinauby/config.json
    property string barPosition: "top"
    property int barHeight: 34
    property bool rotateQuotes: true
    property bool showTitleWhenIdle: true
    property var romanWorkspacesOverride: null
    property bool showTelemetry: true

    readonly property bool useRomanWorkspaces: romanWorkspacesOverride !== null
        ? Boolean(romanWorkspacesOverride)
        : root.isClassic

    onIsClassicChanged: {
        root.romanWorkspacesOverride = null;
    }

    // Dynamic state from /tmp files
    property string wallpaperTitle: "Desktop"
    property string currentQuote: "La Rinascita"

    readonly property var quotesList: [
        "Ad Fontes",
        "Cerca il Vero",
        "Cognoscere Causas",
        "La Rinascita",
        "Sapere Aude",
        "Carpe Diem",
        "L'Uomo Universale",
        "Veritas Vos Liberabit",
        "Cogito Ergo Sum",
        "Ars Longa Vita Brevis"
    ]

    // MPRIS Active Player & Track Title Tracking
    readonly property var mprisPlayersList: {
        if (!Mpris.players || !Mpris.players.values) return [];
        return Mpris.players.values.filter(p => p !== null && p !== undefined);
    }

    readonly property MprisPlayer barActivePlayer: {
        let list = mprisPlayersList;
        if (list.length === 0) return null;
        let playing = list.find(p => p.isPlaying);
        if (playing) return playing;
        let withTitle = list.find(p => p.trackTitle && p.trackTitle.trim() !== "");
        if (withTitle) return withTitle;
        let controllable = list.find(p => p.canControl);
        if (controllable) return controllable;
        return list[0];
    }

    readonly property bool hasMediaPlaying: barActivePlayer !== null && barActivePlayer.trackTitle && barActivePlayer.trackTitle.trim() !== ""
    readonly property string rawMediaTitle: hasMediaPlaying ? barActivePlayer.trackTitle : ""
    readonly property string rawMediaArtist: (hasMediaPlaying && barActivePlayer.trackArtist) ? barActivePlayer.trackArtist : ""
    readonly property bool isMediaPlayingState: hasMediaPlaying && barActivePlayer.isPlaying === true

    function cleanBarMediaTitle(title) {
        if (!title) return "";
        return title
            .replace(/\s*[\(\[](official\s*(music\s*)?video|video|audio|lyrics|hd|4k|remastered)[\)\]]/gi, "")
            .replace(/\s*-\s*YouTube$/i, "")
            .trim();
    }

    function parseBarTheme(txt) {
        if (!txt || txt.trim() === "") return;
        try {
            let parsed = JSON.parse(txt);
            if (parsed && typeof parsed === "object") {
                root.themeJson = parsed;
                if (typeof parsed.themeMode === "string") {
                    let tm = parsed.themeMode.toLowerCase().trim();
                    if (tm === "classic" || tm === "modern") {
                        root.rawThemeMode = tm;
                    }
                }
            }
        } catch (e) {}
    }

    function parseRinaubyConfig(txt) {
        if (!txt || txt.trim() === "") return;
        try {
            let cfg = JSON.parse(txt);
            if (!cfg || typeof cfg !== "object") return;

            let pos = (cfg.waybar && cfg.waybar.position !== undefined)
                ? String(cfg.waybar.position).toLowerCase().trim()
                : (cfg.barPosition !== undefined ? String(cfg.barPosition).toLowerCase().trim() : "top");
            root.barPosition = (pos === "bottom") ? "bottom" : "top";

            let h = (cfg.waybar && cfg.waybar.height !== undefined)
                ? Number(cfg.waybar.height)
                : (cfg.barHeight !== undefined ? Number(cfg.barHeight) : 34);
            if (isNaN(h)) h = 34;
            root.barHeight = Math.max(24, Math.min(48, Math.round(h)));

            if (cfg.waybar && cfg.waybar.rotate_quotes !== undefined) {
                root.rotateQuotes = Boolean(cfg.waybar.rotate_quotes);
            } else if (cfg.rotateQuotes !== undefined) {
                root.rotateQuotes = Boolean(cfg.rotateQuotes);
            } else {
                root.rotateQuotes = true;
            }

            if (cfg.waybar_show_title !== undefined) {
                root.showTitleWhenIdle = Boolean(cfg.waybar_show_title);
            } else if (cfg.waybar && cfg.waybar.show_title !== undefined) {
                root.showTitleWhenIdle = Boolean(cfg.waybar.show_title);
            } else if (cfg.showTitleWhenIdle !== undefined) {
                root.showTitleWhenIdle = Boolean(cfg.showTitleWhenIdle);
            } else {
                root.showTitleWhenIdle = true;
            }

            if (cfg.romanWorkspacesOverride !== undefined && cfg.romanWorkspacesOverride !== null) {
                root.romanWorkspacesOverride = Boolean(cfg.romanWorkspacesOverride);
            } else if (cfg.rinauby && cfg.rinauby.roman_workspaces !== undefined && cfg.rinauby.roman_workspaces !== null) {
                root.romanWorkspacesOverride = Boolean(cfg.rinauby.roman_workspaces);
            } else {
                root.romanWorkspacesOverride = null;
            }

            if (cfg.waybar_telemetry !== undefined) {
                root.showTelemetry = Boolean(cfg.waybar_telemetry);
            } else if (cfg.waybar && cfg.waybar.telemetry !== undefined) {
                root.showTelemetry = Boolean(cfg.waybar.telemetry);
            } else if (cfg.showTelemetry !== undefined) {
                root.showTelemetry = Boolean(cfg.showTelemetry);
            } else {
                root.showTelemetry = true;
            }
        } catch (e) {}
    }

    function rotateQuote() {
        let current = root.currentQuote;
        let candidates = [];
        for (let i = 0; i < root.quotesList.length; i++) {
            if (root.quotesList[i] !== current) {
                candidates.push(root.quotesList[i]);
            }
        }
        if (candidates.length === 0) candidates = root.quotesList;
        let idx = Math.floor(Math.random() * candidates.length);
        let nextQ = candidates[idx];
        root.currentQuote = nextQ;
        Quickshell.execDetached(["sh", "-c", "printf '%s\\n' \"$1\" > /tmp/current_renaissance_quote", "--", nextQ]);
    }

    function reloadAll() {
        barThemeFile.reload();
        themeModeFile.reload();
        wallpaperTitleFile.reload();
        quoteFile.reload();
        rinaubyConfigFile.reload();
        root.refreshAudioFallback();
        root.refreshBatteryFallback();
    }

    // =========================================================================
    // 2. FILE WATCHERS & TIMERS
    // =========================================================================
    FileView {
        id: barThemeFile
        path: root.stateDir + "/qs_bar_theme.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parseBarTheme(text())
    }

    FileView {
        id: themeModeFile
        path: "/tmp/current_theme_mode"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            let t = text().trim().toLowerCase();
            if (t === "classic" || t === "modern") {
                root.tmpThemeMode = t;
            }
        }
    }

    FileView {
        id: wallpaperTitleFile
        path: "/tmp/current_wallpaper_title"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            let t = text().trim();
            root.wallpaperTitle = t !== "" ? t : "Desktop";
        }
    }

    FileView {
        id: quoteFile
        path: "/tmp/current_renaissance_quote"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            let t = text().trim();
            if (t !== "") {
                root.currentQuote = t;
            }
        }
    }

    FileView {
        id: rinaubyConfigFile
        path: root.homeDir + "/.config/rinauby/config.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parseRinaubyConfig(text())
    }

    // Periodic 2s reload for /tmp atomic file replacements
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            themeModeFile.reload();
            wallpaperTitleFile.reload();
            quoteFile.reload();
            barThemeFile.reload();
        }
    }

    // 180s Quote Rotator Timer
    Timer {
        interval: 180000
        running: root.rotateQuotes
        repeat: true
        onTriggered: root.rotateQuote()
    }

    // =========================================================================
    // 3. WINDOW TITLE & WORKSPACES STATE
    // =========================================================================
    readonly property var sortedWorkspaces: {
        let raw = (typeof Hyprland !== "undefined" && Hyprland.workspaces && Hyprland.workspaces.values)
            ? Hyprland.workspaces.values
            : [];
        let arr = [];
        for (let i = 0; i < raw.length; i++) {
            let ws = raw[i];
            if (ws && ws.id > 0) {
                arr.push(ws);
            }
        }
        arr.sort(function(a, b) { return a.id - b.id; });
        if (arr.length === 0) {
            let fId = (typeof Hyprland !== "undefined" && Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id > 0)
                ? Hyprland.focusedWorkspace.id
                : 1;
            arr.push({ id: fId, name: String(fId), urgent: false });
        }
        return arr;
    }

    readonly property var romanNumerals: ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]

    function formatWorkspaceLabel(ws) {
        if (!ws) return "1";
        let id = ws.id;
        if (root.useRomanWorkspaces) {
            return root.romanNumerals[id - 1] || ws.name || id.toString();
        }
        return id.toString();
    }

    readonly property string activeWindowTitle: {
        if (typeof CurrentFocus !== "undefined" && !CurrentFocus.isDesktop && CurrentFocus.appClass !== "Quickshell" && CurrentFocus.windowTitle !== "") {
            return CurrentFocus.windowTitle;
        }
        if (typeof Hyprland !== "undefined" && Hyprland.activeToplevel && Hyprland.activeToplevel.title) {
            let t = String(Hyprland.activeToplevel.title).trim();
            if (t !== "" && t.toLowerCase().indexOf("qs-master") === -1 && t.toLowerCase().indexOf("quickshell") === -1) {
                return t;
            }
        }
        return "";
    }

    readonly property string activeWindowClass: {
        if (typeof CurrentFocus !== "undefined" && !CurrentFocus.isDesktop && CurrentFocus.appClass !== "Quickshell" && CurrentFocus.appClass !== "") {
            return CurrentFocus.appClass;
        }
        if (typeof Hyprland !== "undefined" && Hyprland.activeToplevel) {
            let ipc = Hyprland.activeToplevel.lastIpcObject || {};
            let c = ipc["class"] || ipc.initialClass || (Hyprland.activeToplevel.wayland ? Hyprland.activeToplevel.wayland.appId : "");
            if (c) return String(c).trim();
        }
        return "";
    }

    readonly property bool hasActiveWindow: activeWindowTitle !== ""

    function truncateTitle(text) {
        if (!text) return "";
        return text.length > 36 ? text.slice(0, 35) + "…" : text;
    }

    // =========================================================================
    // 4. AUDIO & BATTERY TELEMETRY + FALLBACKS
    // =========================================================================
    property int pactlVol: 50
    property bool pactlMuted: false
    property string pactlDesc: "Default Output"

    function refreshAudioFallback() {
        if (!audioPollProc.running) {
            audioPollProc.running = true;
        }
    }

    Process {
        id: audioPollProc
        command: [
            "sh", "-c",
            "vol=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oE '[0-9]+%' | head -n1 | tr -d '%'); " +
            "mute=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | awk '{print $2}'); " +
            "desc=$(pactl list sinks 2>/dev/null | grep -A20 \"Name: $(pactl get-default-sink 2>/dev/null)\" | grep -m1 'Description:' | sed 's/.*Description: //'); " +
            "printf '%s|%s|%s\\n' \"${vol:-50}\" \"${mute:-no}\" \"${desc:-Audio Output}\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let line = text.trim();
                if (!line) return;
                let parts = line.split("|");
                if (parts.length >= 2) {
                    let v = parseInt(parts[0], 10);
                    if (!isNaN(v)) root.pactlVol = Math.max(0, Math.min(150, v));
                    root.pactlMuted = (parts[1].trim().toLowerCase() === "yes");
                }
                if (parts.length >= 3 && parts[2].trim() !== "") {
                    root.pactlDesc = parts[2].trim();
                }
            }
        }
    }

    Timer {
        id: pactlRefreshTimer
        interval: 120
        repeat: false
        onTriggered: root.refreshAudioFallback()
    }

    readonly property int effectiveVol: {
        if (typeof Audio !== "undefined" && Audio.defaultSink && Audio.defaultSink.audio && Audio.defaultSink.audio.volume !== undefined) {
            let v = Number(Audio.defaultSink.audio.volume);
            if (!isNaN(v) && v >= 0) {
                return Math.round(v * 100);
            }
        }
        return root.pactlVol;
    }

    readonly property bool effectiveMuted: {
        if (typeof Audio !== "undefined" && Audio.defaultSink && Audio.defaultSink.audio && Audio.defaultSink.audio.muted !== undefined) {
            return Boolean(Audio.defaultSink.audio.muted);
        }
        return root.pactlMuted;
    }

    readonly property string effectiveSinkDesc: {
        if (typeof Audio !== "undefined" && Audio.defaultSink) {
            let name = Audio.getNodeName(Audio.defaultSink);
            if (name && name !== "Unknown Device") return name;
        }
        return root.pactlDesc;
    }

    readonly property string audioIcon: {
        let d = root.effectiveSinkDesc.toLowerCase();
        if (d.indexOf("headphone") !== -1 || d.indexOf("headset") !== -1 || d.indexOf("hands-free") !== -1) {
            return "󰋋";
        }
        if (root.effectiveVol < 33) return "󰕿";
        if (root.effectiveVol < 66) return "󰖀";
        return "󰕾";
    }

    readonly property string audioDisplayText: root.effectiveMuted
        ? "󰝟  Muted"
        : (root.audioIcon + "  " + root.effectiveVol + "%")

    readonly property string audioTooltipText: "Volume: " + root.effectiveVol + "%\nSink: " + root.effectiveSinkDesc

    // Battery state + sysfs fallback
    property int sysBatCap: 100
    property bool sysBatCharging: false
    property real sysBatPower: 0.0

    function refreshBatteryFallback() {
        if (!batPollProc.running) {
            batPollProc.running = true;
        }
    }

    Process {
        id: batPollProc
        command: [
            "sh", "-c",
            "bat=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1); " +
            "if [ -n \"$bat\" ]; then " +
            "  cap=$(cat \"$bat/capacity\" 2>/dev/null || echo 100); " +
            "  st=$(cat \"$bat/status\" 2>/dev/null || echo Unknown); " +
            "  pw=$(cat \"$bat/power_now\" 2>/dev/null || echo 0); " +
            "  printf '%s|%s|%s\\n' \"$cap\" \"$st\" \"$pw\"; " +
            "else " +
            "  printf '100|Full|0\\n'; " +
            "fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let line = text.trim();
                if (!line) return;
                let parts = line.split("|");
                if (parts.length >= 2) {
                    let c = parseInt(parts[0], 10);
                    if (!isNaN(c)) root.sysBatCap = Math.max(0, Math.min(100, c));
                    let st = parts[1].trim().toLowerCase();
                    root.sysBatCharging = (st === "charging" || st === "full" || st === "not charging");
                }
                if (parts.length >= 3) {
                    let uw = parseFloat(parts[2]);
                    if (!isNaN(uw) && uw > 0) {
                        root.sysBatPower = uw / 1000000.0;
                    }
                }
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: {
            root.refreshAudioFallback();
            root.refreshBatteryFallback();
        }
    }

    readonly property int batPct: {
        if (UPower.displayDevice && UPower.displayDevice.ready) {
            let raw = Number(UPower.displayDevice.percentage);
            if (!isNaN(raw) && raw > 0) {
                let pct = (raw <= 1.0) ? Math.round(raw * 100) : Math.round(raw);
                return Math.max(0, Math.min(100, pct));
            }
        }
        return root.sysBatCap;
    }

    readonly property bool batCharging: {
        if (UPower.displayDevice && UPower.displayDevice.ready) {
            let st = UPower.displayDevice.state;
            return st === UPowerDeviceState.Charging ||
                   st === UPowerDeviceState.FullyCharged ||
                   st === UPowerDeviceState.PendingCharge;
        }
        return root.sysBatCharging;
    }

    readonly property var batDischargeIcons: ["󰁺", "󰁼", "󰁾", "󰂀", "󰁹"]

    readonly property string batDisplayText: {
        if (root.batCharging) {
            return "󰂄  " + root.batPct + "%";
        }
        let idx = Math.min(4, Math.max(0, Math.floor(root.batPct / 20)));
        return root.batDischargeIcons[idx] + "  " + root.batPct + "%";
    }

    readonly property string batTooltipText: {
        let timeStr = root.batCharging ? "Mengisi daya" : "Menggunakan baterai";
        let powerW = root.sysBatPower;
        if (UPower.displayDevice && UPower.displayDevice.ready) {
            let secs = root.batCharging ? Number(UPower.displayDevice.timeToFull) : Number(UPower.displayDevice.timeToEmpty);
            if (!isNaN(secs) && secs > 60) {
                let hrs = Math.floor(secs / 3600);
                let mins = Math.floor((secs % 3600) / 60);
                if (hrs > 0) {
                    timeStr = hrs + "h " + mins + "m " + (root.batCharging ? "until full" : "remaining");
                } else {
                    timeStr = mins + "m " + (root.batCharging ? "until full" : "remaining");
                }
            } else if (root.batCharging && root.batPct >= 99) {
                timeStr = "Fully charged";
            }
            let cr = Math.abs(Number(UPower.displayDevice.changeRate) || 0);
            if (cr > 0) powerW = cr;
        }
        return timeStr + "\nDaya: " + powerW.toFixed(1) + " W";
    }

    // =========================================================================
    // 5. CLOCK & MONTHLY CALENDAR TOOLTIP
    // =========================================================================
    property var currentDate: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.currentDate = new Date()
    }

    readonly property string clockDisplayText: {
        let d = root.currentDate;
        const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        let dayName = days[d.getDay()];
        let dd = String(d.getDate()).padStart(2, "0");
        let monName = months[d.getMonth()];
        let hh = String(d.getHours()).padStart(2, "0");
        let mm = String(d.getMinutes()).padStart(2, "0");
        return dayName + ", " + dd + " " + monName + "  " + hh + ":" + mm;
    }

    readonly property string calendarTooltipHtml: {
        let d = root.currentDate;
        let year = d.getFullYear();
        let month = d.getMonth();
        let today = d.getDate();

        const monthNames = [
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December"
        ];
        let headerColor = root.isClassic ? root.accentGold : root.accent;
        let weekColor = root.isClassic ? "#e5c07b" : "#b4befe";
        let dayColor = root.barFg;
        let todayBg = root.isClassic ? root.accentGold : root.accent;
        let todayFg = root.isClassic ? "#1c2124" : "#11111b";

        let firstDay = new Date(year, month, 1).getDay();
        let daysInMonth = new Date(year, month + 1, 0).getDate();

        let titleStr = monthNames[month] + " " + year;
        let padLeft = Math.max(0, Math.floor((20 - titleStr.length) / 2));
        let centeredTitle = " ".repeat(padLeft) + titleStr;

        let html = "<pre style=\"margin:0; font-family:'JetBrainsMono Nerd Font', monospace; font-size:11.5px; line-height:1.35;\">";
        html += "<span style=\"color:" + headerColor + "; font-weight:bold;\">" + centeredTitle + "</span>\n";
        html += "<span style=\"color:" + weekColor + "; font-weight:bold;\">Su Mo Tu We Th Fr Sa</span>\n";

        let col = 0;
        for (let i = 0; i < firstDay; i++) {
            html += "   ";
            col++;
        }

        for (let day = 1; day <= daysInMonth; day++) {
            let cell = day < 10 ? (" " + day) : String(day);
            if (day === today) {
                html += "<span style=\"background-color:" + todayBg + "; color:" + todayFg + "; font-weight:bold;\">" + cell + "</span>";
            } else {
                html += "<span style=\"color:" + dayColor + ";\">" + cell + "</span>";
            }
            col++;
            if (col === 7 && day < daysInMonth) {
                html += "\n";
                col = 0;
            } else if (day < daysInMonth) {
                html += " ";
            }
        }
        html += "</pre>";
        return html;
    }

    // =========================================================================
    // 6. IPC HANDLERS (targets: "waybar" & "rinaubybar")
    // =========================================================================
    IpcHandler {
        target: "waybar"

        function reload() {
            root.reloadAll();
        }

        function toggle() {
            root.visible = !root.visible;
        }

        function open() {
            root.visible = true;
        }

        function close() {
            root.visible = false;
        }

        function rotateQuote() {
            root.rotateQuote();
        }

        function setPosition(pos: string) {
            let p = String(pos || "").toLowerCase().trim();
            root.barPosition = (p === "bottom") ? "bottom" : "top";
        }

        function setHeight(h: string) {
            let val = parseInt(h, 10);
            if (!isNaN(val)) {
                root.barHeight = Math.max(24, Math.min(48, val));
            }
        }
    }

    IpcHandler {
        target: "rinaubybar"

        function reload() {
            root.reloadAll();
        }

        function toggle() {
            root.visible = !root.visible;
        }

        function open() {
            root.visible = true;
        }

        function close() {
            root.visible = false;
        }

        function rotateQuote() {
            root.rotateQuote();
        }

        function setPosition(pos: string) {
            let p = String(pos || "").toLowerCase().trim();
            root.barPosition = (p === "bottom") ? "bottom" : "top";
        }

        function setHeight(h: string) {
            let val = parseInt(h, 10);
            if (!isNaN(val)) {
                root.barHeight = Math.max(24, Math.min(48, val));
            }
        }
    }

    Component.onCompleted: {
        root.reloadAll();
    }

    // =========================================================================
    // 7. MULTI-SCREEN PANEL WINDOWS + FLOATING TOOLTIP
    // =========================================================================
    Variants {
        model: Quickshell.screens

        delegate: Component {
            Scope {
                id: screenScope
                required property var modelData

                property string pendingTooltipText: ""
                property bool pendingTooltipRich: false
                property real pendingTooltipCenterX: 0
                property string activeTooltipText: ""
                property bool activeTooltipRich: false
                property real activeTooltipCenterX: 0
                property bool tooltipShown: false

                Timer {
                    id: tooltipShowTimer
                    interval: 250
                    repeat: false
                    onTriggered: {
                        screenScope.activeTooltipText = screenScope.pendingTooltipText;
                        screenScope.activeTooltipRich = screenScope.pendingTooltipRich;
                        screenScope.activeTooltipCenterX = screenScope.pendingTooltipCenterX;
                        screenScope.tooltipShown = (screenScope.activeTooltipText !== "");
                    }
                }

                function showTooltip(item, text, isRich) {
                    if (!text || text === "") {
                        hideTooltip();
                        return;
                    }
                    let pos = item ? item.mapToItem(barContent, item.width / 2, 0) : { x: 100 };
                    screenScope.pendingTooltipCenterX = pos.x;
                    screenScope.pendingTooltipText = text;
                    screenScope.pendingTooltipRich = Boolean(isRich);
                    if (screenScope.tooltipShown) {
                        screenScope.activeTooltipCenterX = screenScope.pendingTooltipCenterX;
                        screenScope.activeTooltipText = screenScope.pendingTooltipText;
                        screenScope.activeTooltipRich = screenScope.pendingTooltipRich;
                    } else {
                        tooltipShowTimer.restart();
                    }
                }

                function hideTooltip() {
                    tooltipShowTimer.stop();
                    screenScope.tooltipShown = false;
                    screenScope.pendingTooltipText = "";
                }

                PanelWindow {
                    id: barWindow
                    screen: screenScope.modelData

                    WlrLayershell.namespace: "waybar"
                    WlrLayershell.layer: WlrLayer.Top

                    anchors {
                        top: root.barPosition !== "bottom"
                        bottom: root.barPosition === "bottom"
                        left: true
                        right: true
                    }

                    implicitHeight: root.barHeight
                    exclusiveZone: root.barHeight
                    color: "transparent"

                    Rectangle {
                        id: barContent
                        anchors.fill: parent
                        color: Qt.rgba(root.barBgColor.r, root.barBgColor.g, root.barBgColor.b, root.barBgAlpha)

                        // Classic side borders
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 1
                            visible: root.isClassic
                            color: root.barBorderSide
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 1
                            visible: root.isClassic
                            color: root.barBorderSide
                        }

                        // Classic bottom border line
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: root.isClassic ? 2 : 0
                            visible: root.isClassic
                            color: root.barBorderBottom
                        }

                        // -----------------------------------------------------
                        // 1. LEFT SECTION: Logo, Workspaces, Separator, Title
                        // -----------------------------------------------------
                        Row {
                            id: leftSection
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            height: parent.height
                            spacing: 0

                            // Launcher Button (custom/logo)
                            Item {
                                id: logoContainer
                                height: parent.height
                                width: (root.isClassic ? 14 : 12) + logoPad.width + (root.isClassic ? 8 : 6)

                                Item {
                                    id: logoPad
                                    anchors.left: parent.left
                                    anchors.leftMargin: root.isClassic ? 14 : 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: logoText.implicitWidth + (root.isClassic ? 4 : 8)
                                    height: parent.height

                                    Text {
                                        id: logoText
                                        anchors.centerIn: parent
                                        text: root.isClassic ? "" : "󰀻"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: root.isClassic ? 15 : 16
                                        color: logoMouse.containsMouse ? root.barFgBright : root.accent
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }

                                    MouseArea {
                                        id: logoMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        readonly property string tipText: root.isClassic ? "Menu (Click to Launch)" : "Aplikasi"
                                        onEntered: screenScope.showTooltip(logoPad, tipText, false)
                                        onExited: screenScope.hideTooltip()
                                        onClicked: Quickshell.execDetached(["rinauby-launcher"])
                                    }
                                }
                            }

                            // Workspaces (hyprland/workspaces)
                            Item {
                                id: workspacesWrapper
                                height: parent.height
                                width: wsRow.implicitWidth + (root.isClassic ? 4 : 8)

                                Row {
                                    id: wsRow
                                    anchors.centerIn: parent
                                    spacing: root.isClassic ? 2 : 4

                                    Repeater {
                                        model: root.sortedWorkspaces

                                        delegate: Rectangle {
                                            id: wsButton
                                            required property var modelData
                                            readonly property int wsId: modelData ? modelData.id : 1
                                            readonly property bool isActive: Boolean(
                                                typeof Hyprland !== "undefined" &&
                                                Hyprland.focusedWorkspace &&
                                                Hyprland.focusedWorkspace.id === wsId
                                            )
                                            readonly property bool isUrgent: Boolean(modelData && modelData.urgent)
                                            readonly property bool hovered: wsMouse.containsMouse

                                            height: root.isClassic ? (root.barHeight - 6) : (root.barHeight - 8)
                                            width: Math.max(26, wsLabel.implicitWidth + 18)
                                            radius: root.isClassic ? 4 : 6
                                            anchors.verticalCenter: parent.verticalCenter

                                            color: {
                                                if (isUrgent) {
                                                    return root.isClassic ? Qt.rgba(0.90, 0.49, 0.50, 0.2) : "#f38ba8";
                                                }
                                                if (isActive) {
                                                    return Qt.rgba(root.wsActiveBgColor.r, root.wsActiveBgColor.g, root.wsActiveBgColor.b, root.wsActiveBgAlpha);
                                                }
                                                if (hovered) {
                                                    return Qt.rgba(root.wsHoverBgColor.r, root.wsHoverBgColor.g, root.wsHoverBgColor.b, root.wsHoverBgAlpha);
                                                }
                                                return "transparent";
                                            }
                                            Behavior on color { ColorAnimation { duration: 180 } }

                                            Text {
                                                id: wsLabel
                                                anchors.centerIn: parent
                                                text: root.formatWorkspaceLabel(wsButton.modelData)
                                                font.family: root.isClassic ? "Cinzel" : "Inter"
                                                font.pixelSize: root.isClassic ? 14 : 12
                                                font.weight: wsButton.isActive ? Font.Bold : Font.DemiBold
                                                font.letterSpacing: root.isClassic ? 0.8 : 0.2
                                                color: {
                                                    if (wsButton.isUrgent) {
                                                        return root.isClassic ? "#e67e80" : "#11111b";
                                                    }
                                                    if (wsButton.isActive) {
                                                        return root.wsActive;
                                                    }
                                                    if (wsButton.hovered) {
                                                        return root.barFgBright;
                                                    }
                                                    return root.wsInactive;
                                                }
                                                Behavior on color { ColorAnimation { duration: 180 } }
                                            }

                                            MouseArea {
                                                id: wsMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (typeof Hyprland !== "undefined" && Hyprland.dispatch) {
                                                        Hyprland.dispatch("workspace " + wsButton.wsId);
                                                    }
                                                    Quickshell.execDetached(["hyprctl", "dispatch", "workspace", wsButton.wsId.toString()]);
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Left Separator (custom/separator-left)
                            Item {
                                height: parent.height
                                width: sepLeftText.implicitWidth + (root.isClassic ? 24 : 16)

                                Text {
                                    id: sepLeftText
                                    anchors.centerIn: parent
                                    text: "│"
                                    color: root.sepColor
                                    font.family: "Inter"
                                    font.pixelSize: root.isClassic ? 13 : 11
                                }
                            }

                            // Window Title / Wallpaper Title (custom/window-title)
                            Item {
                                id: winTitleContainer
                                visible: root.hasActiveWindow || root.showTitleWhenIdle
                                height: parent.height
                                width: visible ? winTitleText.implicitWidth : 0

                                readonly property string fullTooltip: root.hasActiveWindow
                                    ? ((root.activeWindowClass !== "" ? (root.activeWindowClass + ": ") : "") + root.activeWindowTitle)
                                    : ("Wallpaper: " + root.wallpaperTitle)

                                Text {
                                    id: winTitleText
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.hasActiveWindow
                                        ? root.truncateTitle(root.activeWindowTitle)
                                        : root.wallpaperTitle
                                    font.family: root.hasActiveWindow
                                        ? (root.isClassic ? "EB Garamond" : "Inter")
                                        : (root.isClassic ? "Cinzel" : "Inter")
                                    font.pixelSize: root.isClassic ? 13 : 12
                                    font.weight: (!root.hasActiveWindow && root.isClassic) ? Font.DemiBold : Font.Medium
                                    font.letterSpacing: root.hasActiveWindow ? 0.2 : 0.3
                                    color: root.hasActiveWindow
                                        ? (root.isClassic ? root.windowTitleAppColor : root.barFgBright)
                                        : (root.isClassic ? root.accentGold : root.accent)
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    id: winTitleMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: screenScope.showTooltip(winTitleContainer, winTitleContainer.fullTooltip, false)
                                    onExited: screenScope.hideTooltip()
                                }

                                onFullTooltipChanged: {
                                    if (winTitleMouse.containsMouse) {
                                        screenScope.showTooltip(winTitleContainer, winTitleContainer.fullTooltip, false);
                                    }
                                }
                            }

                            // Media Separator (visible when both winTitle and mediaTitle are present)
                            Item {
                                visible: root.hasMediaPlaying && (root.hasActiveWindow || root.showTitleWhenIdle)
                                height: parent.height
                                width: visible ? (sepMediaText.implicitWidth + (root.isClassic ? 20 : 14)) : 0

                                Text {
                                    id: sepMediaText
                                    anchors.centerIn: parent
                                    text: "│"
                                    color: root.sepColor
                                    font.family: "Inter"
                                    font.pixelSize: root.isClassic ? 13 : 11
                                }
                            }

                            // Media Player Title Module (custom/mediaTitle)
                            Item {
                                id: mediaTitle
                                visible: root.hasMediaPlaying
                                height: parent.height
                                width: visible ? (mediaRow.implicitWidth + (root.isClassic ? 16 : 12)) : 0
                                clip: true

                                Row {
                                    id: mediaRow
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Text {
                                        id: mediaIcon
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.isMediaPlayingState ? "󰎆" : "󰐊"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: root.isClassic ? 13 : 12
                                        color: mediaMouse.containsMouse ? root.barFgBright : root.accent
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }

                                    Text {
                                        id: mediaTitleText
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: {
                                            let clean = root.cleanBarMediaTitle(root.rawMediaTitle);
                                            let display = clean;
                                            if (root.rawMediaArtist !== "") display += " • " + root.rawMediaArtist;
                                            return root.truncateTitle(display);
                                        }
                                        font.family: root.isClassic ? "EB Garamond" : "Inter"
                                        font.pixelSize: root.isClassic ? 13 : 12
                                        font.weight: Font.Medium
                                        color: mediaMouse.containsMouse ? root.accentGoldBright : root.barFgBright
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                }

                                MouseArea {
                                    id: mediaMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                                    readonly property string mediaTipText: {
                                        let tip = "Media: " + root.rawMediaTitle;
                                        if (root.rawMediaArtist !== "") tip += "\nArtist: " + root.rawMediaArtist;
                                        tip += "\n(Click: Media Player Controls • Middle: Play/Pause • Right: Next)";
                                        return tip;
                                    }

                                    onEntered: screenScope.showTooltip(mediaTitle, mediaTipText, false)
                                    onExited: screenScope.hideTooltip()

                                    onClicked: function(mouse) {
                                        if (mouse.button === Qt.LeftButton) {
                                            let pos = null;
                                            try {
                                                pos = mediaTitle.mapToItem(null, 0, 0);
                                            } catch(e) {}
                                            let targetX = pos ? pos.x : 200;
                                            Quickshell.execDetached(["rinauby-mediacontrols", "toggle", String(targetX)]);
                                        } else if (mouse.button === Qt.MiddleButton) {
                                            if (root.barActivePlayer && typeof root.barActivePlayer.togglePlaying === "function") {
                                                root.barActivePlayer.togglePlaying();
                                            }
                                        } else if (mouse.button === Qt.RightButton) {
                                            if (root.barActivePlayer && typeof root.barActivePlayer.next === "function") {
                                                root.barActivePlayer.next();
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // -----------------------------------------------------
                        // 2. CENTER SECTION: Philosophical Motto (custom/quote)
                        // -----------------------------------------------------
                        Item {
                            id: quoteContainer
                            anchors.centerIn: parent
                            height: parent.height
                            width: quoteText.implicitWidth + 28

                            Text {
                                id: quoteText
                                anchors.centerIn: parent
                                text: root.currentQuote
                                font.family: root.isClassic ? "Cinzel" : "Inter"
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                font.letterSpacing: root.isClassic ? 0.8 : 0.4
                                color: quoteMouse.containsMouse ? root.accent : root.barFgBright
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }

                            MouseArea {
                                id: quoteMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: screenScope.showTooltip(quoteContainer, "Philosophy & Quotes\n(Click to rotate)", false)
                                onExited: screenScope.hideTooltip()
                                onClicked: root.rotateQuote()
                            }
                        }

                        // -----------------------------------------------------
                        // 3. RIGHT SECTION: Audio, Battery, Separator, Clock
                        // -----------------------------------------------------
                        Row {
                            id: rightSection
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: parent.height
                            spacing: 0

                            // PulseAudio / PipeWire (pulseaudio)
                            Item {
                                id: audioContainer
                                visible: root.showTelemetry
                                height: parent.height
                                width: visible ? (audioText.implicitWidth + (root.isClassic ? 14 : 16) + 4) : 0

                                Text {
                                    id: audioText
                                    anchors.centerIn: parent
                                    text: root.audioDisplayText
                                    font.family: "Inter"
                                    font.pixelSize: root.isClassic ? 13 : 12
                                    font.weight: Font.Medium
                                    color: {
                                        if (root.effectiveMuted) return root.mutedColor;
                                        if (audioMouse.containsMouse) return root.barFgBright;
                                        return root.barFg;
                                    }
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    id: audioMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onEntered: screenScope.showTooltip(audioContainer, root.audioTooltipText, false)
                                    onExited: screenScope.hideTooltip()
                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.RightButton) {
                                            Quickshell.execDetached(["rinauby-syspanel"]);
                                        } else {
                                            let targetMute = !root.effectiveMuted;
                                            if (typeof Audio !== "undefined" && Audio.defaultSink && Audio.defaultSink.audio) {
                                                Audio.defaultSink.audio.muted = targetMute;
                                            }
                                            Quickshell.execDetached(["pactl", "set-sink-mute", "@DEFAULT_SINK@", targetMute ? "1" : "0"]);
                                            pactlRefreshTimer.restart();
                                        }
                                    }
                                    onWheel: (wheel) => {
                                        if (wheel.angleDelta.y > 0) {
                                            Quickshell.execDetached(["pactl", "set-sink-volume", "@DEFAULT_SINK@", "+5%"]);
                                        } else if (wheel.angleDelta.y < 0) {
                                            Quickshell.execDetached(["pactl", "set-sink-volume", "@DEFAULT_SINK@", "-5%"]);
                                        }
                                        pactlRefreshTimer.restart();
                                    }
                                }

                                Connections {
                                    target: root
                                    function onAudioTooltipTextChanged() {
                                        if (audioMouse.containsMouse) {
                                            screenScope.showTooltip(audioContainer, root.audioTooltipText, false);
                                        }
                                    }
                                }
                            }

                            // Battery (battery)
                            Item {
                                id: batteryContainer
                                visible: root.showTelemetry
                                height: parent.height
                                width: visible ? (batteryText.implicitWidth + (root.isClassic ? 14 : 16) + 4) : 0

                                Text {
                                    id: batteryText
                                    anchors.centerIn: parent
                                    text: root.batDisplayText
                                    font.family: "Inter"
                                    font.pixelSize: root.isClassic ? 13 : 12
                                    font.weight: Font.Medium
                                    color: {
                                        if (!root.batCharging && root.batPct <= 15) return root.criticalColor;
                                        if (!root.batCharging && root.batPct <= 30) return root.isClassic ? root.accentGold : root.accent;
                                        if (batteryMouse.containsMouse) return root.barFgBright;
                                        return root.barFg;
                                    }
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    id: batteryMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: screenScope.showTooltip(batteryContainer, root.batTooltipText, false)
                                    onExited: screenScope.hideTooltip()
                                    onClicked: Quickshell.execDetached(["rinauby-syspanel"])
                                }

                                Connections {
                                    target: root
                                    function onBatTooltipTextChanged() {
                                        if (batteryMouse.containsMouse) {
                                            screenScope.showTooltip(batteryContainer, root.batTooltipText, false);
                                        }
                                    }
                                }
                            }

                            // Right Separator (custom/separator-right)
                            Item {
                                height: parent.height
                                width: sepRightText.implicitWidth + (root.isClassic ? 24 : 16)

                                Text {
                                    id: sepRightText
                                    anchors.centerIn: parent
                                    text: "│"
                                    color: root.sepColor
                                    font.family: "Inter"
                                    font.pixelSize: root.isClassic ? 13 : 11
                                }
                            }

                            // Clock (clock)
                            Item {
                                id: clockContainer
                                height: parent.height
                                width: clockPad.width + (root.isClassic ? 14 : 12)

                                Item {
                                    id: clockPad
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: parent.height
                                    width: clockText.implicitWidth + (root.isClassic ? 14 : 16)

                                    Text {
                                        id: clockText
                                        anchors.centerIn: parent
                                        text: root.clockDisplayText
                                        font.family: root.isClassic ? "Cinzel" : "Inter"
                                        font.pixelSize: root.isClassic ? 13 : 12
                                        font.weight: Font.DemiBold
                                        color: clockMouse.containsMouse
                                            ? root.barFgBright
                                            : (root.isClassic ? root.accentGold : root.accent)
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }

                                    MouseArea {
                                        id: clockMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        onEntered: screenScope.showTooltip(clockPad, root.calendarTooltipHtml, true)
                                        onExited: screenScope.hideTooltip()
                                        onClicked: (mouse) => {
                                            if (mouse.button === Qt.RightButton) {
                                                Quickshell.execDetached(["bash", "-c", "quickshell -c rs ipc call main handleCommand calendar '' '' 2>/dev/null || quickshell ipc call main handleCommand calendar '' ''"]);
                                            } else {
                                                Quickshell.execDetached(["rinauby-syspanel"]);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // -------------------------------------------------------------
                // 4. FLOATING TOOLTIP OVERLAY WINDOW
                // -------------------------------------------------------------
                PanelWindow {
                    id: tooltipWindow
                    screen: screenScope.modelData
                    visible: screenScope.tooltipShown && screenScope.activeTooltipText !== ""

                    WlrLayershell.namespace: "waybar-tooltip"
                    WlrLayershell.layer: WlrLayer.Overlay
                    focusable: false
                    exclusionMode: ExclusionMode.Ignore
                    color: "transparent"

                    anchors {
                        top: root.barPosition !== "bottom"
                        bottom: root.barPosition === "bottom"
                        left: true
                        right: true
                    }

                    margins {
                        top: root.barPosition !== "bottom" ? (root.barHeight + 6) : 0
                        bottom: root.barPosition === "bottom" ? (root.barHeight + 6) : 0
                    }

                    implicitHeight: tooltipBox.height + 8
                    mask: Region {}

                    Rectangle {
                        id: tooltipBox
                        width: tooltipLabel.implicitWidth + 20
                        height: tooltipLabel.implicitHeight + 12
                        x: Math.max(8, Math.min(tooltipWindow.width - width - 8, Math.round(screenScope.activeTooltipCenterX - width / 2)))
                        y: root.barPosition === "bottom" ? (tooltipWindow.height - height) : 0

                        radius: 6
                        color: Qt.rgba(root.tooltipBgColor.r, root.tooltipBgColor.g, root.tooltipBgColor.b, root.tooltipBgAlpha)
                        border.width: 1
                        border.color: Qt.rgba(root.tooltipBorderColor.r, root.tooltipBorderColor.g, root.tooltipBorderColor.b, root.tooltipBorderAlpha)

                        Text {
                            id: tooltipLabel
                            anchors.centerIn: parent
                            text: screenScope.activeTooltipText
                            textFormat: screenScope.activeTooltipRich ? Text.RichText : Text.PlainText
                            color: root.barFg
                            font.family: root.isClassic ? "EB Garamond" : "Inter"
                            font.pixelSize: root.isClassic ? 13 : 12
                        }
                    }
                }
            }
        }
    }
}
