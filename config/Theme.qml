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
    property int wallpaperTransitionStyle: 0
    onModeChanged: {
        // Pick one of six effects, excluding the previous effect. Shared by screens.
        wallpaperTransitionStyle = (wallpaperTransitionStyle + 1 + Math.floor(Math.random() * 5)) % 6;
    }
    property real barOpacity: 1
    property int barTopMargin: 0
    property int barSideMargin: 0
    property int barRadius: 0
    property int fontSize: 20
    property string barPosition: "top"
    readonly property bool verticalBar: barPosition === "left" || barPosition === "right"
    readonly property int sideBarWidth: Math.max(64, Math.ceil(fontSize * 2.5) + 16)
    property var disabledBarScreens: []
    property var wallpapers: ({})
    property bool separateWallpapers: false
    property var lightWallpapers: ({})
    property var darkWallpapers: ({})
    property string wallpaperFolder: ""
    property string lockBackgroundMode: "theme"
    property string lockBackgroundColor: "#191724"
    property string lockBackgroundImage: ""
    readonly property var lockScreen: ({background: lockBackgroundMode, color: lockBackgroundColor, image: lockBackgroundImage})
    readonly property string defaultSettingsIcon: "󰒓"
    property string settingsIcon: defaultSettingsIcon
    property string settingsIconSource: ""
    readonly property var connectedScreens: Quickshell.screens
    readonly property var enabledBarScreens: {
        const names = connectedScreens.map(screen => screen.name);
        const enabled = names.filter(name => !disabledBarScreens.includes(name));
        // A monitor change must not leave the appearance controls inaccessible.
        return enabled.length ? enabled : names.slice(0, 1);
    }
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
            barTopMargin: barTopMargin, barSideMargin: barSideMargin, barRadius: barRadius,
            disabledBarScreens: disabledBarScreens, fontSize: fontSize, barPosition: barPosition,
            wallpapers: wallpapers, wallpaperFolder: wallpaperFolder,
            lockScreen: lockScreen,
            separateWallpapers: separateWallpapers, lightWallpapers: lightWallpapers, darkWallpapers: darkWallpapers,
            settingsIcon: settingsIcon, settingsIconSource: settingsIconSource }, null, 2) + "\n");
    }

    function wallpaperMode(variant) {
        return ["shared", "light", "dark"].includes(variant) ? variant : separateWallpapers ? mode : "shared";
    }

    function wallpaperFor(name, variant) {
        const target = wallpaperMode(variant);
        const choices = target === "light" ? lightWallpapers : target === "dark" ? darkWallpapers : wallpapers;
        if (Object.prototype.hasOwnProperty.call(choices, name)) return choices[name];
        return Object.prototype.hasOwnProperty.call(wallpapers, name) ? wallpapers[name] : "";
    }

    function setWallpaper(name, source, variant) {
        if (!ready || !name || typeof source !== "string" || (source !== "" && !source.startsWith("file:///"))) return;
        const target = wallpaperMode(variant);
        const next = Object.assign({}, target === "light" ? lightWallpapers : target === "dark" ? darkWallpapers : wallpapers);
        // An explicit empty per-mode value must not inherit the shared image.
        if (source || target !== "shared") next[name] = source;
        else delete next[name];
        if (target === "light") lightWallpapers = next;
        else if (target === "dark") darkWallpapers = next;
        else wallpapers = next;
        appearanceSaveTimer.restart();
    }

    function setSeparateWallpapers(value) {
        if (!ready || typeof value !== "boolean") return;
        separateWallpapers = value;
        appearanceSaveTimer.restart();
    }

    function restoreWallpapers(value) {
        const restored = {};
        if (value && typeof value === "object" && !Array.isArray(value)) {
            for (const name of Object.keys(value)) {
                const source = value[name];
                if (name.length > 0 && typeof source === "string" && (source === "" || source.startsWith("file:///"))) restored[name] = source;
            }
        }
        return restored;
    }

    function setLockBackground(kind, value) {
        if (!ready) return;
        if (kind === "mode" && ["theme", "color", "image"].includes(value)) lockBackgroundMode = value;
        else if (kind === "color" && typeof value === "string" && /^#[0-9a-fA-F]{6}$/.test(value)) lockBackgroundColor = value.toLowerCase();
        else if (kind === "image" && typeof value === "string" && (value === "" || value.startsWith("file:///"))) lockBackgroundImage = value;
        else return;
        appearanceSaveTimer.restart();
    }

    function setWallpaperFolder(source) {
        if (!ready || typeof source !== "string" || (source !== "" && !source.startsWith("file:///"))) return;
        wallpaperFolder = source;
        appearanceSaveTimer.restart();
    }

    function setSettingsIcon(glyph, source) {
        if (!ready || typeof glyph !== "string" || typeof source !== "string"
                || (source !== "" && !source.startsWith("file:///"))) return;
        settingsIcon = glyph.trim().slice(0, 16) || defaultSettingsIcon;
        settingsIconSource = source;
        appearanceSaveTimer.restart();
    }

    function setFontSize(value) {
        if (!ready || !Number.isFinite(value)) return;
        fontSize = Math.round(Math.max(12, Math.min(28, value)));
        appearanceSaveTimer.restart();
    }

    function setBarPosition(value) {
        if (!ready || !["top", "left", "bottom", "right"].includes(value)) return;
        barPosition = value;
        appearanceSaveTimer.restart();
    }

    function barEnabled(name) { return enabledBarScreens.includes(name); }

    function setBarEnabled(name, enabled) {
        if (!ready || !connectedScreens.some(screen => screen.name === name)) return;
        if (!enabled && barEnabled(name) && enabledBarScreens.length <= 1) return;
        // Preserve a temporary fallback bar when another display is switched off.
        let disabled = disabledBarScreens.filter(item => !enabledBarScreens.includes(item));
        disabled = disabled.filter(item => item !== name);
        if (!enabled) disabled.push(name);
        disabledBarScreens = disabled;
        appearanceSaveTimer.restart();
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
            if (root.ready) return;
            try {
                var saved = JSON.parse(text());
                if (!saved || typeof saved !== "object") throw new Error("Invalid theme settings");
                root.preset = Palettes.hasPreset(saved.preset) ? saved.preset : "rose-pine";
                root.mode = saved.mode === "light" ? "light" : "dark";
                root.fontSize = typeof saved.fontSize === "number" && Number.isFinite(saved.fontSize)
                    ? Math.round(Math.max(12, Math.min(28, saved.fontSize))) : 20;
                root.barPosition = ["top", "left", "bottom", "right"].includes(saved.barPosition) ? saved.barPosition : "top";
                root.barOpacity = typeof saved.barOpacity === "number" && Number.isFinite(saved.barOpacity)
                    ? Math.max(0.2, Math.min(1, saved.barOpacity)) : 1;
                root.barTopMargin = root.geometryValue(saved.barTopMargin, 40);
                root.barSideMargin = root.geometryValue(saved.barSideMargin, 40);
                root.barRadius = root.geometryValue(saved.barRadius, root.maximumBarRadius);
                root.disabledBarScreens = Array.isArray(saved.disabledBarScreens)
                    ? [...new Set(saved.disabledBarScreens.filter(name => typeof name === "string" && name.length > 0))] : [];
                root.wallpapers = root.restoreWallpapers(saved.wallpapers);
                root.lightWallpapers = root.restoreWallpapers(saved.lightWallpapers);
                root.darkWallpapers = root.restoreWallpapers(saved.darkWallpapers);
                root.separateWallpapers = saved.separateWallpapers === true;
                const lock = saved.lockScreen || {};
                root.lockBackgroundMode = ["theme", "color", "image"].includes(lock.background) ? lock.background : "theme";
                root.lockBackgroundColor = typeof lock.color === "string" && /^#[0-9a-fA-F]{6}$/.test(lock.color) ? lock.color : "#191724";
                root.lockBackgroundImage = typeof lock.image === "string" && lock.image.startsWith("file:///") ? lock.image : "";
                root.wallpaperFolder = typeof saved.wallpaperFolder === "string" && saved.wallpaperFolder.startsWith("file:///")
                    ? saved.wallpaperFolder : "";
                root.settingsIcon = typeof saved.settingsIcon === "string" && saved.settingsIcon.trim()
                    ? saved.settingsIcon.trim().slice(0, 16) : root.defaultSettingsIcon;
                root.settingsIconSource = typeof saved.settingsIconSource === "string" && saved.settingsIconSource.startsWith("file:///")
                    ? saved.settingsIconSource : "";
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
}
