import QtQuick
import qs.config
import qs.kits.default as Default

Default.Kit {
    fontFamily: Qt.fontFamilies().includes("Segoe UI") ? "Segoe UI" : "sans-serif"
    controlFill: state => {
        if (state.variant === "destructive")
            return state.fill;
        if (state.variant === "ghost" && !state.selected && !(state.enabled && (state.hovered || state.down)))
            return "transparent";
        const amount = state.enabled && state.down ? 0.28 : state.selected ? 0.18 : state.enabled && state.hovered ? 0.1 : 0;
        return Qt.tint(Design.surfaceRaised, Qt.rgba(state.accent.r, state.accent.g, state.accent.b, amount));
    }
    tokens: ({
            radiusSmall: 2,
            radiusControl: 3,
            radiusCard: 6,
            sliderTrack: 3
        })
    surface: Component {
        BevelSurface {
            gloss: lightSurface ? 0.025 : 0.06
            foreground: Design.text
        }
    }
    controlSurface: Component {
        ControlSurface {}
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
    barSurface: Component {
        GlassSurface {
            glassOpacity: 0.7
            horizontal: Theme.verticalBar
        }
    }
    menuSurface: Component {
        GlassSurface {
            frameInset: 6
        }
    }
    dropdownSurface: Component {
        DropdownSurface {}
    }
    widgetIndicator: Component {
        WidgetIndicator {}
    }
}
