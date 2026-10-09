pragma ComponentBehavior: Bound
import QtQuick
import "ui" as UI
import Quickshell.Wayland
import Quickshell.Widgets
import "../config"
import "../services"
import "../services/WorkspacePreviewData.js" as PreviewData

Item {
    id: root
    required property int workspaceId
    required property var monitorBounds
    property string monitorName: ""
    property string highlightedAddress: ""
    property bool active: true
    readonly property var windows: Workspaces.getWsWindows(workspaceId)
    readonly property var selectedWindow: windows.find(window => window.address === highlightedAddress)
    readonly property real previewWidth: Math.max(1, width)
    readonly property real previewHeight: previewWidth * monitorBounds.height / monitorBounds.width
    implicitHeight: previewHeight + 30

    UI.Text {
        width: parent.width
        text: "Workspace " + root.workspaceId + (root.selectedWindow ? " · " + root.selectedWindow.title : "")
        textFormat: Text.PlainText
        color: Design.text
        font.family: Design.fontFamily
        role: "body"
        elide: Text.ElideRight
    }
    Rectangle {
        id: desktop
        y: 26
        width: root.previewWidth
        height: root.previewHeight
        color: Design.background
        clip: true
        Image {
            anchors.fill: parent
            source: Theme.wallpaperFor(root.monitorName)
            asynchronous: true
            sourceSize: Qt.size(760, 520)
            fillMode: Image.PreserveAspectCrop
        }
        Repeater {
            model: root.windows
            delegate: Rectangle {
                id: window
                required property var modelData
                readonly property var rect: PreviewData.project(modelData, root.monitorBounds, desktop.width, desktop.height)
                x: rect.x; y: rect.y; width: rect.width; height: rect.height
                // Hyprland's recent-focus rank approximates stacking within layers.
                z: (modelData.fullscreen ? 30000 : modelData.floating ? 20000 : 10000) - Math.min(9999, modelData.rank)
                color: Design.surface
                clip: true
                ScreencopyView {
                    id: capture
                    objectName: "workspace-preview-capture-" + window.modelData.address
                    anchors.fill: parent
                    captureSource: root.active ? Workspaces.captureSource(window.modelData.address) : null
                    live: false
                    paintCursor: false
                }
                Column {
                    anchors.centerIn: parent
                    width: Math.max(0, parent.width - 8)
                    spacing: Design.space4
                    visible: !capture.hasContent
                    IconImage {
                        anchors.horizontalCenter: parent.horizontalCenter
                        implicitSize: Math.min(26, window.height / 2)
                        source: Workspaces.getWsIcons(root.workspaceId).find(icon => icon.address === window.modelData.address)?.source || ""
                    }
                    UI.Text {
                        width: parent.width
                        text: window.modelData.title
                        textFormat: Text.PlainText
                        color: Design.text
                        font.family: Design.fontFamily
                        role: "caption"
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: 1
                    border.color: Design.border
                }
                Timer {
                    interval: 250
                    running: root.active && capture.hasContent
                    repeat: true
                    onTriggered: capture.captureFrame()
                }
            }
        }
        Rectangle {
            objectName: "workspace-preview-highlight"
            readonly property var rect: root.selectedWindow
                ? PreviewData.project(root.selectedWindow, root.monitorBounds, desktop.width, desktop.height)
                : {x: 0, y: 0, width: 0, height: 0}
            x: rect.x; y: rect.y; width: rect.width; height: rect.height
            visible: !!root.selectedWindow
            z: 100000
            color: "transparent"
            border.color: Design.accent
            border.width: 3
        }
    }
}
