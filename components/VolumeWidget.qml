import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland 
import Quickshell.Io
import ".."

Item {
    id: volumeWidget
    implicitWidth: mainLayout.implicitWidth + 16
    implicitHeight: mainLayout.implicitHeight

    property int volumeLevel: 0
    property bool volumeMuted: false

    RowLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: 0

        Text {
            id: volumeText
            width: parent.width
            text: (volumeMuted ? "󰖁 " : "󰕾 ") + volumeLevel 
            color: volumeMuted ? Theme.muted : Theme.text
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            font.bold: true

            // FIX 1: Ensure text stays centered inside the Layout if the top bar stretches it
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            horizontalAlignment: Text.AlignHCenter 
            verticalAlignment: Text.AlignVCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onExited: hideDelay.start()
        onEntered: hideDelay.stop()

        onWheel: (wheel) => {
            let delta = wheel.angleDelta.y > 0 ? "+5%" : "-5%";
            Quickshell.execDetached(["pactl", "set-sink-volume", "@DEFAULT_SINK@", delta]);
            volProc.running = true;
        }
        onClicked: volumeControlProc.running = true
    }

    PopupWindow {
        id: floatingBar
        anchor.window: volumeWidget.QsWindow?.window ?? null

        // FIX 2: CRITICAL! Change `implicitWidth` to `width`. 
        // Wayland CANNOT calculate center-alignment without a hard width.
        implicitWidth: visualBarWrapper.implicitWidth + 10
        implicitHeight: visualBarWrapper.implicitHeight 
        MouseArea {
            id: popupMouseArea 
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onExited: hideDelay.start()
            onEntered: hideDelay.stop()

            onWheel: (wheel) => {
                let delta = wheel.angleDelta.y > 0 ? "+5%" : "-5%";
                Quickshell.execDetached(["pactl", "set-sink-volume", "@DEFAULT_SINK@", delta]);
                volProc.running = true;
            }
        }

        anchor.rect: {
            const window = volumeWidget.QsWindow?.window;
            if (window && window.contentItem && volumeText) {
                return window.contentItem.mapFromItem(
                    volumeText, 
                    -60, 0, 
                    volumeText.width, 
                    volumeText.height
                );
            }
            return Qt.rect(0, 0, 0, 0);
        }

        // FIX 4: Use Quickshell prefix so 'HorizontalCenter' isn't undefined
        anchor.edges: Edges.Bottom| Quickshell.HorizontalCenter

        visible: mouseArea.containsMouse || popupMouseArea.containsMouse || hideDelay.running || visualBar.opacity > 0
        // color: Theme.pine
        color: "transparent"
        Rectangle {

            id: visualBarWrapper
            anchors.centerIn: parent
            implicitWidth: 140
            implicitHeight: 36
            color: Theme.bg
            radius: 8

            Rectangle {
                id: visualBar
                anchors.centerIn: parent
                implicitWidth: 120
                implicitHeight: 12
                color: Theme.overlay
                radius: 6
                border.color: Theme.iris
                border.width: 1
                opacity: (mouseArea.containsMouse || hideDelay.running || popupMouseArea.containsMouse) ? 1 : 0

                Behavior on opacity { 
                    NumberAnimation { duration: 200 } 
                }

                transform: Translate {
                    y: (mouseArea.containsMouse || hideDelay.running || popupMouseArea.containsMouse) ? 0 : -8
                    Behavior on y { 
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic } 
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 3
                    width: {
                        let percentage = Math.min(volumeWidget.volumeLevel / 100, 1.0);
                        return Math.max(0, (parent.width - 6) * percentage);
                    }
                    color: volumeWidget.volumeMuted ? Theme.muted : Theme.love
                    radius: 4 // Note: Changed radius to 4 to match the margin constraint
                }
            }
        }
    }

    // --- Backend (pactl) ---
    Process {
        id: volProc
        command: ["sh", "-c", "pactl get-sink-mute @DEFAULT_SINK@; pactl get-sink-volume @DEFAULT_SINK@"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                volumeWidget.volumeMuted = data.includes("Mute: yes")
                var match = data.match(/(\d+)%/)
                if (match) volumeWidget.volumeLevel = parseInt(match[1], 10)
            }
        }
    }
    Process { id: volumeControlProc; command: ["pavucontrol"] }

    Timer { 
        interval: 500
        running: true
        repeat: true
        onTriggered: volProc.running = true 
    }

    Timer {
        id: hideDelay
        interval: 1000
        running: false
        repeat: false 
    }
}
