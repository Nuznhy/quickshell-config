import QtQuick
import qs.kits.default as DefaultKitScripts

QtObject {
    property string fontFamily: ""
    readonly property var baseTokens: DefaultKitScripts.Tokens.defaults()
    property var tokens: ({})
    // Partial semantic palettes; mode-specific roles override shared roles.
    property var palette: ({})
    property var palettes: ({})
    // Optional state-dependent fill; shared controls also use it for text contrast.
    property var controlFill: null
    property Component surface: Component {
        Surface {}
    }
    property Component controlSurface: surface
    property Component cardSurface: surface
    property Component textFieldSurface: Component {
        TextFieldSurface {}
    }
    property Component choiceIndicator: Component {
        ChoiceIndicator {}
    }
    property Component switchIndicator: Component {
        SwitchIndicator {}
    }
    property Component sliderTrack: Component {
        SliderTrack {}
    }
    property Component sliderHandle: surface
    property Component barSurface: surface
    property Component menuSurface: surface
    property Component dropdownSurface: Component {
        DropdownSurface {}
    }
    property Component widgetIndicator: Component {
        WidgetIndicator {}
    }
}
