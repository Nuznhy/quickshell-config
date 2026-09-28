import QtQuick
import "../config"

Item {
    id: root
    property color color: Theme.text
    property int iconSize: Theme.fontSize
    implicitWidth: iconSize
    implicitHeight: iconSize
    Image {
        id: customImage
        anchors.fill: parent
        source: Theme.settingsIconSource
        sourceSize: Qt.size(root.iconSize * 2, root.iconSize * 2)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
    }
    Text {
        anchors.centerIn: parent
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        fontSizeMode: Text.Fit
        minimumPixelSize: 8
        visible: customImage.status !== Image.Ready
        text: Theme.settingsIcon
        font.family: Theme.fontFamily
        font.pixelSize: root.iconSize
        color: root.color
    }
}
