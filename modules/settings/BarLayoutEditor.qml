pragma ComponentBehavior: Bound
import QtQuick
import "../../components/ui" as UI
import QtQuick.Controls
import QtQuick.Layouts
import "../../config"
import "../../components"

FocusScope {
    id: root
    signal settingsRequested(string widgetId)
    property string dragId: ""
    property bool dragCanceled: false
    property point pointer: Qt.point(0, 0)
    property string destination: ""
    property int insertionIndex: -1
    readonly property bool dragging: dragId !== ""
    implicitWidth: 840
    implicitHeight: 520
    onVisibleChanged: { if (!visible) cancelDrag(); }
    Keys.onEscapePressed: event => {
        if (dragging) { cancelDrag(); event.accepted = true; }
        else event.accepted = false;
    }

    function cancelDrag() {
        dragCanceled = true;
        dragId = "";
        destination = "";
        insertionIndex = -1;
    }
    function updateTarget(point) {
        pointer = point;
        destination = "";
        insertionIndex = -1;
        for (let i = 0; i < lanes.count; ++i) {
            const lane = lanes.itemAt(i);
            const p = lane.viewport.mapFromItem(root, point.x, point.y);
            if (p.x < 0 || p.x > lane.viewport.width || p.y < 0 || p.y > lane.viewport.height) continue;
            destination = lane.section;
            insertionIndex = Math.max(0, Math.min(lane.count, Math.floor((p.y + lane.viewport.contentY + 26) / 58)));
            break;
        }
    }
    function finishDrag() {
        const id = dragId, section = destination, index = insertionIndex;
        cancelDrag();
        if (id && section && index >= 0) BarLayout.move(id, section, index);
    }

    Timer {
        interval: 30
        running: root.dragging
        repeat: true
        onTriggered: {
            for (let i = 0; i < lanes.count; ++i) {
                const lane = lanes.itemAt(i);
                if (lane.section !== root.destination) continue;
                const view = lane.viewport;
                const p = view.mapFromItem(root, root.pointer.x, root.pointer.y);
                const delta = p.y < 28 ? -8 : p.y > view.height - 28 ? 8 : 0;
                view.contentY = Math.max(0, Math.min(Math.max(0, view.contentHeight - view.height), view.contentY + delta));
            }
            root.updateTarget(root.pointer);
        }
    }

    UI.ColumnLayout {
        anchors.fill: parent
        spacing: Design.space16
        UI.RowLayout {
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }
            NotificationButton {
                objectName: "resetLayout"
                text: "Reset layout"
                enabled: BarLayout.ready && !root.dragging
                onClicked: BarLayout.reset()
            }
        }
        UI.RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Design.space12
            Repeater {
                id: lanes
                model: ["start", "center", "end"]
                delegate: UI.Card {
                    id: lane
                    required property string modelData
                    required property int index
                    property string section: modelData
                    property alias viewport: scroll
                    readonly property int count: cards.count
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1

                    border.color: root.destination === section ? Design.accent : Design.border
                    UI.Text {
                        x: Design.panelPadding; y: 14
                        text: (Theme.verticalBar ? ["Top", "Middle", "Bottom"] : ["Start", "Center", "End"])[lane.index]
                        color: Design.text
                        font.family: Design.fontFamily
                        role: "section"
                        font.bold: true
                    }
                    Flickable {
                        id: scroll
                        objectName: "lane-" + lane.section
                        anchors.fill: parent
                        anchors.margins: Design.space8
                        anchors.topMargin: Design.controlHeight + Design.space16
                        contentWidth: width
                        contentHeight: Math.max(height, cards.count * 58 + 4)
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        interactive: !root.dragging
                        ScrollBar.vertical: UI.ScrollBar {}
                        UI.Text {
                            visible: cards.count === 0
                            anchors.centerIn: parent
                            text: "Drop widgets here"
                            color: Design.textSecondary
                            font.family: Design.fontFamily
                            role: "label"
                        }
                        Repeater {
                            id: cards
                            model: BarLayout.ids(lane.section)
                            delegate: Rectangle {
                                id: card
                                required property string modelData
                                required property int index
                                objectName: "card-" + modelData
                                x: 2; y: 2 + index * 58
                                width: scroll.width - 4
                                height: 50
                                radius: Design.radiusControl
                                color: handle.containsMouse ? Design.border : Design.surfaceRaised
                                opacity: root.dragId === modelData ? 0.3 : BarLayout.isEnabled(modelData) ? 1 : 0.55
                                border.color: handle.activeFocus ? Design.accent : "transparent"
                                MouseArea {
                                    id: handle
                                    objectName: "drag-" + card.modelData
                                    anchors.fill: parent
                                    anchors.rightMargin: BarLayout.entry(card.modelData).settings ? 88 : 54
                                    hoverEnabled: true
                                    enabled: BarLayout.ready
                                    cursorShape: root.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                    property point start
                                    onPressed: event => {
                                        start = mapToItem(root, event.x, event.y);
                                        root.dragCanceled = false;
                                        root.forceActiveFocus();
                                    }
                                    onPositionChanged: event => {
                                        if (!pressed || root.dragCanceled) return;
                                        const p = mapToItem(root, event.x, event.y);
                                        if (!root.dragging && Math.abs(p.x - start.x) + Math.abs(p.y - start.y) > 8)
                                            root.dragId = card.modelData;
                                        if (root.dragging) root.updateTarget(p);
                                    }
                                    onReleased: root.finishDrag()
                                    onCanceled: root.cancelDrag()
                                    UI.Text {
                                        anchors.fill: parent
                                        anchors.leftMargin: Design.space8
                                        anchors.rightMargin: Design.space4
                                        text: "⠿  " + BarLayout.entry(card.modelData).label
                                        color: Design.text
                                        font.family: Design.fontFamily
                                        role: "body"
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                    }
                                }
                                UI.IconButton {
                                    objectName: "settings-" + card.modelData
                                    visible: !!BarLayout.entry(card.modelData).settings
                                    anchors.right: parent.right
                                    anchors.rightMargin: Design.space8 + Design.switchWidth + Design.space8
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 28
                                    height: 28
                                    text: "󰒓"
                                    enabled: BarLayout.ready && !root.dragging
                                    Accessible.name: "Configure " + BarLayout.entry(card.modelData).label
                                    onClicked: root.settingsRequested(card.modelData)
                                }
                                ControlSwitch {
                                    objectName: "toggle-" + card.modelData
                                    anchors.right: parent.right
                                    anchors.rightMargin: Design.space8
                                    anchors.verticalCenter: parent.verticalCenter
                                    value: BarLayout.isEnabled(card.modelData)
                                    enabled: BarLayout.ready && !root.dragging
                                    Accessible.name: "Show " + BarLayout.entry(card.modelData).label
                                    onChangeRequested: value => BarLayout.setEnabled(card.modelData, value)
                                }
                            }
                        }
                        Rectangle {
                            visible: root.dragging && root.destination === lane.section
                            x: 2
                            y: root.insertionIndex * 58
                            width: scroll.width - 4
                            height: 3
                            radius: Design.radiusSmall
                            color: Design.accent
                        }
                    }
                }
            }
        }

    }
    Rectangle {
        visible: root.dragging
        x: Math.max(0, Math.min(root.width - width, root.pointer.x + 12))
        y: Math.max(0, Math.min(root.height - height, root.pointer.y + 12))
        width: 180; height: 42
        z: 10
        radius: Design.radiusControl
        color: Design.accent
        UI.Text {
            anchors.centerIn: parent
            text: root.dragId ? BarLayout.entry(root.dragId).label : ""
            color: Design.background
            font.family: Design.fontFamily
            role: "body"
        }
    }
}
