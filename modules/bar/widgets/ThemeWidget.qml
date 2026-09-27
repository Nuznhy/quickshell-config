pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import "../../../config"
import "../../../components"

DropdownWidget {
    id: root
    barWindow: root.QsWindow.window
    popupWidth: 340
    sizeToContent: true
    showStem: false
    stemAlignment: "right"
    property bool choosingWallpaper: false
    focusGrabEnabled: !choosingWallpaper
    popupDismissEnabled: !choosingWallpaper

    Text {
        height: parent.height
        width: 30
        text: "󰏘"
        color: root.dropdownOpen ? Theme.iris : Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    popupContent: ScrollView {
        id: scroll
        implicitHeight: Math.min(picker.implicitHeight, Math.max(120, (root.barWindow?.screen?.height || 800) - 110))
        contentWidth: availableWidth
        clip: true
        ThemePicker {
            id: picker
            width: scroll.availableWidth
            onChoosingWallpaperChanged: root.choosingWallpaper = choosingWallpaper
            onDismissed: root.dropdownOpen = false
        }
    }
}
