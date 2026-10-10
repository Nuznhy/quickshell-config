import QtQuick
import Quickshell.Io

Item {
    id: root
    property bool active: false
    property date firstDate
    property date endDate
    property var events: []
    property string errorMessage: ""
    readonly property bool loading: reader.running || debounce.running
    readonly property string rangeKey: Qt.formatDate(firstDate, "yyyy-MM-dd") + "/" + Qt.formatDate(endDate, "yyyy-MM-dd")
    readonly property string helper: decodeURIComponent(Qt.resolvedUrl("../scripts/ical-calendar.py").toString().replace(/^file:\/\//, ""))
    property int generation: 0
    property bool refreshPending: false

    function refresh() {
        if (!active) return;
        if (reader.running) { refreshPending = true; return; }
        errorMessage = "";
        reader.requestGeneration = generation;
        reader.received = false;
        reader.command = ["python3", helper, "events", Qt.formatDate(firstDate, "yyyy-MM-dd"), Qt.formatDate(endDate, "yyyy-MM-dd")];
        reader.running = true;
    }
    function invalidate() {
        generation++;
        events = [];
        errorMessage = "";
        refreshPending = false;
        debounce.stop();
        if (reader.running) reader.signal(9);
        if (active) debounce.restart();
    }
    function eventsOn(day) {
        const key = Qt.formatDate(day, "yyyy-MM-dd");
        const first = new Date(day.getFullYear(), day.getMonth(), day.getDate()).getTime();
        const last = new Date(day.getFullYear(), day.getMonth(), day.getDate() + 1).getTime();
        return events.filter(event => event.allDay ? event.startDay <= key && key < event.endDay
                            : event.start < last && (event.end > first || event.start === event.end && event.start >= first));
    }
    onActiveChanged: invalidate()
    onRangeKeyChanged: invalidate()
    Timer { id: debounce; interval: 120; onTriggered: root.refresh() }
    Timer { interval: 300000; repeat: true; running: root.active; onTriggered: root.refresh() }
    Timer {
        interval: 45000
        running: reader.running
        onTriggered: {
            root.generation++;
            root.events = [];
            root.errorMessage = "Calendar request timed out. Check your connection and keyring, then Refresh.";
            reader.signal(9);
        }
    }
    Process {
        id: reader
        property int requestGeneration: -1
        property bool received: false
        stdout: SplitParser {
            onRead: data => {
                if (!root.active || reader.requestGeneration !== root.generation) return;
                reader.received = true;
                try {
                    const result = JSON.parse(data);
                    if (!Array.isArray(result.events)) throw new Error("invalid events");
                    root.events = result.events;
                    root.errorMessage = result.error || "";
                } catch (error) {
                    root.events = [];
                    root.errorMessage = "Could not read calendar events.";
                }
            }
        }
        // Consume diagnostics without forwarding account/backend details to logs.
        stderr: SplitParser { onRead: data => {} }
        onExited: code => {
            if (root.active && requestGeneration === root.generation && (code !== 0 || !received)) {
                root.events = [];
                root.errorMessage = "Calendar helper unavailable or resource limit reached. See README → iCalendar feed.";
            }
            if (root.refreshPending && root.active) {
                root.refreshPending = false;
                debounce.restart();
            }
        }
    }
}
