pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../config"
import "../../components"

FocusScope {
    id: root
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

    ColumnLayout {
        anchors.fill: parent
        spacing: 16
        RowLayout {
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }
            NotificationButton {
                objectName: "resetLayout"
                text: "Reset layout"
                enabled: BarLayout.ready && !root.dragging
                onClicked: BarLayout.reset()
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12
            Repeater {
                id: lanes
                model: ["start", "center", "end"]
                delegate: Rectangle {
                    id: lane
                    required property string modelData
                    required property int index
                    property string section: modelData
                    property alias viewport: scroll
                    readonly property int count: cards.count
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    color: Theme.surface
                    radius: 12
                    border.color: root.destination === section ? Theme.iris : Theme.highlightMed
                    Text {
                        x: 12; y: 14
                        text: (Theme.verticalBar ? ["Top", "Middle", "Bottom"] : ["Start", "Center", "End"])[lane.index]
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.bold: true
                    }
                    Flickable {
                        id: scroll
                        objectName: "lane-" + lane.section
                        anchors.fill: parent
                        anchors.margins: 10
                        anchors.topMargin: 46
                        contentWidth: width
                        contentHeight: Math.max(height, cards.count * 58 + 4)
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        interactive: !root.dragging
                        ScrollBar.vertical: ScrollBar {}
                        Text {
                            visible: cards.count === 0
                            anchors.centerIn: parent
                            text: "Drop widgets here"
                            color: Theme.subtle
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
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
                                radius: 8
                                color: handle.containsMouse ? Theme.highlightMed : Theme.overlay
                                opacity: root.dragId === modelData ? 0.3 : BarLayout.isEnabled(modelData) ? 1 : 0.55
                                border.color: handle.activeFocus ? Theme.iris : "transparent"
                                MouseArea {
                                    id: handle
                                    objectName: "drag-" + card.modelData
                                    anchors.fill: parent
                                    anchors.rightMargin: 54
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
                                    Text {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 4
                                        text: "⠿  " + BarLayout.entry(card.modelData).label
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                    }
                                }
                                ControlSwitch {
                                    objectName: "toggle-" + card.modelData
                                    anchors.right: parent.right
                                    anchors.rightMargin: 8
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
                            radius: 1
                            color: Theme.iris
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
        radius: 8
        color: Theme.iris
        Text {
            anchors.centerIn: parent
            text: root.dragId ? BarLayout.entry(root.dragId).label : ""
            color: Theme.bg
            font.family: Theme.fontFamily
            font.pixelSize: 13
        }
    }
}
