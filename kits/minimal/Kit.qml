import QtQuick
import qs.kits.default as Default

Default.Kit {
    tokens: ({radiusSmall: 0, radiusControl: 2, radiusCard: 2, durationFast: 80, durationNormal: 120})
    controlSurface: Component { ControlSurface {} }
}
