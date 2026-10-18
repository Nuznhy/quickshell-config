import QtQuick
import qs.config
import qs.kits.default as Default
import qs.kits.windowsxp as XP

Default.Surface {
    id: root
    readonly property color base: Design.barColor("background")
    function shade(amount) {
        const roles = ["text", "textSecondary", "textMuted", "accent", "danger"];
        for (let attempt = 0; attempt < 10; ++attempt) {
            const value = XP.Colors.shade(base, amount);
            if (roles.every(role => Design.contrast(Design.barColor(role), value) >= 4.5))
                return value;
            amount *= 0.5;
        }
        return base;
    }
    gradient: Gradient {
        orientation: Theme.verticalBar ? Gradient.Horizontal : Gradient.Vertical
        GradientStop {
            position: 0
            color: root.shade(-0.18)
        }
        GradientStop {
            position: 0.08
            color: root.shade(0.2)
        }
        GradientStop {
            position: 0.22
            color: root.base
        }
        GradientStop {
            position: 0.88
            color: root.shade(-0.06)
        }
        GradientStop {
            position: 1
            color: root.shade(-0.25)
        }
    }
}
