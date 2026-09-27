import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../config"

Item {
    id: root
    Layout.preferredWidth: iconContainer.width
    Layout.preferredHeight: parent.height
    Layout.rightMargin: 8

    required property var barWindow
    property int popupWidth: 200
    property int popupHeight: 150
    property bool sizeToContent: false
    property bool showStem: true
    property int popupXOffset: 200
    property bool dropdownOpen: false
    property string stemAlignment: "center"  // "left", "center", or "right"
    property alias popupContent: popupLoader.sourceComponent

    signal opened

    default property alias iconContent: iconContainer.data

    Connections {
        target: barWindow
        function onCloseAllPopups() {
            dropdownOpen = false;
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: 6
        color: Theme.overlay
        visible: triggerMouse.containsMouse || root.dropdownOpen
    }

    Row {
        id: iconContainer
        anchors.centerIn: parent
        height: parent.height
    }

    MouseArea {
        id: triggerMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            var shouldOpen = !dropdownOpen;
            barWindow.closeAllPopups();
            dropdownOpen = shouldOpen;
            if (shouldOpen) {
                root.opened();
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
        visible: popupReveal.presented
        anchor.window: barWindow
        anchor.rect.x: {
            if (!barWindow || !barWindow.contentItem)
                return 0;
            var iconCenter = iconContainer.mapToItem(barWindow.contentItem, iconContainer.width / 2, 0).x;
            if (stemAlignment === "right") {
                return iconCenter - popupWidth + (root.showStem ? cardRect.stemWidth / 2 + 10 : iconContainer.width / 2 + 8);
            } else if (stemAlignment === "left") {
                return iconCenter - cardRect.stemWidth / 2 - 10;
            } else {
                return iconCenter - popupWidth / 2;
            }
        }
        anchor.rect.y: root.showStem ? 32 : barWindow.height + 4
        implicitWidth: popupWidth
        implicitHeight: root.sizeToContent
            ? (popupLoader.item ? popupLoader.item.implicitHeight : 0) + cardRect.stemHeight + 16
            : root.popupHeight
        color: "transparent"

        PopupReveal {
            id: popupReveal
            anchors.fill: parent
            opened: root.dropdownOpen

            Rectangle {
                anchors.fill: parent
                visible: !root.showStem
                color: Theme.bg
                radius: 12
                border.color: Theme.highlightMed
            }

            // Main card with notch corners
            Canvas {
                id: cardRect
                visible: root.showStem
                anchors.fill: parent

                property int rawStemWidth: iconContainer.width + 16
                property int stemWidth: Math.min(rawStemWidth, width - 60)  // ensure room for notch corners
                property int stemHeight: root.showStem ? 12 : 0
                property int notchRadius: 10
                property int cardRadius: 12
                property color backgroundColor: Theme.bg

                onStemWidthChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onBackgroundColorChanged: requestPaint()

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    ctx.fillStyle = backgroundColor;

                    var sw = stemWidth;
                    var sh = stemHeight;
                    var nr = notchRadius;
                    var r = cardRadius;
                    var w = width;
                    var h = height;

                    // Calculate stem center based on alignment
                    var cx;
                    if (root.stemAlignment === "right") {
                        cx = w - sw / 2 - 10;
                    } else if (root.stemAlignment === "left") {
                        cx = sw / 2 + 10;
                    } else {
                        cx = w / 2;
                    }

                    var stemLeft = cx - sw / 2;
                    var stemRight = cx + sw / 2;

                    ctx.beginPath();
                    ctx.moveTo(stemLeft + r, 0);
                    ctx.lineTo(stemRight - r, 0);
                    ctx.arcTo(stemRight, 0, stemRight, r, r);
                    ctx.lineTo(stemRight, sh - nr);
                    ctx.arcTo(stemRight, sh, stemRight + nr, sh, nr);
                    ctx.lineTo(w - r, sh);
                    ctx.arcTo(w, sh, w, sh + r, r);
                    ctx.lineTo(w, h - r);
                    ctx.arcTo(w, h, w - r, h, r);
                    ctx.lineTo(r, h);
                    ctx.arcTo(0, h, 0, h - r, r);
                    ctx.lineTo(0, sh + r);
                    ctx.arcTo(0, sh, r, sh, r);
                    ctx.lineTo(stemLeft - nr, sh);
                    ctx.arcTo(stemLeft, sh, stemLeft, sh - nr, nr);
                    ctx.lineTo(stemLeft, r);
                    ctx.arcTo(stemLeft, 0, stemLeft + r, 0, r);
                    ctx.closePath();
                    ctx.fill();
                }
            }

            MouseArea {
                anchors.fill: parent
            }

            Loader {
                id: popupLoader
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: root.sizeToContent ? undefined : parent.bottom
                height: root.sizeToContent && item ? item.implicitHeight : 0
                anchors.topMargin: cardRect.stemHeight + 8
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.bottomMargin: 8
            }
        }

        onVisibleChanged: {
            if (!visible) {
                dropdownOpen = false;
            }
        }
    }
}
