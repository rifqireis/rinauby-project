import QtQuick
import QtQuick.Window
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import "../"
import "../reusables"

Item {
    id: root
    visible: false
    focus: true
    enabled: visible

    function s(val) {
        return Scaler.s(val);
    }

    readonly property string barPosition: {
        if (typeof Config !== "undefined" && Config.rawSettings && Config.rawSettings.bar && Config.rawSettings.bar.position !== undefined) {
            return Config.rawSettings.bar.position;
        }
        return "top";
    }

    readonly property bool isLeftAnchored: barPosition === "right"
    readonly property real slideDistance: sidebarPanel.width > 0 ? sidebarPanel.width : root.s(420)
    readonly property real rowSlideDistance: root.s(36)

    readonly property bool isDesktop: UPower.displayDevice.ready ? !UPower.displayDevice.isLaptopBattery : SystemInfo.isDesktop

    readonly property real boxRadius: Math.min(ThemeBackend.borderRadius, root.s(14))
    readonly property real cardRadius: Math.min(ThemeBackend.borderRadius, root.s(12))

    readonly property color briColor: ThemeBackend.sapphire
    readonly property color volColor: ThemeBackend.blue
    readonly property color profileColor: ThemeBackend.blue
    readonly property int batCapacity: UPower.displayDevice.ready ? Math.round(UPower.displayDevice.percentage * 100) : 0

    readonly property bool isCharging: UPower.displayDevice.ready && (UPower.displayDevice.state === UPowerDeviceState.Charging || UPower.displayDevice.state === UPowerDeviceState.FullyCharged)

    readonly property string batStatus: {
        if (!UPower.displayDevice.ready) return "Unknown";
        switch (UPower.displayDevice.state) {
            case UPowerDeviceState.FullyCharged: return "Fully Charged";
            case UPowerDeviceState.Charging: return "Charging";
            case UPowerDeviceState.Discharging: return "Discharging";
            default: return "Unknown";
        }
    }

    readonly property int batHours: {
        if (!UPower.displayDevice.ready) return 0;
        let secs = isCharging ? UPower.displayDevice.timeToFull : UPower.displayDevice.timeToEmpty;
        return Math.floor(secs / 3600);
    }

    readonly property int batMins: {
        if (!UPower.displayDevice.ready) return 0;
        let secs = isCharging ? UPower.displayDevice.timeToFull : UPower.displayDevice.timeToEmpty;
        return Math.round((secs % 3600) / 60);
    }

    readonly property string batTimeLabel: {
        if (!UPower.displayDevice.ready || (batHours === 0 && batMins === 0) || batCapacity === 100) return "";
        if (UPower.displayDevice.state === UPowerDeviceState.Charging) return I18n.t("syspanel.battery.until_full");
        if (UPower.displayDevice.state === UPowerDeviceState.Discharging) return I18n.t("syspanel.battery.remaining");
        return "";
    }

    readonly property string powerProfile: {
        switch (PowerProfiles.profile) {
            case PowerProfile.Performance: return "performance";
            case PowerProfile.PowerSaver: return "power-saver";
            default: return "balanced";
        }
    }

    readonly property real sysVolume: Audio.defaultSink && Audio.defaultSink.audio ? Math.round(Audio.defaultSink.audio.volume * 100) : 0
    readonly property bool sysMuted: Audio.defaultSink && Audio.defaultSink.audio ? Audio.defaultSink.audio.muted : false

    property real sysBrightness: 0

    property bool wifiRadioEnabled: Networking.wifiEnabled
    property bool btRadioEnabled: Boolean(Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled)

    Connections {
        target: Bluetooth
        ignoreUnknownSignals: true
        function onDefaultAdapterChanged() {
            root.btRadioEnabled = Boolean(Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled);
        }
    }

    Connections {
        target: Bluetooth.defaultAdapter || null
        ignoreUnknownSignals: true
        function onEnabledChanged() {
            root.btRadioEnabled = Boolean(Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled);
        }
    }



    property bool btStateBeforeAirplane: false
    property bool wifiStateBeforeAirplane: true

    property bool canHibernate: false

    readonly property color batColorFlat: ThemeBackend.blue

    property real animCapacity: 0
    Behavior on animCapacity {
        enabled: root.visible
        NumberAnimation { duration: 1200; easing.type: Easing.OutQuint }
    }

    onBatCapacityChanged: {
        if (root.visible) {
            animCapacity = batCapacity;
        }
    }



    Process {
        id: hibernateCheck
        running: false
        command: ["bash", Caching.serpantinumDir + "/scripts/system/can_hibernate.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let out = this.text.trim();
                root.canHibernate = (out === "yes");
            }
        }
    }

    property real introContent: 0.0
    property real introTop: 0.0
    property real introQuickActions: 0.0
    property real introNotifs: 0.0
    property real introCore: 0.0

    function resetAndPlayIntro() {
        introContent = 0.0;
        introTop = 0.0;
        introQuickActions = 0.0;
        introNotifs = 0.0;
        introCore = 0.0;
        closeSequence.stop();
        startupSequence.restart();
    }

    onVisibleChanged: {
        NotificationManager.sysPanelOpen = visible;
        if (visible) {
            forceActiveFocus();
            resetAndPlayIntro();

            animCapacity = batCapacity;

            if (quickActionsBox.nightLight) quickActionsBox.nightLight.updateState();
            if (quickActionsBox.coffee) quickActionsBox.coffee.updateState();
        } else {
            startupSequence.stop();
            closeSequence.stop();
        }
    }

    Component.onCompleted: {
        hibernateCheck.running = true;
        if (visible) {
            NotificationManager.sysPanelOpen = true;
            if (quickActionsBox.nightLight) quickActionsBox.nightLight.updateState();
            if (quickActionsBox.coffee) quickActionsBox.coffee.updateState();
            resetAndPlayIntro();
            forceActiveFocus();
            animCapacity = batCapacity;
        }
    }

    Component.onDestruction: {
        NotificationManager.sysPanelOpen = false;
    }

    ParallelAnimation {
        id: startupSequence
        NumberAnimation { target: root; property: "introContent"; to: 1.0; duration: 250; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "introTop"; from: 0; to: 1.0; duration: 250; easing.type: Easing.OutCubic }

        SequentialAnimation {
            PauseAnimation { duration: 30 }
            NumberAnimation { target: root; property: "introQuickActions"; from: 0; to: 1.0; duration: 250; easing.type: Easing.OutCubic }
        }
        SequentialAnimation {
            PauseAnimation { duration: 60 }
            NumberAnimation { target: root; property: "introNotifs"; from: 0; to: 1.0; duration: 330; easing.type: Easing.OutCubic }
        }
        SequentialAnimation {
            PauseAnimation { duration: 90 }
            NumberAnimation { target: root; property: "introCore"; from: 0; to: 1.0; duration: 340; easing.type: Easing.OutCubic }
        }
    }

    property alias closeAnim: closeSequence

    property var exitCallback: null

    function startExit(onFinished) {
        startupSequence.stop();
        exitCallback = onFinished;
        closeSequence.restart();
    }

    SequentialAnimation {
        id: closeSequence
        ParallelAnimation {
            NumberAnimation { target: root; property: "introContent"; to: 0.0; duration: 250; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "introTop"; to: 0.0; duration: 250; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "introQuickActions"; to: 0.0; duration: 250; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "introNotifs"; to: 0.0; duration: 250; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "introCore"; to: 0.0; duration: 250; easing.type: Easing.InCubic }
        }
        ScriptAction {
            script: {
                if (root.exitCallback) {
                    let cb = root.exitCallback;
                    root.exitCallback = null;
                    cb();
                } else {
                    Quickshell.execDetached(["bash", Caching.serpantinumDir + "/scripts/qs_manager.sh", "close"]);
                }
            }
        }
    }

    Keys.onEscapePressed: (event) => {
        if (typeof masterWindow !== "undefined" && masterWindow.switchWidget) {
            masterWindow.switchWidget("hidden", "");
        } else {
            closeSequence.restart();
        }
        event.accepted = true;
    }

    component BatteryContent : Item {
        id: bRoot
        property color contentTextColor: ThemeBackend.text
        property color iconColor: root.batColorFlat
        property bool glass: false

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root.s(14)
            anchors.rightMargin: root.s(12)
            spacing: root.s(8)

            Text {
                font.family: ThemeBackend.iconFont
                font.pixelSize: root.s(18)
                color: bRoot.iconColor
                text: root.isCharging ? "󰂄" : (root.batCapacity > 20 ? "󰁹" : "󰂃")
                Behavior on color {
                    enabled: root.visible
                    ColorAnimation { duration: 400 }
                }
                Layout.alignment: Qt.AlignVCenter
            }

            RowLayout {
                spacing: root.s(4)
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                Text {
                    font.family: ThemeBackend.fontFamily
                    font.weight: Font.Bold
                    font.pixelSize: root.s(13)
                    color: bRoot.contentTextColor
                    text: Math.round(root.animCapacity) + "%"
                    Behavior on color {
                        enabled: root.visible
                        ColorAnimation { duration: 400 }
                    }
                }

                Text {
                    property string timeString: {
                        if (root.batStatus === "Fully Charged") return I18n.t("syspanel.battery.fully_charged");
                        if (root.batStatus === "Charging") {
                            if (root.batHours === 0 && root.batMins === 0) return I18n.t("syspanel.battery.charging");
                            return I18n.t("syspanel.battery.charging_time", { hours: root.batHours, mins: root.batMins });
                        }
                        if (root.batHours === 0 && root.batMins === 0) return I18n.t("syspanel.battery.discharging");
                        return I18n.t("syspanel.battery.left_time", { hours: root.batHours, mins: root.batMins });
                    }

                    font.family: ThemeBackend.fontFamily
                    font.weight: Font.Normal
                    font.pixelSize: root.s(10)
                    color: ThemeBackend.subtext0
                    text: "• " + timeString
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Behavior on color {
                        enabled: root.visible
                        ColorAnimation { duration: 250 }
                    }
                }
            }
        }
    }

    Rectangle {
        id: sidebarShadowSource
        anchors.fill: sidebarPanel
        radius: sidebarPanel.radius
        color: "#000000"
        visible: false
    }

    MultiEffect {
        anchors.fill: sidebarPanel
        source: sidebarShadowSource
        shadowEnabled: true
        shadowColor: "#40000000"
        shadowBlur: 0.6
        shadowVerticalOffset: root.s(4)
        shadowHorizontalOffset: 0
        opacity: root.introContent
        transform: Translate { x: (root.isLeftAnchored ? -root.slideDistance : root.slideDistance) * (1.0 - root.introContent) }
    }

    Rectangle {
        id: sidebarPanel
        anchors.fill: parent
        anchors.leftMargin: root.s(14)
        anchors.rightMargin: root.s(10)
        anchors.topMargin: root.s(6)
        anchors.bottomMargin: root.s(12)
        color: Qt.rgba(ThemeBackend.base.r, ThemeBackend.base.g, ThemeBackend.base.b, 0.96)
        radius: root.s(16)
        topLeftRadius: radius
        bottomLeftRadius: radius
        topRightRadius: radius
        bottomRightRadius: radius
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.06)
        clip: true
        opacity: root.introContent

        WallpaperBlur {
            z: -1
            anchors.fill: parent
            topLeftRadius: parent.topLeftRadius
            topRightRadius: parent.topRightRadius
            bottomLeftRadius: parent.bottomLeftRadius
            bottomRightRadius: parent.bottomRightRadius
        }
        transform: Translate { x: (root.isLeftAnchored ? -root.slideDistance : root.slideDistance) * (1.0 - root.introContent) }

        Item {
            anchors.fill: parent

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.s(12)
                spacing: root.s(8)

                Item {
                    id: userBox
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.s(40)
                    Layout.maximumHeight: root.s(40)
                    opacity: root.introTop
                    transform: Translate { x: (root.isLeftAnchored ? -root.rowSlideDistance : root.rowSlideDistance) * (1.0 - root.introTop) }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: root.s(4)
                        anchors.rightMargin: root.s(4)
                        spacing: root.s(10)

                        ImageBox {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: root.s(32)
                            Layout.preferredHeight: root.s(32)
                            size: root.s(32)
                            cornerRadius: root.s(16)
                            imageRadius: root.s(16)
                            source: SystemInfo.avatarPath !== "" ? "file://" + SystemInfo.avatarPath : ""
                            backgroundColor: SystemInfo.avatarPath === "" ? Qt.rgba(ThemeBackend.blue.r, ThemeBackend.blue.g, ThemeBackend.blue.b, 0.14) : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: ""
                                font.family: ThemeBackend.iconFont
                                font.pixelSize: root.s(16)
                                color: ThemeBackend.blue
                                visible: SystemInfo.avatarPath === ""
                            }
                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 0

                            Text {
                                text: SystemInfo.username !== "" ? SystemInfo.username : I18n.t("syspanel.user.default_name")
                                font.family: ThemeBackend.fontFamily
                                font.weight: Font.Bold
                                font.pixelSize: root.s(13)
                                color: ThemeBackend.text
                            }

                            Text {
                                text: SystemInfo.osName !== "" ? SystemInfo.osName : I18n.t("syspanel.user.default_os")
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: root.s(10)
                                color: ThemeBackend.subtext0
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // GNOME-Style Header Actions: Lock, Settings, Power
                        IconButton {
                            id: lockQuickBtn
                            Layout.alignment: Qt.AlignVCenter
                            size: root.s(32)
                            cornerRadius: root.s(16)
                            buttonIcon: ""
                            iconFontSize: root.s(14)
                            accentColor: isHoveredOrHighlighted ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.05)
                            bgOpacity: 1.0
                            textColor: isHoveredOrHighlighted ? ThemeBackend.text : ThemeBackend.subtext0
                            onClicked: {
                                closeSequence.start();
                                Quickshell.execDetached(["bash", "-c", "loginctl lock-session || hyprlock"]);
                            }
                        }

                        IconButton {
                            id: settingsQuickBtn
                            Layout.alignment: Qt.AlignVCenter
                            size: root.s(32)
                            cornerRadius: root.s(16)
                            buttonIcon: "󰒓"
                            iconFontSize: root.s(15)
                            accentColor: isHoveredOrHighlighted ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.05)
                            bgOpacity: 1.0
                            textColor: isHoveredOrHighlighted ? ThemeBackend.text : ThemeBackend.subtext0
                            onClicked: {
                                closeSequence.start();
                                Quickshell.execDetached(["bash", "-c", "rinauby-settings --toggle"]);
                            }
                        }

                        IconButton {
                            id: powerQuickBtn
                            Layout.alignment: Qt.AlignVCenter
                            size: root.s(32)
                            cornerRadius: root.s(16)
                            buttonIcon: ""
                            iconFontSize: root.s(15)
                            accentColor: isHoveredOrHighlighted ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.05)
                            bgOpacity: 1.0
                            textColor: isHoveredOrHighlighted ? ThemeBackend.text : ThemeBackend.subtext0
                            onClicked: {
                                closeSequence.start();
                                Quickshell.execDetached(["bash", Caching.serpantinumDir + "/scripts/system/exit.sh"]);
                            }
                        }
                    }
                }

                SystemPanelQuickActions {
                    id: quickActionsBox
                    panel: root
                }

                NotificationBox {
                    id: notifsBox
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: root.s(68)
                    cornerRadius: root.boxRadius
                    cardRadius: root.cardRadius
                    baseColor: "transparent"
                    rootContext: root
                    opacity: root.introNotifs
                    transform: Translate { x: (root.isLeftAnchored ? -root.rowSlideDistance : root.rowSlideDistance) * (1.0 - root.introNotifs) }
                }

                RowLayout {
                    id: batteryAndProfileRow
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.s(40)
                    Layout.maximumHeight: root.s(40)
                    spacing: root.s(8)
                    opacity: root.introCore
                    transform: Translate { x: (root.isLeftAnchored ? -root.rowSlideDistance : root.rowSlideDistance) * (1.0 - root.introCore) }

                    // 1. KARTU STATUS BATERAI (Minimalis, Flat GNOME Style)
                    Rectangle {
                        id: batteryCard
                        visible: !root.isDesktop
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: height / 2
                        color: ThemeBackend.surface0
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.04)
                        clip: true

                        BatteryContent {
                            anchors.fill: parent
                            contentTextColor: ThemeBackend.text
                            iconColor: root.batColorFlat
                            glass: false
                        }
                    }

                    // 2. KARTU POWER PROFILE (Terpisah rapi di sebelah kanan)
                    Rectangle {
                        id: profileCard
                        Layout.preferredWidth: root.isDesktop ? -1 : root.s(136)
                        Layout.fillWidth: root.isDesktop
                        Layout.fillHeight: true
                        radius: height / 2
                        color: ThemeBackend.surface0
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.04)
                        clip: true

                        Switch {
                            id: profileSwitch
                            anchors.fill: parent
                            anchors.margins: root.s(3)
                            cornerRadius: height / 2
                            fontFamily: root.isDesktop ? ThemeBackend.fontFamily : ThemeBackend.iconFont
                            fontPixelSize: root.isDesktop ? root.s(12) : root.s(15)
                            options: {
                                if (root.isDesktop) {
                                    return PowerProfiles.hasPerformanceProfile
                                        ? ["󰌪 " + I18n.t("syspanel.profiles.power_saver"), "󰗑 " + I18n.t("syspanel.profiles.balanced"), "󰓅 " + I18n.t("syspanel.profiles.performance")]
                                        : ["󰌪 " + I18n.t("syspanel.profiles.power_saver"), "󰗑 " + I18n.t("syspanel.profiles.balanced")];
                                } else {
                                    return PowerProfiles.hasPerformanceProfile
                                        ? ["󰌪", "󰗑", "󰓅"]
                                        : ["󰌪", "󰗑"];
                                }
                            }
                            accentColor: root.profileColor
                            baseColor: ThemeBackend.mantle
                            textColor: ThemeBackend.subtext0
                            activeTextColor: ThemeBackend.crust
                            currentIndex: {
                                if (PowerProfiles.hasPerformanceProfile) {
                                    if (root.powerProfile === "power-saver") return 0;
                                    if (root.powerProfile === "balanced") return 1;
                                    return 2;
                                } else {
                                    if (root.powerProfile === "power-saver") return 0;
                                    return 1;
                                }
                            }

                            onValueChanged: (idx, val) => {
                                if (PowerProfiles.hasPerformanceProfile) {
                                    if (idx === 0) PowerProfiles.profile = PowerProfile.PowerSaver;
                                    else if (idx === 1) PowerProfiles.profile = PowerProfile.Balanced;
                                    else PowerProfiles.profile = PowerProfile.Performance;
                                } else {
                                    if (idx === 0) PowerProfiles.profile = PowerProfile.PowerSaver;
                                    else PowerProfiles.profile = PowerProfile.Balanced;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
