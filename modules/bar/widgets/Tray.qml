pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../../../config"
import "../../../components"

DropdownWidget {
    id: root
    barWindow: root.QsWindow.window
    Layout.preferredHeight: Settings.barHeight
    Layout.rightMargin: 0
    sizeToContent: true
    widthToContent: true
    showStem: false
    focusGrabEnabled: currentMenu === null
    // Native menus take focus away from the tray. Keep their parent popup
    // alive when that focus change triggers the bar's closeAllPopups signal.
    popupDismissEnabled: currentMenu === null
    property var currentMenu: null
    readonly property int itemCount: SystemTray.items.values.length

    onDropdownOpenChanged: {
        if (!dropdownOpen && currentMenu)
            currentMenu.close();
    }

    Text {
        width: 30
        height: parent.height
        text: "󰅀"
        color: root.dropdownOpen ? Theme.iris : Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize + 2
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        rotation: (Theme.barPosition === "left" ? -90 : Theme.barPosition === "right" ? 90 : Theme.barPosition === "bottom" ? 180 : 0)
            + (root.dropdownOpen ? 180 : 0)
        Behavior on rotation {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }
    }

    popupContent: FocusScope {
        implicitWidth: root.itemCount > 0 ? grid.implicitWidth : emptyLabel.implicitWidth + 16
        implicitHeight: root.itemCount > 0 ? grid.implicitHeight : 32
        focus: root.dropdownOpen
        Keys.onEscapePressed: root.dropdownOpen = false

        Text {
            id: emptyLabel
            anchors.centerIn: parent
            visible: root.itemCount === 0
            text: "No tray applications"
            font.family: Theme.fontFamily
            font.pixelSize: Math.round(Theme.fontSize * 0.6)
            color: Theme.subtle
        }

        Grid {
            id: grid
            columns: Math.max(1, Math.min(6, root.itemCount))
            spacing: 6

            Repeater {
                model: SystemTray.items

                delegate: MouseArea {
                    id: trayItem
                    required property var modelData
                    width: 32
                    height: 32
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                    function openMenu() {
                        if (!modelData.hasMenu) return;
                        if (root.currentMenu && root.currentMenu !== menuAnchor)
                            root.currentMenu.close();
                        root.currentMenu = menuAnchor;
                        menuAnchor.open();
                    }

                    Component.onDestruction: {
                        if (root.currentMenu === menuAnchor)
                            root.currentMenu = null;
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: Theme.highlightMed
                        opacity: trayItem.containsMouse ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    IconImage {
                        id: trayIcon
                        anchors.centerIn: parent
                        width: 20
                        height: 20
                        // Preserve the complete image-provider URL and its search path.
                        source: trayItem.modelData.icon
                        visible: status === Image.Ready
                        scale: trayItem.containsMouse ? 1.15 : 1
                        Behavior on scale {
                            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: trayIcon.status !== Image.Ready
                        text: "󰏗"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Math.round(Theme.fontSize * 1.0)
                    }

                    onClicked: event => {
                        if (event.button === Qt.RightButton || (event.button === Qt.LeftButton && modelData.onlyMenu)) {
                            openMenu();
                        } else if (event.button === Qt.MiddleButton) {
                            modelData.secondaryActivate();
                        } else if (event.button === Qt.LeftButton) {
                            modelData.activate();
                            root.dropdownOpen = false;
                        }
                    }

                    onWheel: event => {
                        const horizontal = event.angleDelta.y === 0;
                        modelData.scroll(horizontal ? event.angleDelta.x : event.angleDelta.y, horizontal);
                    }

                    QsMenuAnchor {
                        id: menuAnchor
                        menu: trayItem.modelData.menu
                        anchor.window: trayItem.QsWindow.window
                        anchor.adjustment: PopupAdjustment.Flip
                        anchor.onAnchoring: {
                            const window = trayItem.QsWindow.window;
                            if (window && window.contentItem)
                                menuAnchor.anchor.rect = window.contentItem.mapFromItem(trayItem, 0, trayItem.height, trayItem.width, 1);
                        }
                        onClosed: {
                            if (root.currentMenu === menuAnchor)
                                root.currentMenu = null;
                        }
                    }
                }
            }
        }
    }
}
