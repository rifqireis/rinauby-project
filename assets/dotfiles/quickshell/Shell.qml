import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: shellRoot

    Connections {
        target: Quickshell
        function onReloadCompleted() { Quickshell.inhibitReloadPopup() }
        function onReloadFailed(errorString) { Quickshell.inhibitReloadPopup() }
    }

    Main {}
    RinaubyBar {}
    RinaubyLauncher {}
    RinaubySession {}
    RinaubyMediaControls {}
    Dock {}
    ScreenshotOverlay {}

    Component.onCompleted: {
        Qt.application.organization = "rinauby";
        Qt.application.domain = "rinauby.org";
        Qt.application.name = "rinauby-shell";
    }
}
