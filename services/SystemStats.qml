pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

Singleton {
    id: root
    property int cpuUsage: 0
    property int memUsage: 0
    property var metrics: []
    property var temperatureSources: []
    property var history: ({})
    property int panels: 0
    property string errorMessage: ""
    property string launchError: ""
    property bool completed: false
    readonly property bool detailed: (BarLayout.ready && BarLayout.isEnabled("monitoring")) || panels > 0
    readonly property string helper: decodeURIComponent(Qt.resolvedUrl("../scripts/monitoring.py").toString().replace(/^file:\/\//, ""))
    readonly property string launcher: decodeURIComponent(Qt.resolvedUrl("../scripts/monitoring-terminal.py").toString().replace(/^file:\/\//, ""))
    function metric(id) { return metrics.find(entry => entry.id === id); }
    function icon(entry) {
        if (entry.id.startsWith("battery.")) return "󰁹";
        if (entry.unit === "°C") return "󰔏";
        if (entry.unit === "W") return "󱐋";
        if (entry.unit === "B") return "󰾆";
        return entry.id.startsWith("gpu.") ? "󰢮" : "󰍛";
    }
    function format(entry) {
        if (!entry?.available) return "—";
        if (entry.unit === "B") return (entry.value / 1073741824).toFixed(1) + "/" + (entry.total / 1073741824).toFixed(1) + " GiB";
        return (entry.unit === "W" ? entry.value.toFixed(1) : Math.round(entry.value)) + (entry.unit === "%" ? "%" : " " + entry.unit);
    }
    function maximum(entry) {
        if (entry.maximum > 0) return entry.maximum;
        const values = (history[entry.id] || []).map(point => point.value || 0);
        return Math.max(1, entry.value || 0, ...values);
    }
    function accept(snapshot) {
        if (!Array.isArray(snapshot.metrics) || !Number.isFinite(snapshot.timestamp)) throw new Error("Invalid snapshot");
        const next = snapshot.metrics;
        if (detailed) metrics.forEach(previous => {
            if (!next.some(entry => entry.id === previous.id))
                next.push(Object.assign({}, previous, {available: false, value: null, reason: "Device disconnected"}));
        });
        const cpu = next.find(entry => entry.id === "cpu.load");
        const ram = next.find(entry => entry.id === "ram.usage");
        cpuUsage = cpu?.available ? Math.round(cpu.value) : 0;
        memUsage = ram?.available && ram.total > 0 ? Math.round(100 * ram.value / ram.total) : 0;
        if (detailed) {
            const updated = {};
            next.forEach(entry => {
                const points = (history[entry.id] || []).filter(point => point.time >= snapshot.timestamp - 600000);
                points.push({time: snapshot.timestamp, value: entry.available ? entry.value : null});
                updated[entry.id] = points.slice(-301);
            });
            history = updated;
        }
        metrics = next;
        temperatureSources = snapshot.temperatureSources || [];
        errorMessage = "";
        staleTimer.restart();
    }
    function invalidate() {
        metrics = metrics.map(entry => Object.assign({}, entry, {available: false, value: null, reason: "Monitoring collector unavailable"}));
    }
    function restart() {
        if (!completed) return;
        restartTimer.interval = 250;
        restartTimer.restart();
        if (collector.running) collector.running = false;
    }
    function openBtop() {
        if (terminal.running) return;
        launchError = "";
        terminal.running = true;
    }
    onDetailedChanged: restart()
    Connections {
        target: Monitoring
        function onCpuSensorChanged() { root.restart(); }
    }
    Component.onCompleted: { completed = true; restart(); }
    Process {
        id: collector
        command: ["python3", root.helper, "--watch", String(Settings.statsInterval / 1000), "--cpu-sensor", Monitoring.cpuSensor].concat(root.detailed ? [] : ["--basic"])
        stdout: SplitParser {
            onRead: data => {
                try { root.accept(JSON.parse(data)); }
                catch (error) { root.errorMessage = "Could not read monitoring data."; }
            }
        }
        stderr: StdioCollector {}
        onExited: {
            if (!restartTimer.running) {
                root.errorMessage = "Monitoring collector stopped. Retrying…";
                root.invalidate();
                restartTimer.interval = 5000;
                restartTimer.restart();
            }
        }
    }
    Timer { id: restartTimer; interval: 250; onTriggered: { if (!collector.running) collector.running = true; else restart(); } }
    Timer { id: staleTimer; interval: 6500; onTriggered: { root.errorMessage = "Monitoring data is stale."; root.invalidate(); } }
    Process {
        id: terminal
        command: ["python3", root.launcher]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.launchError = JSON.parse(text).error || ""; }
                catch (error) { root.launchError = "Could not launch btop."; }
            }
        }
        stderr: StdioCollector {}
        onExited: code => { if (code !== 0) root.launchError = root.launchError || "Could not launch btop."; }
    }
}
