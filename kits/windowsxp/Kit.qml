import QtQuick
import qs.config
import qs.kits.default as Default
import qs.kits.windowsxp as XP

Default.Kit {
    icons: XP.IconAssets.sources()
    fontFamily: Qt.fontFamilies().includes("Tahoma") ? "Tahoma" : Qt.fontFamilies().includes("DejaVu Sans") ? "DejaVu Sans" : "sans-serif"
    barPalette: ({
            background: Design.accent,
            text: XP.Colors.foreground(Design.accent),
            textSecondary: XP.Colors.foreground(Design.accent),
            textMuted: XP.Colors.legible(Design.textMuted, Design.accent),
            accent: XP.Colors.legible(Design.warning, Design.accent),
            danger: XP.Colors.legible(Design.danger, Design.accent),
            border: XP.Colors.shade(Design.accent, 0.3)
        })
    controlFill: state => {
        const interacting = state.enabled && (state.hovered || state.down);
        if (state.controlKind === "menuItem")
            return state.selected || interacting ? state.accent : state.variant === "ghost" ? "transparent" : Design.surface;
        if (state.controlKind === "select")
            return Design.surface;
        if (state.variant === "destructive")
            return state.fill;
        if (state.variant === "ghost" && !state.selected && !interacting)
            return "transparent";
        return state.enabled && state.down ? XP.Colors.shade(Design.surfaceRaised, -0.06) : Design.surfaceRaised;
    }
    tokens: ({
            radiusSmall: 2,
            radiusControl: 3,
            radiusCard: 4,
            sliderTrack: 4
        })
    surface: Component {
        BevelSurface {}
    }
    controlSurface: Component {
        ControlSurface {}
    }
    cardSurface: Component {
        BevelSurface {
            gloss: 0
        }
    }
    textFieldSurface: Component {
        TextFieldSurface {}
    }
    choiceIndicator: Component {
        ChoiceIndicator {}
    }
    switchIndicator: Component {
        SwitchIndicator {}
    }
    sliderTrack: Component {
        SliderTrack {}
    }
    sliderHandle: Component {
        SliderHandle {}
    }
    scrollBarTrack: Component {
        ScrollBarTrack {}
    }
    scrollBarThumb: Component {
        ScrollBarThumb {}
    }
    barSurface: Component {
        BarSurface {}
    }
    menuSurface: Component {
        MenuSurface {}
    }
    dropdownSurface: Component {
        DropdownSurface {}
    }
    widgetIndicator: Component {
        WidgetIndicator {}
    }
}
