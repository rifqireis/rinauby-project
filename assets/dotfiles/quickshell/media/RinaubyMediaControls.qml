import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "../"

PanelWindow {
    id: root

    visible: root.isOpen
    WlrLayershell.namespace: "rinauby-mediacontrols"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
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
    // STATE & POSITIONING
    // =========================================================================
    property bool isOpen: false
    property real popupX: 180
    property real barHeight: 34

    readonly property string homeDir: Quickshell.env("HOME") || "/home/rifqi"

    // =========================================================================
    // DYNAMIC THEME PALETTE SYNCHRONIZATION
    // =========================================================================
    property var barThemeData: ({})
    property string fileThemeMode: "classic"

    readonly property string themeMode: {
        if (barThemeData && barThemeData.themeMode) {
            return String(barThemeData.themeMode).toLowerCase();
        }
        return fileThemeMode === "modern" ? "modern" : "classic";
    }
    readonly property bool isClassic: themeMode === "classic"

    readonly property color cBase: {
        if (barThemeData && barThemeData.rofiBgBase) return Qt.color(barThemeData.rofiBgBase);
        return isClassic ? Qt.color("#1c2125") : Qt.color("#111416");
    }
    readonly property color cAccent: {
        if (barThemeData && barThemeData.accent) return Qt.color(barThemeData.accent);
        return isClassic ? Qt.color("#db9c5e") : Qt.color("#9accf9");
    }
    readonly property color cFgMain: {
        if (barThemeData && barThemeData.rofiFgMain) return Qt.color(barThemeData.rofiFgMain);
        return isClassic ? Qt.color("#d3c6aa") : Qt.color("#e2e2e6");
    }

    readonly property color bgOverlay: Qt.rgba(0, 0, 0, 0.35)
    readonly property color cardBg: isClassic ? Qt.rgba(0.11, 0.13, 0.15, 0.96) : Qt.rgba(0.07, 0.08, 0.09, 0.94)
    readonly property color cardBorder: isClassic ? Qt.rgba(0.86, 0.61, 0.37, 0.40) : Qt.rgba(0.60, 0.80, 0.98, 0.35)
    readonly property color accentGold: cAccent
    readonly property color accentGoldBright: isClassic ? Qt.color("#e5c07b") : cAccent
    readonly property color fgMain: cFgMain
    readonly property color fgBright: isClassic ? Qt.color("#fbf2db") : Qt.color("#ffffff")
    readonly property color fgMuted: isClassic ? Qt.color("#859289") : Qt.color("#8b9199")

    FileView {
        id: barThemeWatcher
        path: root.homeDir + "/.local/state/serpantinum/qs_bar_theme.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            let txt = text().trim();
            if (txt !== "") {
                try {
                    root.barThemeData = JSON.parse(txt);
                } catch(e) {}
            }
        }
    }

    FileView {
        id: tmpModeWatcher
        path: "/tmp/current_theme_mode"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            let m = text().trim().toLowerCase();
            if (m === "modern" || m === "classic") {
                root.fileThemeMode = m;
            }
        }
    }

    function reloadTheme() {
        barThemeWatcher.reload();
        tmpModeWatcher.reload();
    }

    // =========================================================================
    // ACTIVE MPRIS PLAYER DISCOVERY & TRACKING
    // =========================================================================
    readonly property var playersList: {
        if (!Mpris.players || !Mpris.players.values) return [];
        return Mpris.players.values.filter(p => p !== null && p !== undefined);
    }

    readonly property MprisPlayer activePlayer: {
        let list = playersList;
        if (list.length === 0) return null;
        let playing = list.find(p => p.isPlaying);
        if (playing) return playing;
        let withTitle = list.find(p => p.trackTitle && p.trackTitle.trim() !== "");
        if (withTitle) return withTitle;
        let controllable = list.find(p => p.canControl);
        if (controllable) return controllable;
        return list[0];
    }

    readonly property bool hasPlayer: activePlayer !== null
    readonly property bool isPlaying: activePlayer ? (activePlayer.isPlaying === true) : false
    readonly property string rawTitle: activePlayer ? (activePlayer.trackTitle || "") : ""
    readonly property string rawArtist: activePlayer ? (activePlayer.trackArtist || "") : ""
    readonly property string rawAlbum: {
        if (!activePlayer || !activePlayer.metadata) return "";
        return String(activePlayer.metadata["xesam:album"] || "");
    }
    readonly property string artUrl: {
        if (!activePlayer) return "";
        if (activePlayer.trackArtUrl && activePlayer.trackArtUrl !== "") return activePlayer.trackArtUrl;
        if (activePlayer.metadata) {
            let m = activePlayer.metadata;
            if (m["mpris:artUrl"]) return String(m["mpris:artUrl"]);
            if (m["artUrl"]) return String(m["artUrl"]);
            if (m["xesam:url"] && typeof m["xesam:url"] === "string" && (m["xesam:url"].startsWith("http") || m["xesam:url"].startsWith("file://"))) {
                if (m["xesam:url"].match(/\.(jpg|jpeg|png|webp)$/i)) return String(m["xesam:url"]);
            }
        }
        return "";
    }

    readonly property real playerPosition: activePlayer ? (activePlayer.position || 0) : 0
    readonly property real playerLength: activePlayer ? (activePlayer.length || 0) : 0
    readonly property bool isLiveStream: playerLength > 1000000000 || playerLength <= 0

    Timer {
        id: positionTicker
        interval: 500
        running: root.isOpen && root.isPlaying && !root.isLiveStream
        repeat: true
        onTriggered: {
            if (root.activePlayer && typeof root.activePlayer.positionChanged === "function") {
                root.activePlayer.positionChanged();
            }
        }
    }

    function cleanTrackTitle(title) {
        if (!title || title.trim() === "") return "No Track Playing";
        return title
            .replace(/\s*[\(\[](official\s*(music\s*)?video|video|audio|lyrics|hd|4k|remastered)[\)\]]/gi, "")
            .replace(/\s*-\s*YouTube$/i, "")
            .trim();
    }

    function formatSeconds(seconds) {
        if (!seconds || isNaN(seconds) || seconds <= 0) return "00:00";
        let s = Math.floor(seconds);
        let m = Math.floor(s / 60);
        let remSec = s % 60;
        let mm = m < 10 ? ("0" + m) : ("" + m);
        let ss = remSec < 10 ? ("0" + remSec) : ("" + remSec);
        return mm + ":" + ss;
    }

    function openAt(targetX: real) {
        root.reloadTheme();
        if (typeof targetX === "number" && !isNaN(targetX)) {
            root.popupX = targetX;
        }
        root.isOpen = true;
        focusScope.forceActiveFocus();
    }

    function open() {
        openAt(root.popupX);
    }

    function close() {
        root.isOpen = false;
    }

    function toggle(targetX: real) {
        if (root.isOpen) {
            root.close();
        } else {
            root.openAt(targetX);
        }
    }

    // =========================================================================
    // IPC HANDLER
    // =========================================================================
    IpcHandler {
        target: "mediacontrols"

        function toggle(targetX: real) {
            root.toggle(targetX);
        }

        function open(targetX: real) {
            root.openAt(targetX);
        }

        function close() {
            root.close();
        }

        function reload() {
            root.reloadTheme();
        }
    }

    // =========================================================================
    // DISMISSABLE BACKDROP
    // =========================================================================
    Rectangle {
        anchors.fill: parent
        color: root.bgOverlay

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    // =========================================================================
    // POPUP CONTENT CONTAINER
    // =========================================================================
    FocusScope {
        id: focusScope
        anchors.fill: parent
        focus: root.isOpen

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                root.close();
                event.accepted = true;
            } else if (event.key === Qt.Key_Space) {
                if (root.activePlayer && typeof root.activePlayer.togglePlaying === "function") {
                    root.activePlayer.togglePlaying();
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Left) {
                if (root.activePlayer && typeof root.activePlayer.previous === "function") {
                    root.activePlayer.previous();
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Right) {
                if (root.activePlayer && typeof root.activePlayer.next === "function") {
                    root.activePlayer.next();
                    event.accepted = true;
                }
            }
        }

        Item {
            id: cardWrapper
            width: 440
            height: root.hasPlayer ? 180 : 130
            x: Math.max(16, Math.min(root.popupX, root.width - cardWrapper.width - 16))
            y: root.barHeight + 6

            // Intercept clicks on card to avoid backdrop dismiss
            MouseArea {
                anchors.fill: parent
                onClicked: function(mouse) { mouse.accepted = true; }
            }

            Rectangle {
                id: cardBgItem
                anchors.fill: parent
                radius: root.isClassic ? 12 : 16
                color: root.cardBg
                border.width: 1
                border.color: root.cardBorder

                // Header Top Strip (Renaissance Gold or Modern Accent)
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 2
                    color: root.accentGold
                    opacity: 0.75
                    radius: 2
                }

                // Inner Padding Layout
                Item {
                    anchors.fill: parent
                    anchors.margins: 14

                    // CASE 1: NO PLAYER ACTIVE
                    ColumnLayout {
                        anchors.centerIn: parent
                        visible: !root.hasPlayer
                        spacing: 8

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "󰎈"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 32
                            color: root.accentGold
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "No Media Player Active"
                            font.family: root.isClassic ? "Cinzel" : "Inter"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            color: root.fgBright
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Start playback in Spotify, Brave, or your music player"
                            font.family: "Inter"
                            font.pixelSize: 11
                            color: root.fgMuted
                        }
                    }

                    // CASE 2: ACTIVE PLAYER CONTROLS
                    RowLayout {
                        anchors.fill: parent
                        visible: root.hasPlayer
                        spacing: 14

                        // Album Art Square
                        Rectangle {
                            id: albumArtFrame
                            Layout.preferredWidth: 140
                            Layout.preferredHeight: 140
                            Layout.alignment: Qt.AlignVCenter
                            radius: root.isClassic ? 8 : 12
                            clip: true
                            color: Qt.rgba(0, 0, 0, 0.4)
                            border.width: 1
                            border.color: Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.25)

                            Image {
                                id: albumImage
                                anchors.fill: parent
                                source: root.artUrl
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: false
                                visible: root.artUrl !== "" && status === Image.Ready
                            }

                            // Fallback art container
                            Rectangle {
                                anchors.fill: parent
                                visible: root.artUrl === "" || albumImage.status !== Image.Ready
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.15) }
                                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.6) }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: root.isPlaying ? "󰎆" : "󰐊"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 42
                                    color: root.accentGold
                                    opacity: 0.85
                                }
                            }
                        }

                        // Track Metadata & Controls Column
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 4

                            // Top Info: Player Identity Badge
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text {
                                    text: "󰎆 NOW PLAYING"
                                    font.family: root.isClassic ? "Cinzel" : "Inter"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1.0
                                    color: root.accentGoldBright
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: root.activePlayer ? (root.activePlayer.identity || "Media") : ""
                                    font.family: "Inter"
                                    font.pixelSize: 10
                                    color: root.fgMuted
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: 100
                                }
                            }

                            // Track Title
                            Text {
                                Layout.fillWidth: true
                                text: root.cleanTrackTitle(root.rawTitle)
                                font.family: root.isClassic ? "EB Garamond" : "Inter"
                                font.pixelSize: root.isClassic ? 15 : 14
                                font.weight: Font.Bold
                                color: root.fgBright
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            // Artist & Album
                            Text {
                                Layout.fillWidth: true
                                text: root.rawArtist !== "" ? (root.rawArtist + (root.rawAlbum !== "" ? (" • " + root.rawAlbum) : "")) : (root.rawAlbum !== "" ? root.rawAlbum : "Unknown Artist")
                                font.family: "Inter"
                                font.pixelSize: 11
                                color: root.fgMuted
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            Item { Layout.fillHeight: true }

                            // Playback Progress Bar & Time
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                // Time Row
                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        text: root.isLiveStream ? "LIVE" : root.formatSeconds(root.playerPosition)
                                        font.family: "Inter"
                                        font.pixelSize: 10
                                        font.weight: Font.Medium
                                        color: root.isLiveStream ? root.accentGold : root.fgMuted
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        text: root.isLiveStream ? "●" : root.formatSeconds(root.playerLength)
                                        font.family: "Inter"
                                        font.pixelSize: 10
                                        color: root.isLiveStream ? "#e67e80" : root.fgMuted
                                    }
                                }

                                // Interactive Progress Track
                                Rectangle {
                                    id: progressTrack
                                    Layout.fillWidth: true
                                    height: 6
                                    radius: 3
                                    color: Qt.rgba(1, 1, 1, 0.12)

                                    // Active Fill
                                    Rectangle {
                                        id: progressFill
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        radius: 3
                                        color: root.accentGold
                                        width: {
                                            if (root.isLiveStream) return progressTrack.width;
                                            if (root.playerLength <= 0) return 0;
                                            let ratio = Math.max(0.0, Math.min(1.0, root.playerPosition / root.playerLength));
                                            return progressTrack.width * ratio;
                                        }
                                    }

                                    MouseArea {
                                        id: progressMouse
                                        anchors.fill: parent
                                        cursorShape: root.isLiveStream ? Qt.ArrowCursor : Qt.PointingHandCursor
                                        enabled: !root.isLiveStream && (root.activePlayer ? root.activePlayer.canSeek : true)

                                        onClicked: function(mouse) {
                                            if (!root.activePlayer || root.isLiveStream || root.playerLength <= 0) return;
                                            let ratio = Math.max(0.0, Math.min(1.0, mouse.x / progressTrack.width));
                                            let newPos = ratio * root.playerLength;
                                            root.activePlayer.position = newPos;
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }

                            // Control Buttons Row (Previous, Play/Pause, Next)
                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 18

                                // Previous Button
                                Rectangle {
                                    id: btnPrev
                                    width: 32
                                    height: 32
                                    radius: 16
                                    color: prevMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰒮"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 16
                                        color: prevMouse.containsMouse ? root.fgBright : root.fgMain
                                    }

                                    MouseArea {
                                        id: prevMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.activePlayer && typeof root.activePlayer.previous === "function") {
                                                root.activePlayer.previous();
                                            }
                                        }
                                    }
                                }

                                // Play / Pause Button
                                Rectangle {
                                    id: btnPlayPause
                                    width: 40
                                    height: 40
                                    radius: 20
                                    color: playMouse.containsMouse ? root.accentGoldBright : root.accentGold
                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.isPlaying ? "󰏤" : "󰐊"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 18
                                        color: root.isClassic ? "#1c2125" : "#111416"
                                    }

                                    MouseArea {
                                        id: playMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.activePlayer && typeof root.activePlayer.togglePlaying === "function") {
                                                root.activePlayer.togglePlaying();
                                            }
                                        }
                                    }
                                }

                                // Next Button
                                Rectangle {
                                    id: btnNext
                                    width: 32
                                    height: 32
                                    radius: 16
                                    color: nextMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰒭"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 16
                                        color: nextMouse.containsMouse ? root.fgBright : root.fgMain
                                    }

                                    MouseArea {
                                        id: nextMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.activePlayer && typeof root.activePlayer.next === "function") {
                                                root.activePlayer.next();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
