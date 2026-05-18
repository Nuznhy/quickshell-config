import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

DropdownWidget {
    id: wifiWidget
    popupWidth: 240
    popupHeight: Math.min(wifiNetworks.length * 40 + 50, 350)
    popupXOffset: 250

    property string wifiSSID: ""
    property int wifiSignal: 0
    property bool wifiConnected: false
    property var wifiNetworks: []

    // Network speed tracking
    property real downloadSpeed: 0  // bytes per second
    property real uploadSpeed: 0
    property real lastRxBytes: 0
    property real lastTxBytes: 0

    function formatSpeed(bytesPerSec) {
        if (bytesPerSec < 1024) return bytesPerSec.toFixed(0) + " B/s"
        if (bytesPerSec < 1024 * 1024) return (bytesPerSec / 1024).toFixed(0) + " K/s"
        return (bytesPerSec / 1024 / 1024).toFixed(1) + " M/s"
    }

    onOpened: wifiScanProc.running = true

    // WiFi current connection
    Process {
        id: wifiCurrentProc
        command: ["sh", "-c", "nmcli -t -f ACTIVE,SSID,SIGNAL device wifi list | grep '^yes' | head -1"]
        stdout: SplitParser {
            onRead: data => {
                if (!data || !data.trim()) {
                    wifiWidget.wifiConnected = false
                    wifiWidget.wifiSSID = ""
                    wifiWidget.wifiSignal = 0
                    return
                }
                var parts = data.trim().split(':')
                if (parts.length >= 3) {
                    wifiWidget.wifiConnected = true
                    wifiWidget.wifiSSID = parts[1]
                    wifiWidget.wifiSignal = parseInt(parts[2]) || 0
                }
            }
        }
        Component.onCompleted: running = true
    }

    // WiFi network scan
    Process {
        id: wifiScanProc
        property string output: ""
        command: ["sh", "-c", "nmcli -t -f SSID,SIGNAL,SECURITY device wifi list | grep -v '^:' | sort -t: -k2 -nr | head -15"]
        stdout: SplitParser {
            onRead: data => {
                if (data) wifiScanProc.output += data + "\n"
            }
        }
        onRunningChanged: {
            if (running) {
                output = ""
            } else if (output) {
                var lines = output.trim().split('\n')
                var networks = []
                var seen = {}
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split(':')
                    if (parts.length >= 2 && parts[0] && !seen[parts[0]]) {
                        seen[parts[0]] = true
                        networks.push({
                            ssid: parts[0],
                            signal: parseInt(parts[1]) || 0,
                            security: parts[2] || ""
                        })
                    }
                }
                wifiWidget.wifiNetworks = networks
            }
        }
    }

    // WiFi connect process
    Process {
        id: wifiConnectProc
        property string targetSSID: ""
        command: ["nmcli", "device", "wifi", "connect", targetSSID]
    }

    // Network speed process
    Process {
        id: netSpeedProc
        command: ["sh", "-c", "cat /proc/net/dev | grep -E 'wl|en' | head -1"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(/\s+/)
                if (parts.length >= 10) {
                    var rxBytes = parseFloat(parts[1]) || 0
                    var txBytes = parseFloat(parts[9]) || 0

                    if (wifiWidget.lastRxBytes > 0) {
                        wifiWidget.downloadSpeed = rxBytes - wifiWidget.lastRxBytes
                        wifiWidget.uploadSpeed = txBytes - wifiWidget.lastTxBytes
                    }
                    wifiWidget.lastRxBytes = rxBytes
                    wifiWidget.lastTxBytes = txBytes
                }
            }
        }
        Component.onCompleted: running = true
    }

    // Update timer
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            wifiCurrentProc.running = true
            netSpeedProc.running = true
        }
    }

    // Icon content
    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Text {
            id: wifiText
            anchors.verticalCenter: parent.verticalCenter
            text: !wifiConnected ? "󰤭" :
                  wifiSignal >= 80 ? "󰤨" :
                  wifiSignal >= 60 ? "󰤥" :
                  wifiSignal >= 40 ? "󰤢" :
                  wifiSignal >= 20 ? "󰤟" : "󰤯"
            color: wifiConnected ? Theme.text : Theme.muted
            font.pixelSize: Theme.fontSize + 4
            font.family: Theme.fontFamily
            font.bold: true
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: wifiConnected
            text: " " + formatSpeed(downloadSpeed) + "  " + formatSpeed(uploadSpeed)
            color: Theme.text
            font.pixelSize: Theme.fontSize - 2
            font.family: Theme.fontFamily
            width: 120
            horizontalAlignment: Text.AlignLeft
        }

        Rectangle {
            width: 1
            height: 16
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.muted
        }
    }

    // Popup content
    popupContent: Component {
        Column {
            spacing: 4

            // Header
            Text {
                text: wifiWidget.wifiConnected ? "󰤨 " + wifiWidget.wifiSSID : "󰤭 Not Connected"
                color: Theme.text
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
                font.bold: true
                width: parent.width
                horizontalAlignment: Text.AlignLeft
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.muted
            }

            // Network list
            ListView {
                id: networkListView
                width: parent.width
                height: parent.height - 40
                clip: true
                model: wifiWidget.wifiNetworks
                spacing: 2

                delegate: Rectangle {
                    width: networkListView.width
                    height: 36
                    color: mouseArea.containsMouse ? Qt.rgba(255, 255, 255, 0.1) : "transparent"
                    radius: 6

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 8

                        Text {
                            text: modelData.signal >= 80 ? "󰤨" :
                                  modelData.signal >= 60 ? "󰤥" :
                                  modelData.signal >= 40 ? "󰤢" :
                                  modelData.signal >= 20 ? "󰤟" : "󰤯"
                            color: Theme.text
                            font.pixelSize: Theme.fontSize
                            font.family: Theme.fontFamily
                        }

                        Text {
                            text: modelData.ssid
                            color: modelData.ssid === wifiWidget.wifiSSID ? Theme.text : Theme.text
                            font.pixelSize: Theme.fontSize - 1
                            font.family: Theme.fontFamily
                            font.bold: modelData.ssid === wifiWidget.wifiSSID
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: modelData.security ? "󰌾" : ""
                            color: Theme.muted
                            font.pixelSize: Theme.fontSize - 2
                            font.family: Theme.fontFamily
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            wifiConnectProc.targetSSID = modelData.ssid
                            wifiConnectProc.running = true
                            wifiWidget.dropdownOpen = false
                        }
                    }
                }
            }
        }
    }
}
