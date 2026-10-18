import QtQuick
import qs.config
import qs.kits.windowsxp as XP

BevelSurface {
    color: Design.background
    inset: true
    gloss: 0.04
    border.color: XP.Colors.shade(color, -0.18)
}
