// components/CustomMenu.qml
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray

// We use a basic Component so the Anchor can instantiate it
Component {
    id: menuComponent
    
    Menu {
        id: root
        
        background: Rectangle {
            implicitWidth: 180
            color: Theme.overlay
            radius: 10
            border.color: Theme.iris
            border.width: 1
        }

        // This is where we tell Quickshell how to draw each entry
        delegate: MenuItem {
            id: itemDelegate
            
            // modelData here is a QsMenuEntry object
            text: modelData.label
            enabled: modelData.enabled
            visible: modelData.visible

            contentItem: Text {
                text: itemDelegate.text
                color: itemDelegate.highlighted ? Theme.base : Theme.text
                font.pixelSize: 13
                verticalAlignment: Text.AlignVCenter
                leftPadding: 10
            }

            background: Rectangle {
                color: itemDelegate.highlighted ? Theme.love : "transparent"
                radius: 6
                anchors.fill: parent
                anchors.margins: 4
            }
            
            // Handle submenus if the app has them
            // QsMenuAnchor handles this automatically if you use standard Menu/MenuItem
        }
    }
}
