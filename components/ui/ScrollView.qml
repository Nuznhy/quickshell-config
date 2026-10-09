import QtQuick.Controls as C
import "." as UI

C.ScrollView {
    id: root
    // Replacing a style's bars also replaces its viewport positioning bindings.
    C.ScrollBar.vertical: UI.ScrollBar {
        id: verticalBar
        parent: root
        x: root.mirrored ? 0 : root.width - width
        y: root.topPadding
        height: root.availableHeight
        active: horizontalBar.active
    }
    C.ScrollBar.horizontal: UI.ScrollBar {
        id: horizontalBar
        parent: root
        x: root.leftPadding
        y: root.height - height
        width: root.availableWidth
        active: verticalBar.active
    }
}
