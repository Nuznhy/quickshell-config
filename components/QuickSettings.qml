import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../config"
import "../services"

ColumnLayout {
    id: root
    property bool active: false
    signal settingsRequested
    spacing: 12
    onActiveChanged: { QuickControls.openPanels += active ? 1 : -1; }
    Component.onDestruction: { if (active) QuickControls.openPanels--; }

    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            Text {
                Layout.fillWidth: true
                text: QuickControls.hostname || "System"
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
            }
            Text {
                Layout.fillWidth: true
                text: [QuickControls.osName, QuickControls.uptime].filter(Boolean).join(" · ")
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: Theme.subtle
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }
        NotificationButton {
            objectName: "full-settings"
            text: "󰒓"
            implicitWidth: 34
            implicitHeight: 34
            Accessible.name: "Open full settings"
            onClicked: root.settingsRequested()
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
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
    Text {
        Layout.fillWidth: true
        visible: text.length > 0
        text: [QuickControls.errorMessage, QuickControls.settingsError].filter(Boolean).join("\n")
        textFormat: Text.PlainText
        wrapMode: Text.WordWrap
        color: Theme.subtle
        font.family: Theme.fontFamily
        font.pixelSize: 10
    }

    SystemInfoPanel {
        Layout.fillWidth: true
        active: root.active
    }

    component QuickToggle: Button {
        id: control
        property string iconGlyph
        // A separate glyph property keeps Qt's Button icon group untouched.
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        implicitHeight: 65
        padding: 8
        hoverEnabled: true
        opacity: enabled ? 1 : 0.45
        Accessible.name: text
        Accessible.role: Accessible.CheckBox
        Accessible.checkable: true
        Accessible.checked: checked
        HoverHandler { cursorShape: Qt.PointingHandCursor }
        background: Rectangle {
            radius: 9
            color: control.checked ? Theme.iris : control.hovered ? Theme.highlightMed : Theme.overlay
            border.color: control.activeFocus ? Theme.text : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
        }
        contentItem: ColumnLayout {
            spacing: 5
            Text {
                Layout.fillWidth: true
                text: control.iconGlyph
                horizontalAlignment: Text.AlignHCenter
                color: control.checked ? Theme.bg : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 20
            }
            Text {
                Layout.fillWidth: true
                text: control.text
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                color: control.checked ? Theme.bg : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }
    }
}
