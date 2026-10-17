import QtQuick
import qs.components.shared
import qs.components.ui as UI
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.components.popup as PopupScripts

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

    onXChanged: {
        if (dropdownOpen)
            popup.anchor.updateAnchor();
    }
    onYChanged: {
        if (dropdownOpen)
            popup.anchor.updateAnchor();
    }

    Connections {
        target: barWindow
        function onCloseAllPopups() {
            if (root.popupDismissEnabled)
                dropdownOpen = false;
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
            if (!root.wheelEnabled) {
                wheel.accepted = false;
                return;
            }
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
        active: dropdownOpen && popup.visible && root.focusGrabEnabled
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
            if (!root.barWindow?.contentItem)
                return;
            const point = iconContainer.mapToItem(root.barWindow.contentItem, 0, 0);
            const placement = PopupScripts.PopupPlacement.position(Theme.barPosition, point.x, point.y, iconContainer.width, iconContainer.height, root.barWindow.width, root.barWindow.height, popup.width, popup.height, root.stemAlignment, cardRect.stemWidth, root.showStem);
            popup.anchor.rect = Qt.rect(placement.x, placement.y, 1, 1);
        }
        // Layouts can publish intermediate sizes while removing delegates or
        // showing sections. Commit only the settled size to the native popup.
        Binding {
            target: popup
            property: "implicitWidth"
            value: root.widthToContent ? (popupLoader.item ? popupLoader.item.implicitWidth : 0) + Settings.popupPadding * 2 : root.popupWidth
            delayed: true
        }
        Binding {
            target: popup
            property: "implicitHeight"
            value: root.sizeToContent ? (popupLoader.item ? popupLoader.item.implicitHeight : 0) + cardRect.stemHeight + Settings.popupPadding * 2 : root.popupHeight
            delayed: true
        }
        color: "transparent"

        PopupReveal {
            id: popupReveal
            anchors.fill: parent
            opened: root.dropdownOpen

            UI.MenuSurface {
                anchors.fill: parent
                visible: !root.showStem
            }

            Item {
                id: cardRect
                anchors.fill: parent
                readonly property bool showStem: root.showStem
                readonly property int triggerWidth: iconContainer.width
                readonly property string stemAlignment: root.stemAlignment
                readonly property int stemWidth: Math.min(triggerWidth + 16, width - 60)
                readonly property int stemHeight: showStem ? 12 : 0
                Loader {
                    anchors.fill: parent
                    visible: cardRect.showStem
                    readonly property var surface: cardRect
                    sourceComponent: UiKit.visual("dropdownSurface")
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
                popupReveal.finishClosing();
            }
        }
    }
}
