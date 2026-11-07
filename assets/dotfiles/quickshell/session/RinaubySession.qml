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
    WlrLayershell.namespace: "rinauby-session"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    color: root.bgOverlay

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // =========================================================================
    // STATE MANAGEMENT
    // =========================================================================
    property bool isOpen: false
    property int selectedIndex: 0

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
        return isClassic ? Qt.color("#161a1e") : Qt.color("#111416");
    }
    readonly property color cAccent: {
        if (barThemeData && barThemeData.accent) return Qt.color(barThemeData.accent);
        return isClassic ? Qt.color("#db9c5e") : Qt.color("#9accf9");
    }
    readonly property color cFgMain: {
        if (barThemeData && barThemeData.rofiFgMain) return Qt.color(barThemeData.rofiFgMain);
        return isClassic ? Qt.color("#d3c6aa") : Qt.color("#e2e2e6");
    }

    readonly property bool isLightMode: cBase.r > 0.5

    readonly property color cFgBright: {
        if (barThemeData && barThemeData.rofiFgBright) return Qt.color(barThemeData.rofiFgBright);
        return isLightMode ? Qt.color("#1f1c1a") : (isClassic ? Qt.color("#fbf2db") : Qt.color("#ffffff"));
    }
    readonly property color cFgMuted: {
        if (barThemeData && barThemeData.rofiFgMuted) return Qt.color(barThemeData.rofiFgMuted);
        return isLightMode ? Qt.color("#786d63") : (isClassic ? Qt.color("#859289") : Qt.color("#8b9199"));
    }

    readonly property color bgOverlay: isLightMode 
        ? Qt.rgba(cBase.r, cBase.g, cBase.b, 0.85) 
        : Qt.rgba(cBase.r, cBase.g, cBase.b, 0.75)
    readonly property color cardBg: isLightMode 
        ? Qt.rgba(0, 0, 0, 0.06) 
        : Qt.rgba(1, 1, 1, 0.06)
    readonly property color cardBorder: isLightMode 
        ? Qt.rgba(0, 0, 0, 0.12) 
        : Qt.rgba(1, 1, 1, 0.12)
    readonly property color cardSelectedBg: isLightMode
        ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.22)
        : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.35)
    readonly property color cardSelectedBorder: cAccent
    readonly property color accentGold: cAccent
    readonly property color accentGoldBright: isLightMode ? Qt.color("#b87732") : (isClassic ? Qt.color("#e5c07b") : cAccent)
    readonly property color fgMain: cFgMain
    readonly property color fgBright: cFgBright
    readonly property color fgMuted: cFgMuted

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
    // 8 SESSION ACTIONS (Model & Dispatcher)
    // =========================================================================
    readonly property var sessionActions: [
        {
            label: "Lock",
            desc: "Lock desktop session and secure screen",
            icon: "󰌾",
            cmd: "hyprlock -c \"$HOME/.config/hypr/hyprlock.conf\" 2>/dev/null || loginctl lock-session"
        },
        {
            label: "Sleep",
            desc: "Suspend system state to RAM",
            icon: "󰒲",
            cmd: "systemctl suspend"
        },
        {
            label: "Logout",
            desc: "Exit Hyprland graphical desktop session",
            icon: "󰍃",
            cmd: "hyprctl dispatch exit 2>/dev/null || pkill -KILL -u \"$USER\""
        },
        {
            label: "Task Manager",
            desc: "Launch real-time system monitor (btop)",
            icon: "󰈸",
            cmd: "kitty -e btop 2>/dev/null || gnome-system-monitor &"
        },
        {
            label: "Hibernate",
            desc: "Save system session to swap and power off",
            icon: "󰒲",
            cmd: "systemctl hibernate"
        },
        {
            label: "Shutdown",
            desc: "Power off the computer completely",
            icon: "󰐥",
            cmd: "systemctl poweroff"
        },
        {
            label: "Reboot",
            desc: "Restart operating system",
            icon: "󰜉",
            cmd: "systemctl reboot"
        },
        {
            label: "UEFI Settings",
            desc: "Reboot directly into BIOS / UEFI firmware",
            icon: "󰒓",
            cmd: "systemctl reboot --firmware-setup"
        }
    ]

    function open() {
        root.reloadTheme();
        root.selectedIndex = 0;
        root.isOpen = true;
        focusScope.forceActiveFocus();
    }

    function close() {
        root.isOpen = false;
    }

    function toggle() {
        if (root.isOpen) root.close();
        else root.open();
    }

    function executeAction(index) {
        if (index < 0 || index >= sessionActions.length) return;
        let item = sessionActions[index];
        root.close();
        if (item && item.cmd) {
            Quickshell.execDetached(["sh", "-c", item.cmd]);
        }
    }

    IpcHandler {
        target: "session"

        function toggle() {
            root.toggle();
        }

        function open() {
            root.open();
        }

        function close() {
            root.close();
        }

        function reload() {
            root.reloadTheme();
        }
    }

    // Fullscreen backdrop click-to-dismiss (clear color on PanelWindow handles the blur tint)
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    FocusScope {
        id: focusScope
        anchors.fill: parent
        focus: root.isOpen

        Keys.onPressed: function(event) {
            let count = root.sessionActions.length;
            if (event.key === Qt.Key_Escape) {
                root.close();
                event.accepted = true;
            } else if (event.key === Qt.Key_Left) {
                root.selectedIndex = (root.selectedIndex - 1 + count) % count;
                event.accepted = true;
            } else if (event.key === Qt.Key_Right) {
                root.selectedIndex = (root.selectedIndex + 1) % count;
                event.accepted = true;
            } else if (event.key === Qt.Key_Up) {
                root.selectedIndex = (root.selectedIndex - 4 + count) % count;
                event.accepted = true;
            } else if (event.key === Qt.Key_Down) {
                root.selectedIndex = (root.selectedIndex + 4) % count;
                event.accepted = true;
            } else if (event.key === Qt.Key_Tab) {
                root.selectedIndex = (root.selectedIndex + 1) % count;
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab) {
                root.selectedIndex = (root.selectedIndex - 1 + count) % count;
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                root.executeAction(root.selectedIndex);
                event.accepted = true;
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 24

            MouseArea {
                // Prevent clicks on content from triggering backdrop dismiss
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: contentBox.implicitWidth
                implicitHeight: contentBox.implicitHeight
                onClicked: function(mouse) { mouse.accepted = true; }

                ColumnLayout {
                    id: contentBox
                    spacing: 20

                    // Title Header
                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 6

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "RINAUBY — SESSION CONTROLS"
                            font.family: root.isClassic ? "Cinzel" : "Inter"
                            font.pixelSize: 18
                            font.weight: Font.Bold
                            font.letterSpacing: 1.5
                            color: root.accentGoldBright
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Arrow keys to navigate, Enter to select • Esc or click anywhere to cancel"
                            font.family: "Inter"
                            font.pixelSize: 12
                            color: root.fgMuted
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    // 4x2 Buttons Grid (Size: 136x136 per button, modeled after SessionScreen.qml)
                    GridLayout {
                        id: actionsGrid
                        Layout.alignment: Qt.AlignHCenter
                        columns: 4
                        rowSpacing: 18
                        columnSpacing: 18

                        Repeater {
                            model: root.sessionActions

                            delegate: Rectangle {
                                id: actionCard
                                required property int index
                                required property var modelData

                                readonly property bool isSelected: index === root.selectedIndex

                                width: 136
                                height: 136
                                radius: isSelected ? 68 : 24

                                color: isSelected
                                    ? root.cardSelectedBg
                                    : (cardMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.09) : root.cardBg)

                                border.width: 1
                                border.color: isSelected ? root.cardSelectedBorder : root.cardBorder

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 12

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: actionCard.modelData.icon
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 44
                                        color: actionCard.isSelected ? root.fgBright : root.accentGold
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: actionCard.modelData.label
                                        font.family: "Inter"
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                        color: actionCard.isSelected ? root.fgBright : root.fgMain
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }

                                MouseArea {
                                    id: cardMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: {
                                        root.selectedIndex = actionCard.index;
                                    }
                                    onClicked: {
                                        root.selectedIndex = actionCard.index;
                                        root.executeAction(actionCard.index);
                                    }
                                }
                            }
                        }
                    }

                    // Dynamic Subtitle Capsule Description (Modeled after DescriptionLabel in SessionScreen.qml)
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        implicitHeight: descText.implicitHeight + 14
                        implicitWidth: descText.implicitWidth + 32
                        radius: 12
                        color: root.isLightMode ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(0, 0, 0, 0.40)
                        border.width: 1
                        border.color: root.cardBorder

                        Text {
                            id: descText
                            anchors.centerIn: parent
                            text: (root.selectedIndex >= 0 && root.selectedIndex < root.sessionActions.length)
                                ? root.sessionActions[root.selectedIndex].desc
                                : ""
                            font.family: "Inter"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: root.fgBright
                        }
                    }
                }
            }
        }
    }
}
