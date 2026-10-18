import QtQuick
import qs.config

BevelSurface {
    gloss: 0
    border.color: surface.border.color === Design.border ? Design.accent : surface.border.color
}
