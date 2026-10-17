import QtQuick

Surface {
    Rectangle {
        y: surface.control.horizontal ? 0 : surface.control.visualPosition * parent.height
        width: surface.control.horizontal ? surface.control.position * parent.width : parent.width
        height: surface.control.horizontal ? parent.height : surface.control.position * parent.height
        radius: parent.radius
        color: surface.control.accentColor
    }
}
