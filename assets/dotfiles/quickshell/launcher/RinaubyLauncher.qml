import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../"

PanelWindow {
    id: root

    visible: root.isOpen
    WlrLayershell.namespace: "rinauby-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // =========================================================================
    // STATE & MODE MANAGEMENT
    // =========================================================================
    property bool isOpen: false
    property string activeMode: "drun" // "drun" | "clipboard" | "powermenu" | "screenshot"
    property string searchQuery: ""
    property int selectedIndex: 0
    property string pendingScreenshotAction: ""

    readonly property string homeDir: Quickshell.env("HOME") || "/home/rifqi"
    readonly property string dotfilesDir: {
        if (typeof Caching !== "undefined" && Caching.serpantinumDir) {
            let p = Caching.serpantinumDir.replace(/\/quickshell\/?$/, "");
            if (p !== Caching.serpantinumDir) return p;
        }
        return "/home/rifqi/Workspace/Belajar/SO/Tubes-2604/Rancangan/assets/dotfiles";
    }
    readonly property string sessionIconsDir: Qt.resolvedUrl("../assets/icons/session/")
    readonly property string screenshotScriptPath: dotfilesDir + "/scripts/screenshot.sh"

    // =========================================================================
    // DYNAMIC THEME PALETTE SYNCHRONIZATION
    // =========================================================================
    property var barThemeData: ({})
    property string fileThemeMode: "classic"

    readonly property string themeMode: {
        if (barThemeData && barThemeData.themeMode) {
            return String(barThemeData.themeMode).toLowerCase();
        }
        return fileThemeMode || "classic";
    }
    readonly property bool isClassic: themeMode === "classic"

    readonly property color cBase: {
        if (barThemeData && barThemeData.rofiBgBase) return Qt.color(barThemeData.rofiBgBase);
        if (typeof ThemeBackend !== "undefined" && ThemeBackend.base) return ThemeBackend.base;
        return isClassic ? Qt.rgba(22 / 255, 26 / 255, 30 / 255, 1.0) : Qt.rgba(24 / 255, 24 / 255, 37 / 255, 1.0);
    }

    readonly property color cInput: {
        if (barThemeData && barThemeData.rofiBgInput) return Qt.color(barThemeData.rofiBgInput);
        if (typeof ThemeBackend !== "undefined" && ThemeBackend.crust) return ThemeBackend.crust;
        return isClassic ? Qt.rgba(14 / 255, 17 / 255, 20 / 255, 1.0) : Qt.rgba(17 / 255, 17 / 255, 27 / 255, 1.0);
    }

    readonly property color cAccent: {
        if (barThemeData && barThemeData.rofiAccent) return Qt.color(barThemeData.rofiAccent);
        if (typeof ThemeBackend !== "undefined" && ThemeBackend.blue) return ThemeBackend.blue;
        return isClassic ? Qt.color("#db9c5e") : Qt.color("#89b4fa");
    }

    readonly property color cFgMain: {
        if (barThemeData && barThemeData.rofiFgMain) return Qt.color(barThemeData.rofiFgMain);
        if (typeof ThemeBackend !== "undefined" && ThemeBackend.subtext0) return ThemeBackend.subtext0;
        return isClassic ? Qt.color("#d3c6aa") : Qt.color("#e2e2e6");
    }

    readonly property color bgBase: Qt.rgba(
        cBase.r,
        cBase.g,
        cBase.b,
        (barThemeData && barThemeData.rofiBgBaseAlpha !== undefined) ? Number(barThemeData.rofiBgBaseAlpha) : 0.96
    )

    readonly property color bgInput: Qt.rgba(
        cInput.r,
        cInput.g,
        cInput.b,
        (barThemeData && barThemeData.rofiBgInputAlpha !== undefined) ? Number(barThemeData.rofiBgInputAlpha) : 0.85
    )

    readonly property color bgSelected: Qt.rgba(
        cAccent.r,
        cAccent.g,
        cAccent.b,
        (barThemeData && barThemeData.rofiBgSelectedAlpha !== undefined)
            ? Number(barThemeData.rofiBgSelectedAlpha)
            : (isClassic ? 0.14 : 0.18)
    )

    readonly property color borderSubtle: isClassic
        ? Qt.rgba(1, 1, 1, 0.05)
        : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.18)

    readonly property color borderHairline: isClassic
        ? Qt.rgba(1, 1, 1, 0.04)
        : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.08)

    readonly property color accentGold: cAccent
    readonly property color accentGoldBright: {
        if (barThemeData && barThemeData.rofiAccentBright) return Qt.color(barThemeData.rofiAccentBright);
        return isClassic ? Qt.color("#e5c07b") : cAccent;
    }

    readonly property color fgMain: cFgMain
    readonly property color fgBright: {
        if (barThemeData && barThemeData.rofiFgBright) return Qt.color(barThemeData.rofiFgBright);
        return isClassic ? Qt.color("#fbf2db") : Qt.color("#ffffff");
    }
    readonly property color fgMuted: {
        if (barThemeData && barThemeData.rofiFgMuted) return Qt.color(barThemeData.rofiFgMuted);
        return isClassic ? Qt.color("#859289") : Qt.color("#8b9199");
    }

    function parseBarTheme(rawText) {
        if (!rawText || rawText.trim() === "") return;
        try {
            let parsed = JSON.parse(rawText);
            if (parsed && typeof parsed === "object") {
                root.barThemeData = parsed;
            }
        } catch (e) {}
    }

    FileView {
        id: barThemeFileView
        path: root.homeDir + "/.local/state/serpantinum/qs_bar_theme.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parseBarTheme(text())
    }

    FileView {
        id: themeModeFileView
        path: "/tmp/current_theme_mode"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            let m = text().trim().toLowerCase();
            if (m === "classic" || m === "modern") {
                root.fileThemeMode = m;
            }
        }
    }

    Connections {
        target: (typeof ThemeBackend !== "undefined") ? ThemeBackend : null
        function onBaseChanged() { barThemeFileView.reload(); }
        function onBlueChanged() { barThemeFileView.reload(); }
        function onSapphireChanged() { barThemeFileView.reload(); }
    }

    // =========================================================================
    // IPC HANDLER & PUBLIC API
    // =========================================================================
    function toggle(mode) {
        let targetMode = (mode && String(mode).trim() !== "") ? String(mode).trim() : "drun";
        if (root.isOpen && root.activeMode === targetMode) {
            root.close();
        } else {
            root.open(targetMode);
        }
    }

    function open(mode) {
        let targetMode = (mode && String(mode).trim() !== "") ? String(mode).trim() : "drun";
        barThemeFileView.reload();
        themeModeFileView.reload();

        root.activeMode = targetMode;
        root.searchQuery = "";
        root.selectedIndex = 0;

        if (drunInput) drunInput.text = "";
        if (screenshotInput) screenshotInput.text = "";

        if (targetMode === "drun") {
            root.loadApplications();
            root.updateDrunFilter("");
            if (drunListView) drunListView.contentY = 0;
        } else if (targetMode === "clipboard") {
            root.refreshClipboard();
            if (drunListView) drunListView.contentY = 0;
        } else if (targetMode === "screenshot") {
            root.updateScreenshotFilter("");
        } else if (targetMode === "powermenu") {
            root.selectedIndex = 0;
        }

        root.isOpen = true;
        root.grabModeFocus();
        focusTimerFast.restart();
        focusTimerSlow.restart();
    }

    function close() {
        root.isOpen = false;
        focusTimerFast.stop();
        focusTimerSlow.stop();
    }

    function drun() {
        root.toggle("drun");
    }

    function clipboard() {
        root.toggle("clipboard");
    }

    function powermenu() {
        root.toggle("powermenu");
    }

    function screenshot() {
        root.toggle("screenshot");
    }

    function grabModeFocus() {
        if (!root.isOpen) return;
        if (root.activeMode === "drun" || root.activeMode === "clipboard") {
            drunInput.forceActiveFocus();
        } else if (root.activeMode === "screenshot") {
            screenshotInput.forceActiveFocus();
        } else if (root.activeMode === "powermenu") {
            powermenuFocusScope.forceActiveFocus();
        }
    }

    Timer {
        id: focusTimerFast
        interval: 25
        repeat: false
        onTriggered: root.grabModeFocus()
    }

    Timer {
        id: focusTimerSlow
        interval: 100
        repeat: false
        onTriggered: root.grabModeFocus()
    }

    IpcHandler {
        target: "launcher"

        function toggle(mode: string) {
            root.toggle(mode);
        }

        function open(mode: string) {
            root.open(mode);
        }

        function close() {
            root.close();
        }

        function drun() {
            root.drun();
        }

        function clipboard() {
            root.clipboard();
        }

        function powermenu() {
            root.close();
            Quickshell.execDetached(["rinauby-powermenu"]);
        }

        function screenshot() {
            root.screenshot();
        }

        function reload() {
            barThemeFileView.reload();
            themeModeFileView.reload();
            root.loadApplications();
        }
    }

    // =========================================================================
    // DATA MODELS & LOGIC (DRUN, CLIPBOARD, POWERMENU, SCREENSHOT)
    // =========================================================================
    property var allApps: []
    property var clipboardEntries: []

    ListModel {
        id: filteredListModel
    }

    ListModel {
        id: screenshotListModel
    }

    readonly property var powermenuActions: [
        { label: "Lock", icon: "lock.svg", cmd: "loginctl lock-session" },
        { label: "Suspend", icon: "suspend.svg", cmd: "systemctl suspend" },
        { label: "Logout", icon: "logout.svg", cmd: "hyprctl dispatch exit" },
        { label: "Reboot", icon: "reboot.svg", cmd: "systemctl reboot" },
        { label: "Shutdown", icon: "shutdown.svg", cmd: "systemctl poweroff" }
    ]

    readonly property var screenshotActions: [
        { label: "󰹑  Layar Penuh (Simpan & Salin)", action: "full" },
        { label: "󰆞  Pilih Area (Interaktif)", action: "area" },
        { label: "󰖯  Jendela Aktif", action: "window" },
        { label: "󰔛  Tunda 3 Detik (Layar Penuh)", action: "delay3" },
        { label: "󰔝  Tunda 5 Detik (Layar Penuh)", action: "delay5" },
        { label: "󰉋  Buka Folder Screenshot", action: "folder" }
    ]

    Component.onCompleted: {
        loadApplications();
        updateDrunFilter("");
        updateScreenshotFilter("");
    }

    Connections {
        target: (typeof DesktopEntries !== "undefined") ? DesktopEntries : null
        function onApplicationsChanged() {
            root.loadApplications();
            if (root.isOpen && root.activeMode === "drun") {
                root.updateDrunFilter(root.searchQuery);
            }
        }
    }

    Connections {
        target: (typeof DesktopEntries !== "undefined" && DesktopEntries.applications) ? DesktopEntries.applications : null
        function onValuesChanged() {
            root.loadApplications();
            if (root.isOpen && root.activeMode === "drun") {
                root.updateDrunFilter(root.searchQuery);
            }
        }
    }

    function resolveIconSource(iconName) {
        if (!iconName || iconName === "") {
            let fallback = (typeof Quickshell !== "undefined" && typeof Quickshell.iconPath === "function")
                ? Quickshell.iconPath("application-x-executable", true)
                : "";
            if (fallback && fallback.startsWith("/")) return "file://" + fallback;
            return fallback || "";
        }
        if (iconName.startsWith("file://") || iconName.startsWith("image://") || iconName.startsWith("http://") || iconName.startsWith("https://")) {
            return iconName;
        }
        if (iconName.startsWith("/")) {
            return "file://" + iconName;
        }
        if (typeof Quickshell !== "undefined" && typeof Quickshell.iconPath === "function") {
            let resolved = Quickshell.iconPath(iconName, true);
            if (!resolved || resolved === "") {
                let stripped = iconName.replace(/\.(png|svg|xpm|ico)$/i, "");
                resolved = Quickshell.iconPath(stripped, true);
            }
            if (!resolved || resolved === "") {
                resolved = Quickshell.iconPath("application-x-executable", true);
            }
            if (resolved && resolved.length > 0) {
                return resolved.startsWith("/") ? ("file://" + resolved) : resolved;
            }
        }
        return "";
    }

    function loadApplications() {
        let list = [];
        if (typeof DesktopEntries !== "undefined" && DesktopEntries.applications && DesktopEntries.applications.values) {
            let entries = DesktopEntries.applications.values;
            let seenNames = ({});
            for (let i = 0; i < entries.length; i++) {
                let e = entries[i];
                if (!e || e.noDisplay) continue;
                let name = e.name || "";
                if (name === "" || seenNames[name]) continue;
                seenNames[name] = true;

                let generic = e.genericName || "";
                let comment = e.comment || "";
                let subtitle = generic !== "" ? generic : comment;
                let kw = (e.keywords && e.keywords.length > 0) ? e.keywords.join(" ") : "";

                list.push({
                    appId: e.id || "",
                    name: name,
                    genericName: generic,
                    comment: comment,
                    subtitle: subtitle,
                    keywords: kw,
                    icon: e.icon || "",
                    nameLower: name.toLowerCase(),
                    genericLower: generic.toLowerCase(),
                    commentLower: comment.toLowerCase(),
                    keywordsLower: kw.toLowerCase(),
                    idLower: (e.id || "").toLowerCase()
                });
            }
        }

        list.sort(function(a, b) {
            return a.name.localeCompare(b.name);
        });
        root.allApps = list;
    }

    function isFuzzySubsequence(needle, haystack) {
        if (!needle || !haystack) return false;
        let i = 0;
        let j = 0;
        while (i < needle.length && j < haystack.length) {
            if (needle[i] === haystack[j]) i++;
            j++;
        }
        return i === needle.length;
    }

    function scoreApplication(app, q) {
        if (q === "") return 1;
        let nameL = app.nameLower;
        let genL = app.genericLower;
        let comL = app.commentLower;
        let kwL = app.keywordsLower;
        let idL = app.idLower;

        if (nameL === q) return 100000;
        if (nameL.startsWith(q)) return 60000;

        // Word-boundary match in app name
        let wordIdx = nameL.indexOf(" " + q);
        if (wordIdx !== -1) return 45000 - wordIdx;

        let subIdx = nameL.indexOf(q);
        if (subIdx !== -1) return 30000 - subIdx * 10;

        if (genL === q || genL.startsWith(q)) return 22000;
        if (idL.indexOf(q) !== -1) return 18000;
        if (kwL.indexOf(q) !== -1) return 15000;
        if (genL.indexOf(q) !== -1) return 12000;
        if (comL.indexOf(q) !== -1) return 9000;
        if (isFuzzySubsequence(q, nameL)) return 2000;

        return 0;
    }

    function syncModel(targetModel, items) {
        targetModel.clear();
        for (let i = 0; i < items.length; i++) {
            targetModel.append(items[i]);
        }
    }

    function updateDrunFilter(queryText) {
        let raw = (queryText || "").trim();
        let q = raw.toLowerCase();
        let results = [];

        if (raw.startsWith(">")) {
            let cmd = raw.substring(1).trim();
            results.push({
                itemType: "command",
                appId: "",
                name: cmd !== "" ? ("> " + cmd) : "> ...",
                subtitle: cmd !== "" ? ("Run shell command: " + cmd) : "Type a shell command to execute",
                icon: "utilities-terminal",
                rawLine: cmd
            });
            syncModel(filteredListModel, results);
            root.selectedIndex = 0;
            return;
        }

        let scored = [];
        for (let i = 0; i < root.allApps.length; i++) {
            let app = root.allApps[i];
            let s = scoreApplication(app, q);
            if (s > 0) {
                scored.push({
                    score: s,
                    app: app
                });
            }
        }

        if (q !== "") {
            scored.sort(function(a, b) {
                if (b.score !== a.score) return b.score - a.score;
                return a.app.name.localeCompare(b.app.name);
            });
        }

        for (let j = 0; j < scored.length; j++) {
            let a = scored[j].app;
            results.push({
                itemType: "app",
                appId: a.appId,
                name: a.name,
                subtitle: a.subtitle || "",
                icon: a.icon || "",
                rawLine: ""
            });
        }

        syncModel(filteredListModel, results);
        root.selectedIndex = results.length > 0 ? 0 : -1;
        if (drunListView) drunListView.contentY = 0;
    }

    // Clipboard history loading & filtering
    Process {
        id: cliphistProcess
        running: false
        command: ["cliphist", "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                let parsed = [];
                let rawOutput = this.text || "";
                let lines = rawOutput.split("\n");
                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i];
                    if (!line || line.trim() === "") continue;
                    let cleaned = line.replace(/^\s*\d+\t/, "").trim();
                    if (cleaned === "") cleaned = line.trim();
                    parsed.push({
                        rawLine: line,
                        displayText: cleaned,
                        displayLower: cleaned.toLowerCase()
                    });
                }
                root.clipboardEntries = parsed;
                if (root.activeMode === "clipboard") {
                    root.updateClipboardFilter(root.searchQuery);
                }
            }
        }
    }

    function refreshClipboard() {
        if (cliphistProcess.running) {
            cliphistProcess.running = false;
        }
        cliphistProcess.running = true;
    }

    function updateClipboardFilter(queryText) {
        let q = (queryText || "").trim().toLowerCase();
        let results = [];

        for (let i = 0; i < root.clipboardEntries.length; i++) {
            let entry = root.clipboardEntries[i];
            if (q === "" || entry.displayLower.indexOf(q) !== -1 || isFuzzySubsequence(q, entry.displayLower)) {
                results.push({
                    itemType: "clipboard",
                    appId: "",
                    name: entry.displayText,
                    subtitle: "",
                    icon: "",
                    rawLine: entry.rawLine
                });
            }
            if (results.length >= 150) break;
        }

        syncModel(filteredListModel, results);
        root.selectedIndex = results.length > 0 ? 0 : -1;
        if (drunListView) drunListView.contentY = 0;
    }

    function updateScreenshotFilter(queryText) {
        let q = (queryText || "").trim().toLowerCase();
        let results = [];
        for (let i = 0; i < root.screenshotActions.length; i++) {
            let item = root.screenshotActions[i];
            if (q === "" || item.label.toLowerCase().indexOf(q) !== -1 || item.action.toLowerCase().indexOf(q) !== -1) {
                results.push({
                    label: item.label,
                    action: item.action
                });
            }
        }
        syncModel(screenshotListModel, results);
        root.selectedIndex = results.length > 0 ? 0 : -1;
    }

    // =========================================================================
    // ITEM ACTIVATION HANDLERS
    // =========================================================================
    function activateDrunOrClipboard(index) {
        if (root.activeMode === "clipboard") {
            if (index < 0 || index >= filteredListModel.count) return;
            let clipItem = filteredListModel.get(index);
            if (clipItem && clipItem.rawLine) {
                Quickshell.execDetached([
                    "sh",
                    "-c",
                    "printf '%s' \"$1\" | cliphist decode | wl-copy",
                    "--",
                    clipItem.rawLine
                ]);
            }
            root.close();
            return;
        }

        // Mode "drun"
        let rawQuery = (root.searchQuery || "").trim();
        if (rawQuery.startsWith(">")) {
            let cmd = rawQuery.substring(1).trim();
            if (cmd !== "") {
                Quickshell.execDetached(["sh", "-c", cmd]);
                root.close();
            }
            return;
        }

        if (index >= 0 && index < filteredListModel.count) {
            let item = filteredListModel.get(index);
            if (item.itemType === "command") {
                if (item.rawLine && item.rawLine !== "") {
                    Quickshell.execDetached(["sh", "-c", item.rawLine]);
                }
                root.close();
                return;
            }
            if (item && item.appId) {
                let entry = DesktopEntries.byId(item.appId);
                if (entry) {
                    entry.execute();
                }
                root.close();
                return;
            }
        }

        // Fallback: if no desktop app matched and user pressed Enter on a shell command
        if (rawQuery !== "" && filteredListModel.count === 0) {
            Quickshell.execDetached(["sh", "-c", rawQuery]);
            root.close();
        }
    }

    function activatePowermenu(index) {
        if (index < 0 || index >= root.powermenuActions.length) return;
        let item = root.powermenuActions[index];
        root.close();
        if (item && item.cmd) {
            Quickshell.execDetached(["sh", "-c", item.cmd]);
        }
    }

    Timer {
        id: screenshotDelayTimer
        interval: 220
        repeat: false
        onTriggered: {
            let act = root.pendingScreenshotAction;
            root.pendingScreenshotAction = "";
            if (!act || act === "") return;

            if (act === "folder") {
                Quickshell.execDetached([
                    "sh",
                    "-c",
                    "mkdir -p \"$HOME/Pictures/Screenshots\" && xdg-open \"$HOME/Pictures/Screenshots\""
                ]);
            } else {
                Quickshell.execDetached([root.screenshotScriptPath, act]);
            }
        }
    }

    function activateScreenshot(index) {
        if (index < 0 || index >= screenshotListModel.count) return;
        let item = screenshotListModel.get(index);
        if (!item || !item.action) return;
        root.pendingScreenshotAction = item.action;
        root.close();
        screenshotDelayTimer.restart();
    }

    // =========================================================================
    // FULL-SCREEN OVERLAY BACKDROP & ESCAPE HANDLER
    // =========================================================================
    Item {
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: function(event) {
            root.close();
            event.accepted = true;
        }

        // Clicking outside the centered modal card closes the launcher
        MouseArea {
            anchors.fill: parent
            enabled: root.isOpen
            onClicked: root.close()
        }

        // =====================================================================
        // MODE A & MODE B: "drun" & "clipboard" (renaissance_launcher.rasi 1:1)
        // =====================================================================
        Rectangle {
            id: drunModalCard
            visible: root.activeMode === "drun" || root.activeMode === "clipboard"
            anchors.centerIn: parent
            width: 680
            height: {
                let visibleRows = Math.min(6, filteredListModel.count);
                let listH = visibleRows > 0 ? (visibleRows * 60 + (visibleRows - 1) * 6) : 0;
                return 24 + 46 + (listH > 0 ? (16 + listH) : 0) + 24;
            }
            radius: 16
            color: root.bgBase
            border.width: 1
            border.color: root.borderSubtle

            // Prevent clicks inside the modal from closing the window
            MouseArea {
                anchors.fill: parent
                onClicked: function(mouse) { mouse.accepted = true; }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                // Inputbar (height: 46, padding: 12px 18px, radius: 10)
                Rectangle {
                    id: drunInputBar
                    width: parent.width
                    height: 46
                    radius: 10
                    color: root.bgInput
                    border.width: 1
                    border.color: root.borderHairline

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        anchors.topMargin: 12
                        anchors.bottomMargin: 12
                        spacing: 12

                        Text {
                            id: drunPrompt
                            text: root.activeMode === "clipboard" ? "󰅌 " : " "
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 16
                            color: root.accentGold
                            Layout.alignment: Qt.AlignVCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            TextInput {
                                id: drunInput
                                anchors.fill: parent
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: "Inter"
                                font.pixelSize: 16
                                color: root.fgBright
                                selectionColor: root.accentGold
                                selectedTextColor: root.bgBase
                                clip: true
                                focus: root.isOpen && (root.activeMode === "drun" || root.activeMode === "clipboard")

                                onTextChanged: {
                                    root.searchQuery = text;
                                    if (root.activeMode === "clipboard") {
                                        root.updateClipboardFilter(text);
                                    } else if (root.activeMode === "drun") {
                                        root.updateDrunFilter(text);
                                    }
                                }

                                Keys.onPressed: function(event) {
                                    if (event.key === Qt.Key_Escape) {
                                        root.close();
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                                        let count = filteredListModel.count;
                                        if (count > 0) {
                                            root.selectedIndex = (root.selectedIndex + 1) % count;
                                            drunListView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                                        }
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                                        let count = filteredListModel.count;
                                        if (count > 0) {
                                            root.selectedIndex = (root.selectedIndex - 1 + count) % count;
                                            drunListView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                                        }
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        root.activateDrunOrClipboard(root.selectedIndex);
                                        event.accepted = true;
                                    }
                                }
                            }

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                visible: drunInput.text.length === 0
                                text: root.activeMode === "clipboard"
                                    ? "Search clipboard history..."
                                    : "Search knowledge, tools, apps..."
                                font.family: "Inter"
                                font.pixelSize: 16
                                color: root.fgMuted
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                // Listview (lines: 6, dynamic: true, cycle: true, spacing: 6px)
                ListView {
                    id: drunListView
                    width: parent.width
                    height: {
                        let visibleCount = Math.min(6, filteredListModel.count);
                        return visibleCount * 60 + Math.max(0, visibleCount - 1) * 6;
                    }
                    visible: filteredListModel.count > 0
                    spacing: 6
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: filteredListModel
                    currentIndex: root.selectedIndex

                    delegate: Rectangle {
                        id: drunElement
                        required property int index
                        required property string itemType
                        required property string appId
                        required property string name
                        required property string subtitle
                        required property string icon
                        required property string rawLine

                        readonly property bool isSelected: index === root.selectedIndex

                        width: drunListView.width
                        height: 60
                        radius: 10
                        color: isSelected
                            ? root.bgSelected
                            : (itemMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent")

                        RowLayout {
                            anchors.fill: parent
                            anchors.topMargin: 10
                            anchors.bottomMargin: 10
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 16

                            // Element Icon (40x40)
                            Item {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                Layout.alignment: Qt.AlignVCenter

                                Image {
                                    id: appIconImg
                                    anchors.fill: parent
                                    visible: drunElement.itemType === "app" && status === Image.Ready
                                    source: drunElement.itemType === "app" ? root.resolveIconSource(drunElement.icon) : ""
                                    sourceSize: Qt.size(40, 40)
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    mipmap: true
                                    asynchronous: true
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: drunElement.itemType !== "app" || appIconImg.status !== Image.Ready
                                    text: drunElement.itemType === "clipboard"
                                        ? "󰅌"
                                        : (drunElement.itemType === "command" ? "󰆍" : "󰣆")
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 24
                                    color: drunElement.isSelected ? root.accentGoldBright : root.accentGold
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            // Element Text (Vertically centered column)
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: drunElement.name
                                    font.family: "Inter"
                                    font.pixelSize: 16
                                    font.weight: Font.Medium
                                    color: drunElement.isSelected ? root.fgBright : root.fgMain
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Text {
                                    Layout.fillWidth: true
                                    visible: drunElement.subtitle !== ""
                                    text: drunElement.subtitle
                                    font.family: "Inter"
                                    font.pixelSize: 13
                                    color: root.fgMuted
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: {
                                root.selectedIndex = drunElement.index;
                            }
                            onClicked: {
                                root.selectedIndex = drunElement.index;
                                root.activateDrunOrClipboard(drunElement.index);
                            }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // MODE C: "powermenu" (powermenu.rasi 1:1)
        // =====================================================================
        Rectangle {
            id: powermenuModalCard
            visible: root.activeMode === "powermenu"
            anchors.centerIn: parent
            width: 680
            height: 224
            radius: 16
            color: root.bgBase
            border.width: 1
            border.color: root.borderSubtle

            MouseArea {
                anchors.fill: parent
                onClicked: function(mouse) { mouse.accepted = true; }
            }

            FocusScope {
                id: powermenuFocusScope
                anchors.fill: parent
                focus: root.isOpen && root.activeMode === "powermenu"

                Keys.onPressed: function(event) {
                    let count = root.powermenuActions.length;
                    if (event.key === Qt.Key_Escape) {
                        root.close();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                        root.selectedIndex = (root.selectedIndex - 1 + count) % count;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                        root.selectedIndex = (root.selectedIndex + 1) % count;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        root.activatePowermenu(root.selectedIndex);
                        event.accepted = true;
                    }
                }

                Column {
                    anchors.fill: parent
                    anchors.topMargin: 26
                    anchors.bottomMargin: 28
                    anchors.leftMargin: 28
                    anchors.rightMargin: 28
                    spacing: 22

                    // Title (textbox-title)
                    Text {
                        width: parent.width
                        text: "RINAUBY — SESSION CONTROLS"
                        font.family: root.isClassic ? "Cinzel" : "Inter"
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        font.letterSpacing: 1.2
                        color: root.accentGoldBright
                        horizontalAlignment: Text.AlignHCenter
                    }

                    // Horizontal 5-Card List
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 16

                        Repeater {
                            model: root.powermenuActions

                            delegate: Rectangle {
                                id: powerCard
                                required property int index
                                required property var modelData

                                readonly property bool isSelected: index === root.selectedIndex

                                width: 112
                                height: 116
                                radius: 12
                                color: isSelected
                                    ? Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.22)
                                    : Qt.rgba(1, 1, 1, 0.04)
                                border.width: 1
                                border.color: isSelected ? root.accentGold : Qt.rgba(1, 1, 1, 0.05)

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 12

                                    Image {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 40
                                        height: 40
                                        source: root.sessionIconsDir + powerCard.modelData.icon
                                        sourceSize: Qt.size(40, 40)
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        mipmap: true
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: powerCard.modelData.label
                                        font.family: "Inter"
                                        font.pixelSize: 12
                                        font.weight: Font.Bold
                                        color: powerCard.isSelected ? root.fgBright : root.fgMain
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: {
                                        root.selectedIndex = powerCard.index;
                                    }
                                    onClicked: {
                                        root.selectedIndex = powerCard.index;
                                        root.activatePowermenu(powerCard.index);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // MODE D: "screenshot" (screenshot_menu.rasi 1:1)
        // =====================================================================
        Rectangle {
            id: screenshotModalCard
            visible: root.activeMode === "screenshot"
            anchors.centerIn: parent
            width: 460
            height: {
                let count = Math.min(6, screenshotListModel.count);
                let listH = count > 0 ? (count * 38 + (count - 1) * 6) : 0;
                return 20 + 38 + (listH > 0 ? (14 + listH) : 0) + 20;
            }
            radius: 14
            color: root.bgBase
            border.width: 1
            border.color: root.borderSubtle

            MouseArea {
                anchors.fill: parent
                onClicked: function(mouse) { mouse.accepted = true; }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                // Inputbar (height: 38, radius: 8, padding: 8px 14px)
                Rectangle {
                    width: parent.width
                    height: 38
                    radius: 8
                    color: root.bgInput
                    border.width: 1
                    border.color: root.borderHairline

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        anchors.topMargin: 8
                        anchors.bottomMargin: 8
                        spacing: 10

                        Text {
                            text: "󰄀 "
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 15
                            font.weight: Font.Bold
                            color: root.accentGoldBright
                            Layout.alignment: Qt.AlignVCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            TextInput {
                                id: screenshotInput
                                anchors.fill: parent
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                                color: root.fgBright
                                selectionColor: root.accentGold
                                selectedTextColor: root.bgBase
                                clip: true
                                focus: root.isOpen && root.activeMode === "screenshot"

                                onTextChanged: {
                                    root.searchQuery = text;
                                    root.updateScreenshotFilter(text);
                                }

                                Keys.onPressed: function(event) {
                                    let count = screenshotListModel.count;
                                    if (event.key === Qt.Key_Escape) {
                                        root.close();
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                                        if (count > 0) {
                                            root.selectedIndex = (root.selectedIndex + 1) % count;
                                        }
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                                        if (count > 0) {
                                            root.selectedIndex = (root.selectedIndex - 1 + count) % count;
                                        }
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        root.activateScreenshot(root.selectedIndex);
                                        event.accepted = true;
                                    }
                                }
                            }

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                visible: screenshotInput.text.length === 0
                                text: "Pilih aksi tangkapan layar..."
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                                color: root.fgMuted
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                // 6 Action Items (spacing: 6, each item height: 38, radius: 8, padding: 8px 12px)
                ListView {
                    id: screenshotListView
                    width: parent.width
                    height: {
                        let count = Math.min(6, screenshotListModel.count);
                        return count * 38 + Math.max(0, count - 1) * 6;
                    }
                    visible: screenshotListModel.count > 0
                    spacing: 6
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: screenshotListModel
                    currentIndex: root.selectedIndex

                    delegate: Rectangle {
                        id: shotElement
                        required property int index
                        required property string label
                        required property string action

                        readonly property bool isSelected: index === root.selectedIndex

                        width: screenshotListView.width
                        height: 38
                        radius: 8
                        color: isSelected
                            ? root.bgSelected
                            : (shotMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent")

                        Text {
                            anchors.fill: parent
                            anchors.topMargin: 8
                            anchors.bottomMargin: 8
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            verticalAlignment: Text.AlignVCenter
                            text: shotElement.label
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            color: shotElement.isSelected ? root.fgBright : root.fgMain
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: shotMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: {
                                root.selectedIndex = shotElement.index;
                            }
                            onClicked: {
                                root.selectedIndex = shotElement.index;
                                root.activateScreenshot(shotElement.index);
                            }
                        }
                    }
                }
            }
        }
    }
}
