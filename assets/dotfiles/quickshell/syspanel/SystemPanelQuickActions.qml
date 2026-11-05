import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import "../"
import "../reusables"

Item {
    required property var panel
    property alias nightLight: nightLightBtn
    property alias coffee: coffeeBtn

    component GnomePillBtn : Rectangle {
        id: pill
        Layout.fillWidth: true
        Layout.preferredHeight: view.panel.s(42)
        Layout.maximumHeight: view.panel.s(42)
        radius: height / 2

        property bool isActive: false
        property string iconText: ""
        property string labelText: ""
        property bool hasSubmenu: false
        property color activeColor: ThemeBackend.blue
        readonly property bool isHovered: pillMa.containsMouse

        signal leftClicked()
        signal rightClicked()

        color: isActive ? activeColor : (isHovered ? Qt.rgba(1, 1, 1, 0.08) : ThemeBackend.surface0)
        border.width: 1
        border.color: isActive ? activeColor : (isHovered ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04))

        scale: pillMa.pressed ? 0.97 : (isHovered ? 1.01 : 1.0)
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: view.panel.s(14)
            anchors.rightMargin: view.panel.s(12)
            spacing: view.panel.s(8)

            Text {
                text: pill.iconText
                font.family: ThemeBackend.iconFont
                font.pixelSize: view.panel.s(16)
                color: pill.isActive ? ThemeBackend.crust : (pill.isHovered ? ThemeBackend.text : ThemeBackend.subtext0)
                Layout.alignment: Qt.AlignVCenter
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            Text {
                text: pill.labelText
                font.family: ThemeBackend.fontFamily
                font.pixelSize: view.panel.s(12)
                font.weight: Font.DemiBold
                color: pill.isActive ? ThemeBackend.crust : (pill.isHovered ? ThemeBackend.text : ThemeBackend.subtext0)
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            Text {
                visible: pill.hasSubmenu
                text: ""
                font.family: ThemeBackend.iconFont
                font.pixelSize: view.panel.s(11)
                color: pill.isActive ? Qt.alpha(ThemeBackend.crust, 0.6) : Qt.alpha(ThemeBackend.subtext0, 0.45)
                Layout.alignment: Qt.AlignVCenter
            }
        }

        MouseArea {
            id: pillMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton) pill.rightClicked();
                else pill.leftClicked();
            }
        }
    }

    id: view
    z: 5
    Layout.fillWidth: true
    Layout.preferredHeight: (3 * view.panel.s(42)) + (2 * view.panel.s(6))
    Layout.maximumHeight: (3 * view.panel.s(42)) + (2 * view.panel.s(6))
    opacity: view.panel.introQuickActions
    transform: Translate { x: (view.panel.isLeftAnchored ? -view.panel.rowSlideDistance : view.panel.rowSlideDistance) * (1.0 - view.panel.introQuickActions) }

    GridLayout {
        anchors.fill: parent
        columns: 2
        rowSpacing: view.panel.s(6)
        columnSpacing: view.panel.s(6)

        // 1. Wi-Fi
        GnomePillBtn {
            iconText: view.panel.wifiRadioEnabled ? "󰤨" : "󰤮"
            labelText: "Wi-Fi"
            hasSubmenu: true
            isActive: view.panel.wifiRadioEnabled
            onLeftClicked: {
                Sounds.playSfx("system/quick_click.wav");
                Networking.wifiEnabled = !Networking.wifiEnabled;
            }
            onRightClicked: {
                view.panel.closeAnim.start();
                Quickshell.execDetached(["bash", Caching.serpantinumDir + "/scripts/qs_manager.sh", "toggle", "network", "wifi"]);
            }
        }

        // 2. Bluetooth
        GnomePillBtn {
            iconText: view.panel.btRadioEnabled ? "󰂯" : "󰂲"
            labelText: "Bluetooth"
            hasSubmenu: true
            isActive: view.panel.btRadioEnabled
            onLeftClicked: {
                Sounds.playSfx("system/quick_click.wav");
                if (Bluetooth.defaultAdapter) {
                    Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
                }
            }
            onRightClicked: {
                view.panel.closeAnim.start();
                Quickshell.execDetached(["bash", Caching.serpantinumDir + "/scripts/qs_manager.sh", "toggle", "network", "bt"]);
            }
        }

        // 3. Night Light
        GnomePillBtn {
            id: nightLightBtn
            iconText: "󰖔"
            labelText: "Night Light"
            hasSubmenu: false

            function updateState() {
                let anyEnabled = false;
                if (typeof BlueLight !== "undefined" && typeof BlueLight.isAnyEnabled === "function") {
                    anyEnabled = BlueLight.isAnyEnabled();
                } else if (typeof Config !== "undefined") {
                    let ds = Config.getSetting("display", {"monitors": {}});
                    let mons = (ds && ds.monitors) ? ds.monitors : {};
                    for (let mName in mons) {
                        if (mons[mName] && mons[mName].enabled) {
                            anyEnabled = true;
                            break;
                        }
                    }
                }
                isActive = anyEnabled;
            }

            Component.onCompleted: updateState()

            Connections {
                target: typeof Config !== "undefined" ? Config : null
                enabled: view.panel.visible
                ignoreUnknownSignals: true
                function onSettingsLoaded() {
                    nightLightBtn.updateState();
                }
            }

            Connections {
                target: typeof BlueLight !== "undefined" ? BlueLight : null
                enabled: view.panel.visible
                ignoreUnknownSignals: true
                function onSettingsChanged() {
                    nightLightBtn.updateState();
                }
            }

            onLeftClicked: {
                Sounds.playSfx("system/quick_click.wav");
                let target = !nightLightBtn.isActive;
                nightLightBtn.isActive = target;

                let monNames = [];
                let ds = typeof Config !== "undefined" ? Config.getSetting("display", {"monitors": {}}) : {"monitors": {}};
                let mons = (ds && ds.monitors) ? ds.monitors : {};
                for (let m in mons) {
                    if (monNames.indexOf(m) === -1) {
                        monNames.push(m);
                    }
                }
                if (typeof Quickshell !== "undefined" && Quickshell.screens) {
                    for (let i = 0; i < Quickshell.screens.length; i++) {
                        let scr = Quickshell.screens[i];
                        if (scr && scr.name && monNames.indexOf(scr.name) === -1) {
                            monNames.push(scr.name);
                        }
                    }
                }

                if (monNames.length > 0) {
                    for (let i = 0; i < monNames.length; i++) {
                        BlueLight.setEnabled(monNames[i], target);
                    }
                } else {
                    BlueLight.setEnabled("", target);
                }
                nightLightBtn.updateState();
            }

            onRightClicked: {
                view.panel.closeAnim.start();
                Quickshell.execDetached(["bash", Caching.serpantinumDir + "/scripts/qs_manager.sh", "toggle", "settings", "display"]);
            }
        }

        // 4. Caffeine
        GnomePillBtn {
            id: coffeeBtn

            property double coffeeStartTime: 0
            property double coffeeEndTime: 0
            property int remainingSeconds: 0

            readonly property string remainingTimeString: {
                if (isActive && coffeeEndTime <= 0) return "∞";
                let secs = remainingSeconds;
                if (secs <= 0) return "< 1m";
                let h = Math.floor(secs / 3600);
                let m = Math.floor((secs % 3600) / 60);
                if (h > 0) {
                    return h + "h " + (m < 10 ? "0" + m : m) + "m";
                }
                return Math.max(1, m) + "m";
            }

            iconText: "󰅶"
            labelText: isActive ? remainingTimeString : "Caffeine"
            hasSubmenu: false

            function updateRemaining() {
                if (!isActive || coffeeEndTime <= 0) {
                    remainingSeconds = 0;
                    return;
                }
                let now = Date.now();
                let diff = Math.round((coffeeEndTime - now) / 1000);
                if (diff <= 0) {
                    remainingSeconds = 0;
                    disableCaffeine();
                } else {
                    remainingSeconds = diff;
                }
            }

            function syncConfig(enabled) {
                if (typeof Config === "undefined") return;
                let idleObj = Object.assign({}, Config.getSetting("idle", {}));
                idleObj.manualInhibit = enabled;
                idleObj.caffeineStartTime = enabled ? coffeeStartTime : 0;
                idleObj.caffeineEndTime = enabled ? coffeeEndTime : 0;
                Config.setSetting("idle", idleObj);
            }

            function enableCaffeine(durationMs) {
                let now = Date.now();
                coffeeStartTime = now;
                coffeeEndTime = now + durationMs;
                isActive = true;
                updateRemaining();
                syncConfig(true);
            }

            function increaseCaffeine(addMs) {
                let now = Date.now();
                if (!isActive || coffeeEndTime <= now) {
                    enableCaffeine(addMs);
                } else {
                    coffeeEndTime += addMs;
                    updateRemaining();
                    syncConfig(true);
                }
            }

            function disableCaffeine() {
                isActive = false;
                coffeeStartTime = 0;
                coffeeEndTime = 0;
                remainingSeconds = 0;
                syncConfig(false);
            }

            function updateState() {
                if (typeof Config === "undefined") return;
                let idleObj = Config.getSetting("idle", {}) || {};
                let endTime = Number(idleObj.caffeineEndTime) || 0;

                if (!idleObj.manualInhibit) {
                    isActive = false;
                    coffeeStartTime = 0;
                    coffeeEndTime = 0;
                    remainingSeconds = 0;
                } else if (endTime > 0 && endTime <= Date.now()) {
                    disableCaffeine();
                } else {
                    coffeeStartTime = Number(idleObj.caffeineStartTime) || 0;
                    coffeeEndTime = endTime;
                    isActive = true;
                    updateRemaining();
                }
            }

            Timer {
                id: coffeeTicker
                interval: view.panel.visible ? 1000 : 15000
                repeat: true
                running: coffeeBtn.isActive
                triggeredOnStart: true
                onTriggered: {
                    coffeeBtn.updateRemaining();
                }
            }

            Component.onCompleted: updateState()

            Connections {
                target: typeof Config !== "undefined" ? Config : null
                enabled: true
                ignoreUnknownSignals: true
                function onSettingsLoaded() {
                    coffeeBtn.updateState();
                }
            }

            onLeftClicked: {
                Sounds.playSfx("system/quick_click.wav");
                if (isActive) {
                    disableCaffeine();
                } else {
                    enableCaffeine(3600 * 1000);
                }
            }

            onRightClicked: {
                Sounds.playSfx("system/quick_click.wav");
                increaseCaffeine(3600 * 1000);
            }
        }

        // 5. Airplane Mode
        GnomePillBtn {
            iconText: "󰀝"
            labelText: "Airplane"
            hasSubmenu: false
            isActive: !view.panel.wifiRadioEnabled && !view.panel.btRadioEnabled
            onLeftClicked: {
                Sounds.playSfx("system/quick_click.wav");
                let enableAirplane = !isActive;
                if (enableAirplane) {
                    view.panel.btStateBeforeAirplane = view.panel.btRadioEnabled;
                    view.panel.wifiStateBeforeAirplane = view.panel.wifiRadioEnabled;
                    Networking.wifiEnabled = false;
                    if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = false;
                } else {
                    let restoreWifi = view.panel.wifiStateBeforeAirplane;
                    let restoreBt = view.panel.btStateBeforeAirplane;
                    if (!restoreWifi && !restoreBt) {
                        restoreWifi = true;
                    }
                    Networking.wifiEnabled = restoreWifi;
                    if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = restoreBt;
                }
            }
        }

        // 6. Do Not Disturb
        GnomePillBtn {
            id: dndPill
            property bool dndActive: Boolean(Config.rawSettings && Config.rawSettings.notifications && Config.rawSettings.notifications.dnd)
            iconText: dndActive ? "󰂛" : "󰂚"
            labelText: "Do Not Disturb"
            hasSubmenu: false
            isActive: dndActive

            Connections {
                target: Config
                function onSettingsLoaded() {
                    let n = Config.getSetting("notifications", { "dnd": false });
                    dndPill.dndActive = Boolean(n && n.dnd);
                }
            }

            onLeftClicked: {
                Sounds.playSfx("system/quick_click.wav");
                dndPill.dndActive = !dndPill.dndActive;
                let n = Config.getSetting("notifications", { "dnd": false });
                if (typeof n !== "object" || n === null) n = {};
                n.dnd = dndPill.dndActive;
                Config.setSetting("notifications", n);
            }
        }
    }
}
