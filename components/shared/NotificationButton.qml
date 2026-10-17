import QtQuick
import qs.components.ui as UI

// Compatibility adapter for existing feature components.
UI.Button {
    property bool accent: false
    variant: accent ? "primary" : "neutral"
}
