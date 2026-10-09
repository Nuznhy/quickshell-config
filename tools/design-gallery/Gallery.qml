import QtQuick
import QtQuick.Controls as C
import QtQuick.Layouts
import "../../components/ui" as UI
import "../../config"
import "../../config/Palettes.js" as Palettes

UI.ScrollView {
    id: root
    property string preset: "rose-pine"
    property string mode: "dark"
    property alias content: body
    clip: true
    contentWidth: availableWidth
    padding: Design.windowPadding
    C.ScrollBar.horizontal.policy: C.ScrollBar.AlwaysOff
    Binding {
        target: Design
        property: "previewPalette"
        value: Palettes.palette(root.preset, root.mode)
        restoreMode: Binding.RestoreBindingOrValue
    }
    background: Rectangle { color: Design.background }

    UI.ColumnLayout {
        id: body
        width: root.availableWidth
        spacing: Design.sectionGap
        UI.Text { text: "Design system"; role: "page" }
        UI.HelperText { text: "Local preview • no preferences are saved. Tab through controls; hover, press, and select to inspect their states."; Layout.fillWidth: true }
        UI.RowLayout {
            Layout.fillWidth: true
            UI.ComboBox {
                objectName: "gallery-palette"
                model: Palettes.presets
                textRole: "name"
                valueRole: "id"
                currentIndex: Palettes.presets.findIndex(p => p.id === root.preset)
                onActivated: root.preset = currentValue
                Accessible.name: "Preview palette"
            }
            UI.SegmentedControl {
                model: ["Dark", "Light"]
                currentIndex: root.mode === "dark" ? 0 : 1
                onSelected: index => root.mode = index === 0 ? "dark" : "light"
            }
        }
        UI.Divider { Layout.fillWidth: true }
        UI.Text { text: "Typography"; role: "panel" }
        Flow {
            Layout.fillWidth: true
            spacing: Design.space16
            Repeater {
                model: ["page", "panel", "section", "body", "label", "caption"]
                UI.Text {
                    required property string modelData
                    role: modelData
                    text: modelData + " · " + Design.textSize(modelData)
                }
            }
        }
        UI.Text { text: "Buttons"; role: "panel" }
        Repeater {
            model: ["neutral", "primary", "ghost", "destructive"]
            Flow {
                required property string modelData
                Layout.fillWidth: true
                spacing: Design.space8
                UI.Button { text: parent.modelData; variant: parent.modelData }
                UI.Button { text: "Compact"; size: "compact"; variant: parent.modelData }
                UI.Button { text: "Selected"; checked: true; variant: parent.modelData }
                UI.Button { text: "Disabled"; enabled: false; variant: parent.modelData }
                UI.Button { text: "Working…"; busy: true; variant: parent.modelData }
                UI.Button { text: "Capsule"; capsule: true; variant: parent.modelData }
            }
        }
        UI.RowLayout {
            UI.IconButton { text: "󰒓"; Accessible.name: "Settings" }
            UI.IconButton { text: "×"; variant: "ghost"; Accessible.name: "Close" }
            UI.IconButton { text: "󰂚"; enabled: false; Accessible.name: "Notifications unavailable" }
        }
        UI.Text { text: "Inputs and selection"; role: "panel" }
        UI.GridLayout {
            Layout.fillWidth: true
            columns: root.width < 720 ? 1 : 2
            columnSpacing: Design.space16
            rowSpacing: Design.space8
            UI.ColumnLayout {
                Layout.fillWidth: true
                UI.FieldLabel { text: "Name" }
                UI.TextField { Layout.fillWidth: true; placeholderText: "Enter a value…"; Accessible.name: "Name" }
                UI.HelperText { text: "Helper text explains the field." }
            }
            UI.ColumnLayout {
                Layout.fillWidth: true
                UI.FieldLabel { text: "Invalid value" }
                UI.TextField { Layout.fillWidth: true; text: "Not a valid color"; invalid: true; Accessible.name: "Invalid color" }
                UI.HelperText { text: "Enter a six-digit hex color."; invalid: true }
            }
            UI.TextField { Layout.fillWidth: true; text: "Password"; echoMode: TextInput.Password; Accessible.name: "Password" }
            UI.TextField { Layout.fillWidth: true; text: "Read-only, selectable text"; readOnly: true; Accessible.name: "Read-only value" }
            UI.TextField { Layout.fillWidth: true; placeholderText: "Disabled"; enabled: false; Accessible.name: "Disabled input" }
            UI.ComboBox { Layout.fillWidth: true; model: ["First choice", "A very long selection that should elide in a narrow field", "Third choice"]; Accessible.name: "Selection" }
        }
        Flow {
            Layout.fillWidth: true
            spacing: Design.space16
            UI.CheckBox { text: "Checkbox" }
            UI.CheckBox { text: "Checked"; checked: true }
            UI.CheckBox { text: "Disabled"; checked: true; enabled: false }
            Row {
                spacing: Design.space8
                UI.RadioButton { text: "First"; checked: true }
                UI.RadioButton { text: "Second" }
            }
            UI.RadioButton { text: "Disabled"; enabled: false }
        }
        UI.SegmentedControl {
            Layout.fillWidth: true
            model: ["Automatic", "Light", "Dark"]
            currentIndex: 0
            onSelected: index => currentIndex = index
        }
        UI.Text { text: "Toggles and sliders"; role: "panel" }
        UI.RowLayout {
            spacing: Design.space16
            UI.Switch { Accessible.name: "Off switch" }
            UI.Switch { checked: true; Accessible.name: "On switch" }
            UI.Switch { checked: true; enabled: false; Accessible.name: "Disabled switch" }
            UI.Switch { busy: true; Accessible.name: "Busy switch" }
            UI.ToggleTile { text: "Night shift"; iconGlyph: "󰖔"; checkable: true }
            UI.ToggleTile { text: "Selected"; iconGlyph: "󰂚"; checked: true; checkable: true }
        }
        UI.Slider { Layout.fillWidth: true; value: 0.4; Accessible.name: "Level" }
        UI.Slider { Layout.fillWidth: true; value: 0.65; enabled: false; Accessible.name: "Unavailable level" }
        UI.Text { text: "Surfaces and long content"; role: "panel" }
        UI.Pane {
            Layout.fillWidth: true
            contentItem: UI.ColumnLayout {
                spacing: Design.space8
                UI.Text { text: "Card heading"; role: "section" }
                UI.Text { text: "Body text wraps inside a shared padded card. Resize this window to inspect spacing and line height."; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                UI.Capsule {
                    implicitWidth: badge.implicitWidth + Design.space24
                    implicitHeight: Design.compactHeight
                    UI.Text { id: badge; anchors.centerIn: parent; text: "Capsule"; role: "label"; color: parent.foreground }
                }
            }
        }
        UI.MenuSurface {
            Layout.fillWidth: true
            implicitHeight: menuItems.implicitHeight + Design.space16
            UI.ColumnLayout {
                id: menuItems
                anchors.fill: parent
                anchors.margins: Design.space8
                UI.MenuItem { Layout.fillWidth: true; text: "Menu option" }
                UI.MenuItem { Layout.fillWidth: true; text: "Selected menu option"; checked: true }
                UI.MenuItem { Layout.fillWidth: true; text: "Unavailable option"; enabled: false }
            }
        }
        UI.Button {
            text: "Open popup"
            onClicked: samplePopup.open()
            UI.Popup {
                id: samplePopup
                y: parent.height + Design.space4
                width: 220
                contentItem: UI.MenuItem { text: "Select to dismiss"; onClicked: samplePopup.close() }
            }
        }
    }
}
