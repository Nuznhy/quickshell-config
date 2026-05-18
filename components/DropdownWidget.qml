import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."

Item {
    id: root
    Layout.preferredWidth: iconContainer.width
    Layout.preferredHeight: parent.height
    Layout.rightMargin: 8

    required property var barWindow
    property int popupWidth: 200
    property int popupHeight: 150
    property int popupXOffset: 200
    property bool dropdownOpen: false
    property string stemAlignment: "center"  // "left", "center", or "right"
    property alias popupContent: popupLoader.sourceComponent

    signal opened()

    default property alias iconContent: iconContainer.data

    Connections {
        target: barWindow
        onCloseAllPopups: {
            dropdownOpen = false
        }
    }

    Row {
        id: iconContainer
        anchors.centerIn: parent
        height: parent.height
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            dropdownOpen = !dropdownOpen
            if (dropdownOpen) {
                root.opened()
            }
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [popup]
        active: dropdownOpen
        onCleared: dropdownOpen = false
    }

    PopupWindow {
        id: popup
        visible: dropdownOpen
        anchor.window: barWindow
        anchor.rect.x: {
            var iconCenter = root.x + iconContainer.x + iconContainer.width/2
            if (stemAlignment === "right") {
                return iconCenter - popupWidth + cardRect.stemWidth/2 + 10
            } else if (stemAlignment === "left") {
                return iconCenter - cardRect.stemWidth/2 - 10
            } else {
                return iconCenter - popupWidth/2
            }
        }
        anchor.rect.y: 32
        implicitWidth: popupWidth
        implicitHeight: popupHeight
        color: "transparent"

        // Main card with notch corners
        Canvas {
            id: cardRect
            anchors.fill: parent

            property int rawStemWidth: iconContainer.width + 16
            property int stemWidth: Math.min(rawStemWidth, width - 60)  // ensure room for notch corners
            property int stemHeight: 12
            property int notchRadius: 10
            property int cardRadius: 12

            onStemWidthChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                ctx.fillStyle = Theme.colBg

                var sw = stemWidth
                var sh = stemHeight
                var nr = notchRadius
                var r = cardRadius
                var w = width
                var h = height

                // Calculate stem center based on alignment
                var cx
                if (root.stemAlignment === "right") {
                    cx = w - sw/2 - 10
                } else if (root.stemAlignment === "left") {
                    cx = sw/2 + 10
                } else {
                    cx = w / 2
                }

                var stemLeft = cx - sw/2
                var stemRight = cx + sw/2

                ctx.beginPath()
                ctx.moveTo(stemLeft + r, 0)
                ctx.lineTo(stemRight - r, 0)
                ctx.arcTo(stemRight, 0, stemRight, r, r)
                ctx.lineTo(stemRight, sh - nr)
                ctx.arcTo(stemRight, sh, stemRight + nr, sh, nr)
                ctx.lineTo(w - r, sh)
                ctx.arcTo(w, sh, w, sh + r, r)
                ctx.lineTo(w, h - r)
                ctx.arcTo(w, h, w - r, h, r)
                ctx.lineTo(r, h)
                ctx.arcTo(0, h, 0, h - r, r)
                ctx.lineTo(0, sh + r)
                ctx.arcTo(0, sh, r, sh, r)
                ctx.lineTo(stemLeft - nr, sh)
                ctx.arcTo(stemLeft, sh, stemLeft, sh - nr, nr)
                ctx.lineTo(stemLeft, r)
                ctx.arcTo(stemLeft, 0, stemLeft + r, 0, r)
                ctx.closePath()
                ctx.fill()
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        Loader {
            id: popupLoader
            anchors.fill: parent
            anchors.topMargin: cardRect.stemHeight + 8
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.bottomMargin: 8
        }

        onVisibleChanged: {
            if (!visible) {
                dropdownOpen = false
            }
        }
    }
}
