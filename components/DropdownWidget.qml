import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../config"
import "PopupPlacement.js" as PopupPlacement

Item {
    id: root
    implicitWidth: iconContainer.width
    implicitHeight: Settings.barHeight
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: Settings.barHeight

    required property var barWindow
    property int popupWidth: 200
    property int popupHeight: 150
    property bool sizeToContent: false
    property bool widthToContent: false
    property bool focusGrabEnabled: true
    property bool popupDismissEnabled: true
    property bool showStem: true
    property bool showHoverIndicator: true
    property int popupXOffset: 200
    property bool dropdownOpen: false
    property bool rightClickEnabled: false
    property bool wheelEnabled: false
    property string stemAlignment: "center"  // "left", "center", or "right"
    property alias popupContent: popupLoader.sourceComponent

    signal opened
    signal rightClicked
    signal wheelScrolled(int delta)

    default property alias iconContent: iconContainer.data

    onXChanged: { if (dropdownOpen) popup.anchor.updateAnchor(); }
    onYChanged: { if (dropdownOpen) popup.anchor.updateAnchor(); }

    Connections {
        target: barWindow
        function onCloseAllPopups() {
            if (root.popupDismissEnabled) dropdownOpen = false;
        }
    }

    BarHoverIndicator {
        anchors.fill: parent
        hovered: root.showHoverIndicator && triggerMouse.containsMouse
        active: root.showHoverIndicator && root.dropdownOpen
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
        acceptedButtons: root.rightClickEnabled ? Qt.LeftButton | Qt.RightButton : Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onWheel: wheel => {
            if (!root.wheelEnabled) { wheel.accepted = false; return; }
            root.wheelScrolled(wheel.angleDelta.y);
        }
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                root.rightClicked();
                return;
            }
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
        active: dropdownOpen && root.focusGrabEnabled
        onCleared: {
            if (root.focusGrabEnabled)
                dropdownOpen = false;
        }
    }

    PopupWindow {
        id: popup
        visible: popupReveal.presented
        anchor.window: root.barWindow
        anchor.adjustment: PopupAdjustment.SlideX | PopupAdjustment.SlideY
        anchor.onAnchoring: {
            if (!root.barWindow?.contentItem) return;
            const point = iconContainer.mapToItem(root.barWindow.contentItem, 0, 0);
            const placement = PopupPlacement.position(Theme.barPosition, point.x, point.y,
                iconContainer.width, iconContainer.height, root.barWindow.width, root.barWindow.height,
                popup.width, popup.height, root.stemAlignment, cardRect.stemWidth, root.showStem);
            popup.anchor.rect = Qt.rect(placement.x, placement.y, 1, 1);
        }
        implicitWidth: root.widthToContent
            ? (popupLoader.item ? popupLoader.item.implicitWidth : 0) + Settings.popupPadding * 2
            : root.popupWidth
        implicitHeight: root.sizeToContent
            ? (popupLoader.item ? popupLoader.item.implicitHeight : 0) + cardRect.stemHeight + Settings.popupPadding * 2
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
                anchors.topMargin: cardRect.stemHeight + Settings.popupPadding
                anchors.leftMargin: Settings.popupPadding
                anchors.rightMargin: Settings.popupPadding
                anchors.bottomMargin: Settings.popupPadding
            }
        }

        onVisibleChanged: {
            if (!visible) {
                dropdownOpen = false;
            }
        }
    }
}
