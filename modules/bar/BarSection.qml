pragma ComponentBehavior: Bound
import QtQuick
import "../../components/ui" as UI
import QtQuick.Controls
import QtQuick.Layouts
import "../../config"

Flickable {
    id: root
    required property string section
    required property var barWindow
    property bool alignEnd: false
    property int generation: 0
    readonly property var positions: {
        generation;
        let result = [], length = 0, count = 0;
        for (let i = 0; i < widgets.count; ++i) {
            const slot = widgets.itemAt(i);
            if (slot && slot.occupied) {
                if (count++) length += Settings.widgetSpacing;
                result.push(length);
                length += Theme.verticalBar ? slot.widgetHeight : slot.widgetWidth;
            } else result.push(length);
        }
        return { offsets: result, length: length };
    }
    readonly property real naturalLength: positions.length
    readonly property real viewportLength: Theme.verticalBar ? height : width
    readonly property bool overflowing: naturalLength > viewportLength + 1
    contentWidth: Theme.verticalBar ? width : naturalLength
    contentHeight: Theme.verticalBar ? naturalLength : height
    flickableDirection: Theme.verticalBar ? Flickable.VerticalFlick : Flickable.HorizontalFlick
    interactive: overflowing
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    onMovementStarted: barWindow.closeAllPopups()
    function settleScroll() {
        if (Theme.verticalBar) { contentX = 0; contentY = alignEnd ? Math.max(0, contentHeight - height) : 0; }
        else { contentY = 0; contentX = alignEnd ? Math.max(0, contentWidth - width) : 0; }
    }
    onNaturalLengthChanged: Qt.callLater(settleScroll)
    onWidthChanged: Qt.callLater(settleScroll)
    onHeightChanged: Qt.callLater(settleScroll)
    ScrollBar.vertical: UI.ScrollBar { policy: Theme.verticalBar && root.overflowing ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff }
    ScrollBar.horizontal: UI.ScrollBar { policy: !Theme.verticalBar && root.overflowing ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff }

    Repeater {
        id: widgets
        model: BarLayout.ids(root.section)
        onItemAdded: root.generation++
        onItemRemoved: root.generation++
        delegate: Item {
            id: slot
            required property string modelData
            required property int index
            readonly property real widgetWidth: loader.item ? Math.max(0,
                loader.item.Layout.preferredWidth >= 0 ? loader.item.Layout.preferredWidth : loader.item.implicitWidth) : 0
            readonly property real widgetHeight: !Theme.verticalBar ? Settings.barHeight
                : modelData === "clock" ? Settings.barHeight + 12
                : loader.item ? Math.max(Settings.barHeight,
                    loader.item.Layout.preferredHeight >= 0 ? loader.item.Layout.preferredHeight : loader.item.implicitHeight) : 0
            readonly property bool occupied: loader.item !== null && loader.item.visible && widgetWidth > 0
            x: Theme.verticalBar ? 0 : (root.positions.offsets[index] || 0)
            y: Theme.verticalBar ? (root.positions.offsets[index] || 0) : 0
            width: Theme.verticalBar ? root.width : occupied ? widgetWidth : 0
            height: Theme.verticalBar ? (occupied ? widgetHeight : 0) : root.height
            // Do not bind parent visibility to item.visible: inherited visibility
            // would prevent conditionally hidden media from ever returning.
            Loader {
                id: loader
                active: BarLayout.isEnabled(slot.modelData)
                source: Qt.resolvedUrl(BarLayout.entry(slot.modelData).source)
                width: slot.widgetWidth
                height: slot.widgetHeight
                x: (slot.width - width) / 2
                y: Theme.verticalBar ? 0 : (slot.height - height) / 2
            }
        }
    }
}
