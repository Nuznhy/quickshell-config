import QtQuick

// The Loader supplies the stable surface host as `surface`.
Rectangle {
    readonly property var surface: parent.surface
    color: surface.color
    radius: surface.radius
    topLeftRadius: surface.topLeftRadius
    topRightRadius: surface.topRightRadius
    bottomLeftRadius: surface.bottomLeftRadius
    bottomRightRadius: surface.bottomRightRadius
    border.width: surface.border.width
    border.color: surface.border.color
}
