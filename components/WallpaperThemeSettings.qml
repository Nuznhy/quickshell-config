import QtQuick
import QtQuick.Layouts
import "ui" as UI
import "../config"
import "../services"

UI.ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: Design.space12
    readonly property var monitors: {
        const names = Theme.connectedScreens.map(s => s.name);
        if (Theme.wallpaperColorMonitor && !names.includes(Theme.wallpaperColorMonitor)) names.push(Theme.wallpaperColorMonitor);
        return names;
    }
    component Label: UI.Text {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        color: Design.textSecondary
        role: "label"
    }
    UI.Text { text: "Theme from wallpaper"; role: "section"; color: Design.text }
    Label { text: "Choose a monitor, extraction method, or variant to generate and apply colors automatically." }
    UI.GridLayout {
        Layout.fillWidth: true
        columns: width >= 560 ? 3 : 1
        columnSpacing: Design.space12
        rowSpacing: Design.space8
        UI.ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Label { text: "Source monitor" }
            UI.ComboBox {
                objectName: "wallpaper-color-monitor"
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                model: root.monitors
                currentIndex: root.monitors.indexOf(Theme.wallpaperColorMonitor)
                displayText: currentIndex >= 0 ? currentText : "Choose monitor"
                enabled: Theme.ready && root.monitors.length > 0
                Accessible.name: "Wallpaper theme source monitor"
                onActivated: index => WallpaperTheme.setOption("monitor", root.monitors[index])
            }
        }
        UI.ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Label { text: "Extraction" }
            UI.ComboBox {
                objectName: "wallpaper-color-method"
                Layout.fillWidth: true
                model: ["Dominant", "Vibrant", "Average", "Muted", "Dark", "Light", "Balanced"]
                currentIndex: ["dominant", "vibrant", "average", "muted", "dark", "light", "balanced"].indexOf(Theme.wallpaperColorMethod)
                enabled: Theme.ready
                Accessible.name: "Wallpaper color extraction"
                onActivated: index => WallpaperTheme.setOption("method", ["dominant", "vibrant", "average", "muted", "dark", "light", "balanced"][index])
            }
        }
        UI.ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Label { text: "Color variant" }
            UI.ComboBox {
                objectName: "wallpaper-color-variant"
                Layout.fillWidth: true
                model: ["Neutral", "Tonal", "Vivid"]
                currentIndex: ["neutral", "tonal", "vivid"].indexOf(Theme.wallpaperColorVariant)
                enabled: Theme.ready
                Accessible.name: "Wallpaper theme color variant"
                onActivated: index => WallpaperTheme.setOption("variant", ["neutral", "tonal", "vivid"][index])
            }
        }
    }
    Label {
        text: ({dominant: "Dominant favors common colors.", vibrant: "Vibrant favors saturated colors with meaningful coverage.", average: "Average blends the image’s colors.", muted: "Muted favors less saturated colors.", dark: "Dark favors darker colors.", light: "Light favors lighter colors.", balanced: "Balanced blends distinct colors with equal weight."})[Theme.wallpaperColorMethod]
            + " " + ({neutral: "Neutral keeps surfaces mostly gray.", tonal: "Tonal gently tints surfaces.", vivid: "Vivid uses richer accents and surfaces."})[Theme.wallpaperColorVariant]
    }
    UI.RowLayout {
        Layout.fillWidth: true
        Label { text: "Follow wallpaper changes"; role: "body"; color: Design.text }
        ControlSwitch {
            objectName: "wallpaper-color-auto"
            value: Theme.wallpaperColorAuto
            enabled: Theme.ready
            Accessible.name: "Automatically update wallpaper colors"
            onChangeRequested: value => WallpaperTheme.setOption("auto", value)
        }
    }
    UI.RowLayout {
        Layout.fillWidth: true
        Label { text: "Vivid colors for Neovim"; role: "body"; color: Design.text }
        ControlSwitch {
            objectName: "wallpaper-nvim-vivid"
            value: Theme.wallpaperNvimVivid
            enabled: Theme.ready
            Accessible.name: "Use vivid wallpaper colors for Neovim"
            onChangeRequested: value => WallpaperTheme.setOption("nvimVivid", value)
        }
    }
    Label { text: "Uses the vivid variant only for Neovim when the Wallpaper theme and Neovim application sync are enabled." }
    Label {
        visible: WallpaperTheme.busy
        text: "Generating colors…"
    }
    Label {
        visible: WallpaperTheme.errorMessage.length > 0
        text: WallpaperTheme.errorMessage
        color: Design.danger
    }
    UI.GridLayout {
        Layout.fillWidth: true
        columns: width >= 400 ? 2 : 1
        rowSpacing: Design.space8
        columnSpacing: Design.space12
        visible: WallpaperTheme.preview !== null
        Repeater {
            model: ["dark", "light"]
            UI.Pane {
                id: sample
                required property string modelData
                readonly property var colors: WallpaperTheme.preview?.[modelData] || Theme.palette
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                padding: Design.space12
                background: UI.Card { color: sample.colors.bg; border.color: sample.colors.highlightMed }
                contentItem: UI.ColumnLayout {
                    UI.Text { text: sample.modelData === "dark" ? "Dark preview" : "Light preview"; color: sample.colors.text; role: "body" }
                    UI.Text { text: "Readable text and accents"; color: sample.colors.subtle; role: "caption" }
                    PaletteSwatches { colors: sample.colors; swatchWidth: 20; swatchHeight: 12 }
                }
            }
        }
    }
}
