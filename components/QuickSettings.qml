import QtQuick
import "ui" as UI
import QtQuick.Controls
import QtQuick.Layouts
import "../config"
import "../services"

UI.ColumnLayout {
    id: root
    property bool active: false
    signal settingsRequested
    spacing: Design.space12
    onActiveChanged: { QuickControls.openPanels += active ? 1 : -1; }
    Component.onDestruction: { if (active) QuickControls.openPanels--; }

    UI.RowLayout {
        Layout.fillWidth: true
        spacing: Design.space12
        UI.ColumnLayout {
            Layout.fillWidth: true
            spacing: Design.space2
            UI.Text {
                Layout.fillWidth: true
                text: QuickControls.hostname || "System"
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: Design.text
                font.family: Design.fontFamily
                role: "section"
                font.bold: true
            }
            UI.Text {
                Layout.fillWidth: true
                text: [QuickControls.osName, QuickControls.uptime].filter(Boolean).join(" · ")
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: Design.textSecondary
                font.family: Design.fontFamily
                role: "caption"
            }
        }
        UI.IconButton {
            objectName: "full-settings"
            text: "󰒓"
            implicitWidth: 34
            implicitHeight: Design.controlHeight
            Accessible.name: "Open full settings"
            onClicked: root.settingsRequested()
        }
    }

    UI.RowLayout {
        Layout.fillWidth: true
        spacing: Design.space8
        QuickToggle {
            objectName: "night-shift-toggle"
            iconGlyph: "󰖔"
            text: "Night shift"
            checked: QuickControls.nightEnabled
            enabled: QuickControls.available && QuickControls.ready
            onClicked: QuickControls.toggleNightShift()
        }
        QuickToggle {
            objectName: "theme-toggle"
            iconGlyph: Theme.isDark ? "󰖔" : "󰖙"
            text: Theme.isDark ? "Dark" : "Light"
            checked: Theme.isDark
            enabled: Theme.ready
            onClicked: Theme.selectMode(Theme.isDark ? "light" : "dark")
        }
        QuickToggle {
            objectName: "dnd-toggle"
            iconGlyph: Notifications.doNotDisturb ? "󰂛" : "󰂚"
            text: "DND"
            checked: Notifications.doNotDisturb
            onClicked: Notifications.setDoNotDisturb(!Notifications.doNotDisturb)
        }
    }
    AppearanceSlider {
        objectName: "night-shift-strength"
        Layout.fillWidth: true
        visible: QuickControls.nightEnabled
        enabled: QuickControls.available && QuickControls.ready
        label: "Color temperature"
        minimum: 1500
        maximum: 6500
        stepSize: 50
        suffix: " K"
        value: QuickControls.temperature
        onValueEdited: value => QuickControls.setStrength((6500 - value) / 50)
    }
    UI.Text {
        Layout.fillWidth: true
        visible: text.length > 0
        text: [QuickControls.errorMessage, QuickControls.settingsError].filter(Boolean).join("\n")
        textFormat: Text.PlainText
        wrapMode: Text.WordWrap
        color: Design.textSecondary
        font.family: Design.fontFamily
        role: "caption"
    }

    SystemInfoPanel {
        Layout.fillWidth: true
        active: root.active
    }

    component QuickToggle: UI.ToggleTile {
        Layout.fillWidth: true
        Layout.preferredWidth: 1
    }
}
