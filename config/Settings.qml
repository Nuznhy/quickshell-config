pragma Singleton
import QtQuick

QtObject {
    readonly property int barHeight: Math.max(42, Theme.fontSize + 22)
    readonly property int widgetSpacing: 12
    readonly property int leftPadding: 34
    readonly property int rightPadding: 40
    // Empty follows the active keyboard; set a device name to pin the widget.
    readonly property string keyboardName: ""
    readonly property int statsInterval: 2000
    readonly property int audioInterval: 500
    readonly property int keyboardInterval: 2000
    readonly property int workspaceInterval: 500
    readonly property var volumeControlCommand: ["pavucontrol"]
}
