.pragma library

var sections = ["start", "center", "end"];
var widgets = [
    { id: "workspaces", label: "Workspaces", section: "start", source: "widgets/WorkspaceBar.qml" },
    { id: "tray", label: "System tray", section: "start", source: "widgets/Tray.qml" },
    { id: "media", label: "Media", section: "start", source: "widgets/MediaWidget.qml" },
    { id: "clock", label: "Clock", section: "center", source: "widgets/Clock.qml" },
    { id: "cpu", label: "CPU", section: "end", source: "widgets/Cpu.qml" },
    { id: "memory", label: "Memory", section: "end", source: "widgets/Memory.qml" },
    { id: "monitoring", label: "PC monitoring", section: "end", source: "widgets/MonitoringWidget.qml", settings: true, disabledByDefault: true },
    { id: "network", label: "Network", section: "end", source: "../network/Network.qml" },
    { id: "bluetooth", label: "Bluetooth", section: "end", source: "widgets/BluetoothWidget.qml" },
    { id: "keyboard", label: "Keyboard", section: "end", source: "widgets/KeyboardLanguage.qml" },
    { id: "volume", label: "Volume", section: "end", source: "widgets/VolumeWidget.qml" },
    { id: "brightness", label: "Brightness", section: "end", source: "widgets/BrightnessWidget.qml" },
    { id: "display-mode", label: "Duplicate laptop screen", section: "end", source: "widgets/DisplayModeWidget.qml" },
    { id: "desktop-tv", label: "Desktop / TV switch", section: "end", source: "widgets/DesktopTvWidget.qml" },
    { id: "battery", label: "Battery", section: "end", source: "widgets/BatteryWidget.qml", disabledByDefault: true },
    { id: "notifications", label: "Notifications", section: "end", source: "widgets/NotificationWidget.qml" },
    { id: "theme-mode", label: "Light / dark mode", section: "end", source: "widgets/ThemeModeWidget.qml" },
    { id: "settings", label: "Settings", section: "end", source: "widgets/ThemeWidget.qml" },
    { id: "power", label: "Power", section: "end", source: "widgets/PowerWidget.qml" }
];

function widget(id) { return widgets.find(entry => entry.id === id); }
function defaults() {
    var result = { version: 1, sections: { start: [], center: [], end: [] }, disabled: [] };
    for (var entry of widgets) {
        result.sections[entry.section].push(entry.id);
        if (entry.disabledByDefault) result.disabled.push(entry.id);
    }
    return result;
}
function normalize(saved) {
    if (!saved || saved.version !== 1 || !saved.sections ||
            sections.some(section => !Array.isArray(saved.sections[section])))
        throw new Error("Invalid bar layout");
    var result = defaults();
    var seen = [];
    for (var section of sections) {
        result.sections[section] = saved.sections[section].filter(id => {
            if (!widget(id) || seen.includes(id)) return false;
            seen.push(id);
            return true;
        });
    }
    for (var entry of widgets) {
        if (!seen.includes(entry.id)) result.sections[entry.section].push(entry.id);
    }
    result.disabled = Array.isArray(saved.disabled)
        ? [...new Set(saved.disabled.filter(id => !!widget(id)))] : [];
    for (var entry of widgets) {
        if (entry.disabledByDefault && !seen.includes(entry.id) && !result.disabled.includes(entry.id))
            result.disabled.push(entry.id);
    }
    return result;
}
// Index is an insertion boundary in the destination's list BEFORE removal.
function move(state, id, destination, index) {
    if (!widget(id) || !sections.includes(destination) || !Number.isInteger(index)) return state;
    var next = normalize(state);
    index = Math.max(0, Math.min(index, next.sections[destination].length));
    var previous = next.sections[destination].indexOf(id);
    if (previous >= 0 && previous < index) --index;
    for (var section of sections)
        next.sections[section] = next.sections[section].filter(value => value !== id);
    next.sections[destination].splice(index, 0, id);
    return next;
}
function setEnabled(state, id, enabled) {
    if (!widget(id)) return state;
    var next = normalize(state);
    next.disabled = next.disabled.filter(value => value !== id);
    if (!enabled) next.disabled.push(id);
    return next;
}
