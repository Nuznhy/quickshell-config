import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray 
import Quickshell.Widgets 
import QtQuick.Controls 
import ".."
import "."

Rectangle {
    id: trayContainer
    color: Theme.overlay
    radius: 8 
    border.color: Theme.iris
    border.width: 1

    implicitWidth: trayRoot.implicitWidth + 24 
    implicitHeight: 32
    
    RowLayout {
        id: trayRoot
        anchors.centerIn: parent
        spacing: 12

        Repeater {
            model: SystemTray.items

            delegate: MouseArea {
                id: trayItem
                required property var modelData 
                readonly property string cleanIcon: {
                    let path = modelData.icon ? modelData.icon.toString() : "";
                    if (path.includes("?path=")) {
                        path = path.split("?path=")[1];
                    }
                    return path;
                }
                property alias item: trayItem.modelData
                opacity: 0
                scale: 0.5

                Component.onCompleted: {
                    appearAnim.start()
                }

                ParallelAnimation {
                    id: appearAnim
                    NumberAnimation { 
                        target: trayItem; property: "opacity"
                        from: 0; to: 1; duration: 250; easing.type: Easing.OutCubic 
                    }
                    NumberAnimation { 
                        target: trayItem; property: "scale"
                        from: 0.5; to: 1; duration: 300; easing.type: Easing.OutBack 
                    }
                }

                visible: cleanIcon !== ""
                Layout.preferredWidth: visible ? 18 : 0
                Layout.preferredHeight: visible ? 18 : 0
                width: 18
                height: 18
                hoverEnabled: true

                IconImage {
                    anchors.fill: parent
                    source: trayItem.cleanIcon

                    onStatusChanged: {
                        if (status === Image.Error) trayItem.visible = false
                    }
                }

                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                onClicked: event => {
                    if (event.button == Qt.LeftButton) {
                        item.activate();
                    } else if (event.button == Qt.MiddleButton) {
                        item.secondaryActivate();
                    } else if (event.button == Qt.RightButton) {
                        menuAnchor.open();
                    }
                }

                QsMenuAnchor {
                    id: menuAnchor
                    menu: item.menu

                    anchor.window: trayItem.QsWindow.window
                    anchor.adjustment: PopupAdjustment.Flip

                    anchor.onAnchoring: {
                        const window = trayItem.QsWindow.window;
                        const widgetRect = window.contentItem.mapFromItem(trayItem, 0, trayItem.height, trayItem.width, trayItem.height);

                        menuAnchor.anchor.rect = widgetRect;
                    }
                }
            }
        }
    }
}
