import QtQuick
import QtQuick.Layouts
import "../../config"

Item {
    implicitWidth: Settings.widgetSpacing
    Layout.minimumWidth: Settings.widgetSpacing
    Layout.preferredWidth: Settings.widgetSpacing
    Layout.maximumWidth: Settings.widgetSpacing
    implicitHeight: Theme.verticalBar ? Settings.widgetSpacing : 0
    Layout.minimumHeight: implicitHeight
    Layout.preferredHeight: implicitHeight
    Layout.maximumHeight: implicitHeight
}
