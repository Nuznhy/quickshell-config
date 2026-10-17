import QtQuick
import qs.kits.default as Default

Default.Kit {
    tokens: ({
            radiusSmall: 6,
            radiusControl: 16,
            radiusCard: 20,
            durationFast: 160,
            durationNormal: 200
        })
    controlSurface: Component {
        ControlSurface {}
    }
}
