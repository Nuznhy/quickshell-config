import QtQuick
import "ui" as UI
import "../config"

Item {
    id: root
    property color color: Design.text
    property int iconSize: Theme.fontSize
    property string glyph: Theme.settingsIcon
    property url source: Theme.settingsIconSource
    implicitWidth: iconSize
    implicitHeight: iconSize
    Image {
        id: customImage
        anchors.fill: parent
        source: root.source
        sourceSize: Qt.size(root.iconSize * 2, root.iconSize * 2)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
    }
    UI.Icon {
        anchors.fill: parent
        visible: customImage.status !== Image.Ready
        text: root.glyph
        size: root.iconSize
        color: root.color
    }
}
