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

    property bool isDraggingVol: false
    property bool isDraggingBri: false
    property bool usesDdcBrightness: false

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

    onSysVolumeChanged: {
        if (root.visible && slidersBox.volumeSlider && !root.isDraggingVol && slidersBox.volumeSlider.value !== sysVolume) {
            slidersBox.volumeSlider.value = sysVolume;
        }
    }

    onSysBrightnessChanged: {
        if (root.visible && slidersBox.brightnessSlider && !root.isDraggingBri && slidersBox.brightnessSlider.value !== sysBrightness) {
            slidersBox.brightnessSlider.value = sysBrightness;
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
    property real introSliders: 0.0
    property real introQuickActions: 0.0
    property real introNotifs: 0.0
    property real introActions: 0.0
    property real introCore: 0.0

    function resetAndPlayIntro() {
        introContent = 0.0;
        introTop = 0.0;
        introSliders = 0.0;
        introQuickActions = 0.0;
        introNotifs = 0.0;
        introActions = 0.0;
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

            if (slidersBox.volumeSlider && !root.isDraggingVol) {
                slidersBox.volumeSlider.value = root.sysVolume;
            }

            if (slidersBox.brightnessSlider && !root.isDraggingBri) {
                slidersBox.brightnessSlider.value = root.sysBrightness;
            }

            if (quickActionsBox.nightLight) quickActionsBox.nightLight.updateState();
            if (quickActionsBox.coffee) quickActionsBox.coffee.updateState();

            briPollerTimer.interval = 150;
            briPollerTimer.restart();
        } else {
            briPollerTimer.stop();
            briPoller.running = false;
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
            briPollerTimer.interval = 150;
            briPollerTimer.restart();
            animCapacity = batCapacity;
        }
    }

    Component.onDestruction: {
        NotificationManager.sysPanelOpen = false;
        briPollerTimer.stop();
    }

    Timer {
        id: briPollerTimer
        interval: root.usesDdcBrightness ? 10000 : 1500
        repeat: false
        onTriggered: {
            if (root.visible) {
                briPoller.running = true;
                interval = root.usesDdcBrightness ? 10000 : 1500;
            }
        }
    }

    Process {
        id: briBackend
        command: ["bash", Caching.serpantinumDir + "/scripts/brightness.sh", "backend"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.usesDdcBrightness = this.text.trim() === "ddc"
        }
    }

    Process {
        id: briPoller
        command: ["bash", Caching.serpantinumDir + "/scripts/brightness.sh", "get"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let out = this.text.trim();
                if (out !== "" && !root.isDraggingBri) {
                    root.sysBrightness = parseInt(out) || 0;
                }
                if (root.visible) briPollerTimer.start();
            }
        }
    }

    ParallelAnimation {
        id: startupSequence
        NumberAnimation { target: root; property: "introContent"; to: 1.0; duration: 250; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "introTop"; from: 0; to: 1.0; duration: 250; easing.type: Easing.OutCubic }

        SequentialAnimation {
            PauseAnimation { duration: 30 }
            NumberAnimation { target: root; property: "introSliders"; from: 0; to: 1.0; duration: 250; easing.type: Easing.OutCubic }
        }
        SequentialAnimation {
            PauseAnimation { duration: 55 }
            NumberAnimation { target: root; property: "introQuickActions"; from: 0; to: 1.0; duration: 250; easing.type: Easing.OutCubic }
        }
        SequentialAnimation {
            PauseAnimation { duration: 80 }
            NumberAnimation { target: root; property: "introNotifs"; from: 0; to: 1.0; duration: 330; easing.type: Easing.OutCubic }
        }
        SequentialAnimation {
            PauseAnimation { duration: 105 }
            NumberAnimation { target: root; property: "introActions"; from: 0; to: 1.0; duration: 330; easing.type: Easing.OutCubic }
        }
        SequentialAnimation {
            PauseAnimation { duration: 130 }
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
            NumberAnimation { target: root; property: "introSliders"; to: 0.0; duration: 250; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "introQuickActions"; to: 0.0; duration: 250; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "introNotifs"; to: 0.0; duration: 250; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "introActions"; to: 0.0; duration: 250; easing.type: Easing.InCubic }
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
            anchors.leftMargin: root.s(12)
            anchors.rightMargin: root.s(10)
            spacing: root.s(10)

            Text {
                font.family: ThemeBackend.iconFont
                font.pixelSize: root.s(24)
                color: bRoot.iconColor
                text: root.isCharging ? "󰂄" : (root.batCapacity > 20 ? "󰁹" : "󰂃")
                Behavior on color {
                    enabled: root.visible
                    ColorAnimation { duration: 400 }
                }
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                Text {
                    font.family: ThemeBackend.fontFamily
                    font.weight: Font.Black
                    font.pixelSize: root.s(16)
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
                    font.weight: Font.Bold
                    font.pixelSize: root.s(10)
                    color: bRoot.glass ? Qt.alpha(bRoot.contentTextColor, 0.75) : (bRoot.contentTextColor === ThemeBackend.crust ? Qt.alpha(ThemeBackend.crust, 0.85) : ThemeBackend.subtext0)
                    text: timeString
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

                Rectangle {
                    id: userBox
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.s(58)
                    Layout.maximumHeight: root.s(58)
                    radius: root.boxRadius
                    color: userGlass.active ? "transparent" : ThemeBackend.surface0
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.05)
                    opacity: root.introTop
                    transform: Translate { x: (root.isLeftAnchored ? -root.rowSlideDistance : root.rowSlideDistance) * (1.0 - root.introTop) }

                    GlassFill {
                        id: userGlass
                        anchors.fill: parent
                        radius: parent.radius
                        tintColor: ThemeBackend.surface0
                        tintAmount: 0.3
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: root.s(10)
                        spacing: root.s(10)

                        ImageBox {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: root.s(36)
                            Layout.preferredHeight: root.s(36)
                            size: root.s(36)
                            cornerRadius: root.s(10)
                            imageRadius: root.s(10)
                            source: SystemInfo.avatarPath !== "" ? "file://" + SystemInfo.avatarPath : ""
                            backgroundColor: SystemInfo.avatarPath === "" ? Qt.rgba(ThemeBackend.blue.r, ThemeBackend.blue.g, ThemeBackend.blue.b, 0.14) : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: ""
                                font.family: ThemeBackend.iconFont
                                font.pixelSize: root.s(17)
                                color: ThemeBackend.blue
                                visible: SystemInfo.avatarPath === ""
                            }
                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: root.s(1)

                            Text {
                                text: SystemInfo.username !== "" ? SystemInfo.username : I18n.t("syspanel.user.default_name")
                                font.family: ThemeBackend.serifFont
                                font.weight: Font.Bold
                                font.capitalization: Font.AllUppercase
                                font.letterSpacing: 0.6
                                font.pixelSize: root.s(14)
                                color: ThemeBackend.text
                            }

                            Text {
                                text: SystemInfo.osName !== "" ? SystemInfo.osName : I18n.t("syspanel.user.default_os")
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: root.s(11)
                                color: ThemeBackend.subtext0
                            }
                        }

                        Item { Layout.fillWidth: true }

                        IconButton {
                            id: settingsQuickBtn
                            Layout.alignment: Qt.AlignVCenter
                            size: root.s(32)
                            cornerRadius: root.s(8)
                            buttonIcon: "󰒓"
                            iconFontSize: root.s(16)
                            accentColor: isHoveredOrHighlighted ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                            bgOpacity: isHoveredOrHighlighted ? 1.0 : 0.0
                            textColor: isHoveredOrHighlighted ? ThemeBackend.text : ThemeBackend.blue
                            onClicked: {
                                closeSequence.start();
                                Quickshell.execDetached(["bash", "-c", "rinauby-settings --toggle"]);
                            }
                        }

                        ClickButton {
                            id: logoutBtn
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            Layout.preferredWidth: root.s(80)
                            Layout.preferredHeight: root.s(32)
                            horizontalPadding: root.s(8)
                            cornerRadius: root.s(8)
                            buttonText: I18n.t("syspanel.user.logout")
                            textFontSize: root.s(11)
                            buttonIcon: "󰍃"
                            iconFontSize: root.s(14)
                            accentColor: isHoveredOrHighlighted ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                            bgOpacity: isHoveredOrHighlighted ? 1.0 : 0.0
                            textColor: isHoveredOrHighlighted ? ThemeBackend.text : ThemeBackend.blue

                            Timer {
                                id: logoutOpenTimer
                                interval: 150
                                onTriggered: {
                                    closeSequence.start();
                                    Quickshell.execDetached(["bash", Caching.serpantinumDir + "/scripts/system/exit.sh"]);
                                }
                            }

                            onTriggered: {
                                logoutOpenTimer.start();
                            }
                        }
                    }
                }

                SystemPanelSliders {
                    id: slidersBox
                    panel: root
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
                    baseColor: ThemeBackend.surface0
                    rootContext: root
                    opacity: root.introNotifs
                    transform: Translate { x: (root.isLeftAnchored ? -root.rowSlideDistance : root.rowSlideDistance) * (1.0 - root.introNotifs) }
                }

                SystemPanelPowerActions {
                    panel: root
                }

                RowLayout {
                    id: batteryAndProfileRow
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.isDesktop ? root.s(50) : root.s(58)
                    Layout.maximumHeight: Layout.preferredHeight
                    spacing: root.s(8)
                    opacity: root.introCore
                    transform: Translate { x: (root.isLeftAnchored ? -root.rowSlideDistance : root.rowSlideDistance) * (1.0 - root.introCore) }

                    // 1. KARTU STATUS BATERAI (Terisolasi mandiri, wave tidak akan menabrak profile)
                    Rectangle {
                        id: batteryCard
                        visible: !root.isDesktop
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: root.boxRadius
                        color: (root.isDesktop || batteryGlass.active) ? "transparent" : ThemeBackend.surface0
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.05)
                        clip: true

                        property real fillLevel: root.animCapacity / 100
                        property real maxWaveAmp: root.s(2)
                        property real waveAmp: (fillLevel < 0.99 && fillLevel > 0.01) ? maxWaveAmp * Math.sin(fillLevel * Math.PI) : 0

                        GlassFill {
                            id: batteryGlass
                            anchors.fill: parent
                            allowed: !root.isDesktop
                            radius: parent.radius
                            tintColor: ThemeBackend.surface0
                            tintAmount: 0.3
                        }

                        FluidWave {
                            id: waveCanvas
                            anchors.fill: parent
                            visible: !batteryGlass.active && root.visible && !root.isDesktop && batteryCard.fillLevel > 0.001

                            property real wavePhase: 0.0
                            NumberAnimation on wavePhase {
                                running: root.visible && !root.isDesktop && batteryCard.fillLevel > 0.0 && batteryCard.fillLevel < 1.0
                                loops: Animation.Infinite
                                from: 0; to: Math.PI * 2; duration: root.isCharging ? 1200 : 2200
                            }

                            radius: batteryCard.radius
                            fillLevel: batteryCard.fillLevel
                            waveAmp: (batteryCard.fillLevel < 0.99 && batteryCard.waveAmp > 0) ? Math.min(batteryCard.waveAmp, Math.min(width * batteryCard.fillLevel, width * (1.0 - batteryCard.fillLevel))) : 0
                            phase: wavePhase
                            vertical: 0.0
                            color1: root.batColorFlat
                            color2: root.batColorFlat
                        }

                        LiquidFill {
                            anchors.fill: parent
                            visible: batteryGlass.active && root.visible && !root.isDesktop && batteryCard.fillLevel > 0.001
                            radius: batteryCard.radius
                            fillLevel: batteryCard.fillLevel
                            waveAmp: waveCanvas.waveAmp
                            phase: waveCanvas.wavePhase
                            color1: Qt.alpha(Qt.lighter(root.batColorFlat, 1.1), 0.6)
                            color2: Qt.alpha(root.batColorFlat, 0.6)
                            bodyAlpha: 0.18
                        }

                        BatteryContent {
                            anchors.fill: parent
                            contentTextColor: ThemeBackend.text
                            iconColor: root.batColorFlat
                            glass: batteryGlass.active
                            visible: !root.isDesktop
                        }

                        Item {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            visible: !root.isDesktop

                            property real phaseOffset: Math.sin(waveCanvas.wavePhase) - Math.cos(waveCanvas.wavePhase)
                            property real centerOffset: batteryCard.fillLevel > 0.01 && batteryCard.fillLevel < 0.99 ? 0.375 * batteryCard.waveAmp * phaseOffset : 0

                            width: Math.max(0, Math.min(parent.width, (parent.width * batteryCard.fillLevel) + centerOffset))
                            clip: true

                            BatteryContent {
                                width: batteryCard.width
                                height: batteryCard.height
                                contentTextColor: batteryGlass.active ? ThemeBackend.text : ThemeBackend.crust
                                iconColor: batteryGlass.active ? ThemeBackend.text : ThemeBackend.crust
                                glass: batteryGlass.active
                            }
                        }
                    }

                    // 2. KARTU POWER PROFILE (Terpisah rapi di sebelah kanan)
                    Rectangle {
                        id: profileCard
                        Layout.preferredWidth: root.isDesktop ? -1 : root.s(160)
                        Layout.fillWidth: root.isDesktop
                        Layout.fillHeight: true
                        radius: root.boxRadius
                        color: ThemeBackend.surface0
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.05)
                        clip: true

                        Switch {
                            id: profileSwitch
                            anchors.fill: parent
                            anchors.margins: root.s(4)
                            cornerRadius: root.boxRadius - root.s(2)
                            fontFamily: root.isDesktop ? ThemeBackend.fontFamily : ThemeBackend.iconFont
                            fontPixelSize: root.isDesktop ? root.s(13) : root.s(18)
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
