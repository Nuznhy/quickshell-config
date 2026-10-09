import QtQuick
import "ui" as UI
import QtQuick.Window
import "../config"
import "../services"
import "../config/AppGlyphs.js" as AppGlyphs

Grid {
    id: root
    columns: Theme.verticalBar ? 1 : Math.max(1, iconModel.count)
    required property var icons
    required property bool activeWorkspace
    property bool nerdFontIcons: false
    readonly property int count: iconModel.count
    property string hoveredAddress: ""
    onVisibleChanged: { if (!visible) hoveredAddress = ""; }
    signal windowClicked
    spacing: Design.space4

    move: Transition {
        NumberAnimation { properties: "x,y"; duration: 220; easing.type: Easing.OutCubic }
    }

    ListModel {
        id: iconModel
    }

    function removeIcon(address) {
        for (let i = 0; i < iconModel.count; ++i) {
            if (iconModel.get(i).windowAddress === address && !iconModel.get(i).present) {
                iconModel.remove(i);
                return;
            }
        }
    }

    function syncIcons() {
        const incoming = icons || [];
        const ids = new Set(incoming.map(icon => icon.address));
        for (let i = 0; i < iconModel.count; ++i)
            iconModel.setProperty(i, "present", ids.has(iconModel.get(i).windowAddress));
        for (const icon of incoming) {
            let index = -1;
            for (let i = 0; i < iconModel.count; ++i) {
                if (iconModel.get(i).windowAddress === icon.address) {
                    index = i;
                    break;
                }
            }
            const payload = JSON.stringify(icon);
            if (index < 0) {
                iconModel.append({
                    windowAddress: icon.address,
                    iconJson: payload,
                    present: true
                });
            } else {
                if (iconModel.get(index).iconJson !== payload)
                    iconModel.setProperty(index, "iconJson", payload);
                iconModel.setProperty(index, "present", true);
            }
        }
    }

    onIconsChanged: syncIcons()
    Component.onCompleted: syncIcons()

    Repeater {
        model: iconModel
        Item {
            id: appIcon
            required property string windowAddress
            objectName: "workspace-window-" + windowAddress
            required property string iconJson
            required property bool present
            readonly property var modelData: JSON.parse(iconJson)
            property bool appeared: false
            Component.onCompleted: appeared = true
            enabled: present
            onPresentChanged: { if (!present && root.hoveredAddress === windowAddress) root.hoveredAddress = ""; }
            opacity: appeared && present ? 1 : 0
            scale: appeared && present ? 1 : 0.5

            Behavior on opacity {
                NumberAnimation {
                    duration: 160
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: appIcon.present ? 200 : 160
                    easing.type: appIcon.present ? Easing.OutBack : Easing.InCubic
                }
            }
            Timer {
                interval: 180
                running: !appIcon.present
                onTriggered: root.removeIcon(appIcon.windowAddress)
            }
            width: Theme.fontSize - 1
            height: width
            property real iconScale: iconMouse.containsMouse ? 1.25 : 1
            readonly property bool needsAttention: Workspaces.needsAttention(modelData.appId, modelData.addresses)

            Behavior on iconScale {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }

            Image {
                id: systemIcon
                anchors.fill: parent
                objectName: "workspace-app-image-" + appIcon.windowAddress
                source: root.nerdFontIcons ? "" : appIcon.modelData.source
                // Keep enough detail for hover zoom and scaled displays without
                // reloading the image on every animation frame.
                readonly property int textureSize: Math.ceil(width * Screen.devicePixelRatio * 2)
                sourceSize: Qt.size(textureSize, textureSize)
                fillMode: Image.PreserveAspectFit
                mipmap: true
                visible: !root.nerdFontIcons && status === Image.Ready
                scale: appIcon.iconScale
            }

            UI.Text {
                id: glyph
                objectName: "workspace-app-glyph-" + appIcon.windowAddress
                x: (parent.width - glyphMetrics.tightBoundingRect.width) / 2 - glyphMetrics.tightBoundingRect.x
                y: (parent.height - glyphMetrics.tightBoundingRect.height) / 2 - glyphMetrics.tightBoundingRect.y - baselineOffset
                visible: root.nerdFontIcons || systemIcon.status !== Image.Ready
                text: root.nerdFontIcons ? AppGlyphs.resolve(appIcon.modelData.appId) : "󰏗"
                font.family: Design.fontFamily
                font.pixelSize: appIcon.height
                color: root.activeWorkspace ? Design.danger : Design.text
                scale: appIcon.iconScale
            }
            TextMetrics { id: glyphMetrics; font: glyph.font; text: glyph.text }

            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: -3
                anchors.rightMargin: -3
                width: 9
                height: 9
                radius: width / 2
                color: Design.danger
                border.color: Design.background
                border.width: 1
                visible: appIcon.needsAttention
            }

            MouseArea {
                id: iconMouse
                anchors.fill: parent
                anchors.margins: -3
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.hoveredAddress = appIcon.windowAddress
                onExited: { if (root.hoveredAddress === appIcon.windowAddress) root.hoveredAddress = ""; }
                onClicked: { root.windowClicked(); Workspaces.focusWindow(appIcon.modelData.address); }
            }
        }
    }
}
