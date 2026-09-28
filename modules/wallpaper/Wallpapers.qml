pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../config"
import "../../components"

Variants {
    model: Quickshell.screens
    PanelWindow {
        id: wallpaperWindow
        required property var modelData
        readonly property string wallpaperSource: Theme.wallpaperFor(modelData.name)
        screen: modelData
        visible: Theme.ready && (wallpaperSource.length > 0 || transition.hasContent)
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell-wallpaper"
        mask: Region {}
        color: Theme.bg
        WallpaperTransition {
            id: transition
            anchors.fill: parent
            source: wallpaperWindow.wallpaperSource
            mode: Theme.mode
            ready: Theme.ready
            style: Theme.wallpaperTransitionStyle
            backgroundColor: Theme.bg
            pixelSize: Qt.size(
                Math.ceil((wallpaperWindow.modelData.width || 1920) * (wallpaperWindow.modelData.devicePixelRatio || 1)),
                Math.ceil((wallpaperWindow.modelData.height || 1080) * (wallpaperWindow.modelData.devicePixelRatio || 1)))
        }
    }
}
