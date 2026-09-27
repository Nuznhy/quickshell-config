pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "Palettes.js" as Palettes

Singleton {
    id: root

    readonly property var presets: Palettes.presets
    property string preset: "rose-pine"
    property string mode: "dark"
    property real barOpacity: 1
    property int barTopMargin: 0
    property int barSideMargin: 0
    property int barRadius: 0
    readonly property int maximumBarRadius: Math.floor(Settings.barHeight / 2)
    property bool ready: false
    property string errorMessage: ""
    readonly property bool isDark: mode === "dark"
    readonly property var palette: Palettes.palette(preset, mode)

    function preview(id) {
        return Palettes.palette(id, mode);
    }

    function selectPreset(id) {
        if (!ready || !Palettes.hasPreset(id)) return;
        preset = id;
        save();
    }

    function selectMode(value) {
        if (!ready || (value !== "dark" && value !== "light")) return;
        mode = value;
        save();
    }

    function save() {
        appearanceSaveTimer.stop();
        errorMessage = "";
        stateFile.setText(JSON.stringify({ preset: preset, mode: mode, barOpacity: barOpacity,
            barTopMargin: barTopMargin, barSideMargin: barSideMargin, barRadius: barRadius }, null, 2) + "\n");
    }

    function setBarOpacity(value) {
        if (!ready || !Number.isFinite(value)) return;
        barOpacity = Math.round(Math.max(0.2, Math.min(1, value)) * 100) / 100;
        appearanceSaveTimer.restart();
    }

    function geometryValue(value, maximum) {
        return typeof value === "number" && Number.isFinite(value)
            ? Math.round(Math.max(0, Math.min(maximum, value))) : 0;
    }

    function setBarGeometry(name, value) {
        if (!ready || !Number.isFinite(value)) return;
        if (name === "barTopMargin") barTopMargin = geometryValue(value, 40);
        else if (name === "barSideMargin") barSideMargin = geometryValue(value, 40);
        else if (name === "barRadius") barRadius = geometryValue(value, maximumBarRadius);
        else return;
        appearanceSaveTimer.restart();
    }

    Timer {
        id: appearanceSaveTimer
        interval: 250
        onTriggered: root.save()
    }

    FileView {
        id: stateFile
        path: Quickshell.statePath("theme.json")
        printErrors: false
        onLoaded: {
            try {
                var saved = JSON.parse(text());
                if (!saved || typeof saved !== "object") throw new Error("Invalid theme settings");
                root.preset = Palettes.hasPreset(saved.preset) ? saved.preset : "rose-pine";
                root.mode = saved.mode === "light" ? "light" : "dark";
                root.barOpacity = typeof saved.barOpacity === "number" && Number.isFinite(saved.barOpacity)
                    ? Math.max(0.2, Math.min(1, saved.barOpacity)) : 1;
                root.barTopMargin = root.geometryValue(saved.barTopMargin, 40);
                root.barSideMargin = root.geometryValue(saved.barSideMargin, 40);
                root.barRadius = root.geometryValue(saved.barRadius, root.maximumBarRadius);
            } catch (error) {
                root.errorMessage = "Could not read saved theme. Choose a theme to reset it.";
            }
            root.ready = true;
        }
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                root.errorMessage = "Could not read saved theme settings.";
            root.ready = true;
        }
        onSaveFailed: error => {
            root.errorMessage = "Theme applied, but could not save it.";
            console.warn(root.errorMessage, FileViewError.toString(error));
        }
    }

    readonly property color bg: palette.bg
    readonly property color surface: palette.surface
    readonly property color overlay: palette.overlay
    readonly property color muted: palette.muted
    readonly property color subtle: palette.subtle
    readonly property color text: palette.text
    readonly property color love: palette.love
    readonly property color gold: palette.gold
    readonly property color rose: palette.rose
    readonly property color pine: palette.pine
    readonly property color foam: palette.foam
    readonly property color iris: palette.iris
    readonly property color highlightLow: palette.highlightLow
    readonly property color highlightMed: palette.highlightMed
    readonly property color highlightHigh: palette.highlightHigh

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 20
}
