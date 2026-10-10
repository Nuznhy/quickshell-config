pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config"
import "../config/WallpaperColors.js" as WallpaperColors

Singleton {
    id: root
    property var preview: null
    property string previewKey: ""
    property string errorMessage: ""
    property int revision: 0
    property bool pendingAutomatic: false
    property bool pending: false
    property var job: ({})
    property var response: null
    readonly property bool busy: worker.running || debounce.running || pending
    readonly property string monitor: Theme.wallpaperColorMonitor
    readonly property bool connected: Theme.connectedScreens.some(s => s.name === monitor)
    readonly property string source: connected ? Theme.wallpaperFor(monitor) : ""
    readonly property string key: JSON.stringify([monitor, source, Theme.mode, Theme.wallpaperColorMethod, Theme.wallpaperColorVariant])
    readonly property bool automatic: Theme.wallpaperColorAuto && Theme.preset === "wallpaper"
    readonly property string helper: decodeURIComponent(Qt.resolvedUrl("../scripts/wallpaper-palette.py").toString().replace(/^file:\/\//, ""))

    function initialize() {
        if (!Theme.ready) return;
        if (!monitor) {
            const screen = Theme.connectedScreens.find(s => Theme.wallpaperFor(s.name));
            if (screen) Theme.setWallpaperColorOption("monitor", screen.name);
        }
        if (automatic || (Theme.preset === "wallpaper" && Theme.wallpaperNvimVivid && !Theme.generatedVividPalette)) generate(true);
    }
    function setOption(name, value) {
        Theme.setWallpaperColorOption(name, value);
        if (name === "nvimVivid") {
            if (value && Theme.preset === "wallpaper" && !Theme.generatedVividPalette) generate(false);
        } else if (name !== "auto" || value) generate(false);
    }
    function cancel() {
        revision++;
        pending = false;
        debounce.stop();
    }
    function generate(followChange) {
        if (!Theme.ready) return;
        revision++;
        pendingAutomatic = followChange === true;
        errorMessage = "";
        pending = true;
        debounce.restart();
    }
    function pump() {
        if (!pending || worker.running || debounce.running) return;
        pending = false;
        if (!connected || !source) {
            errorMessage = !connected ? "Connect the source monitor or choose another monitor." : "Choose a wallpaper for this monitor first.";
            return;
        }
        job = {key: key, source: source, method: Theme.wallpaperColorMethod, variant: Theme.wallpaperColorVariant, automatic: pendingAutomatic, revision: revision};
        response = null;
        worker.running = true;
    }
    onKeyChanged: {
        preview = null;
        previewKey = "";
        errorMessage = "";
        if (Theme.ready && automatic) generate(true);
    }
    onAutomaticChanged: {
        if (automatic && Theme.ready && previewKey !== key) generate(true);
        else if (!automatic && (pending ? pendingAutomatic : worker.running && job.automatic)) cancel();
    }
    Component.onCompleted: initialize()
    Connections {
        target: Theme
        function onPresetChanged() {
            if (Theme.preset !== "wallpaper") root.cancel();
            else if (Theme.wallpaperNvimVivid && !Theme.generatedVividPalette) root.generate(false);
        }
        function onReadyChanged() { root.initialize(); }
        function onConnectedScreensChanged() { if (!root.monitor) root.initialize(); }
        function onWallpapersChanged() { if (!root.monitor) root.initialize(); }
        function onLightWallpapersChanged() { if (!root.monitor) root.initialize(); }
        function onDarkWallpapersChanged() { if (!root.monitor) root.initialize(); }
    }
    Timer { id: debounce; interval: 300; onTriggered: root.pump() }
    Process {
        id: worker
        command: ["python3", root.helper]
        stdinEnabled: true
        onStarted: {
            write(JSON.stringify(root.job));
            stdinEnabled = false;
        }
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.response = JSON.parse(text); }
                catch (error) { root.response = {error: "Could not read generated colors."}; }
            }
        }
        stderr: StdioCollector {}
        onExited: code => {
            stdinEnabled = true;
            if (root.job.revision === root.revision && root.job.key === root.key && !root.pending) {
                if (code === 0 && WallpaperColors.valid(root.response?.palettes)) {
                    root.preview = root.response.palettes;
                    root.previewKey = root.job.key;
                    root.errorMessage = "";
                    Theme.applyWallpaperPalette(root.preview, root.response.vividPalettes);
                } else root.errorMessage = root.response?.error || "Wallpaper theme generation failed.";
            }
            Qt.callLater(root.pump);
        }
    }
}
