pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

Singleton {
    id: root
    property int volumeLevel: 0
    property bool volumeMuted: false
    property var outputs: []
    property string defaultOutput: ""
    property var microphones: []
    property string defaultMicrophone: ""
    property int microphoneVolume: 0
    property bool microphoneMuted: false
    property var pendingDeviceCommands: []
    property string errorMessage: ""
    property alias streams: streamModel
    property var pendingStreamCommands: []
    property int audioRevision: 0
    readonly property bool commandsPending: deviceCommandProc.running || streamCommandProc.running
        || pendingDeviceCommands.length > 0 || pendingStreamCommands.length > 0 || switching || switchingMicrophone
    readonly property bool switching: switchProc.running
    readonly property bool switchingMicrophone: microphoneProc.running
    readonly property bool available: outputs.some(output => output.name === defaultOutput)
    readonly property bool microphoneAvailable: microphones.some(source => source.name === defaultMicrophone)

    ListModel { id: streamModel }

    function updateStreams(inputs) {
        const ids = inputs.map(input => input.index);
        for (let i = streamModel.count - 1; i >= 0; --i) {
            if (!ids.includes(streamModel.get(i).streamId)) streamModel.remove(i);
        }
        inputs.forEach(input => {
            const properties = input.properties || {};
            const channels = Object.values(input.volume || {});
            const row = {
                streamId: input.index,
                appName: properties["application.name"] || properties["application.process.binary"] || "Audio application",
                iconName: properties["application.icon_name"] || "",
                desktopId: properties["application.desktop"] || properties["application.id"] || "",
                binaryName: properties["application.process.binary"] || "",
                mediaName: properties["media.name"] || "",
                volume: channels.length ? Math.round(channels.reduce((sum, channel) => sum + parseInt(channel.value_percent, 10), 0) / channels.length) : 0,
                muted: !!input.mute,
                writable: input.has_volume !== false && input.volume_writable !== false && channels.length > 0
            };
            let index = -1;
            for (let i = 0; i < streamModel.count; ++i) {
                if (streamModel.get(i).streamId === input.index) { index = i; break; }
            }
            // Updating roles in place preserves sliders while playback state is polled.
            if (index < 0) streamModel.append(row);
            else streamModel.set(index, row);
        });
    }

    function streamCommand(id, action, value) {
        let exists = false;
        for (let i = 0; i < streamModel.count; ++i) {
            if (streamModel.get(i).streamId === id) exists = true;
        }
        if (!exists) return;
        audioRevision++;
        enqueue(pendingStreamCommands, ["pactl", action, String(id), value]);
        errorMessage = "";
        runNextStreamCommand();
    }

    function setStreamVolume(id, value) {
        if (!Number.isFinite(value)) return;
        const volume = Math.round(Math.max(0, Math.min(150, value)));
        for (let i = 0; i < streamModel.count; ++i) {
            if (streamModel.get(i).streamId === id) streamModel.setProperty(i, "volume", volume);
        }
        streamCommand(id, "set-sink-input-volume", volume + "%");
    }

    function setStreamMuted(id, muted) {
        streamCommand(id, "set-sink-input-mute", muted ? "1" : "0");
    }

    function runNextStreamCommand() {
        if (streamCommandProc.running || !pendingStreamCommands.length) return;
        streamCommandProc.command = pendingStreamCommands.shift();
        streamCommandProc.running = true;
    }

    Process {
        id: streamCommandProc
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) root.errorMessage = "Could not change application audio. The stream may have closed.";
            root.runNextStreamCommand();
            root.refresh();
        }
    }

    function refresh() {
        if (statusProc.running || commandsPending) return;
        statusProc.revision = audioRevision;
        statusProc.running = true;
    }

    function adjustVolume(delta) {
        // Use the optimistic value so rapid scroll steps accumulate correctly.
        if (available) setOutputVolume(volumeLevel + (delta.startsWith("-") ? -5 : 5));
    }

    function toggleMute() {
        if (available) deviceCommand("set-sink-mute", defaultOutput, "toggle");
    }

    function setOutputVolume(value) {
        if (!available || !Number.isFinite(value)) return;
        volumeLevel = Math.round(Math.max(0, Math.min(150, value)));
        deviceCommand("set-sink-volume", defaultOutput, volumeLevel + "%");
    }

    function setMicrophoneVolume(value) {
        if (!microphoneAvailable || !Number.isFinite(value)) return;
        microphoneVolume = Math.round(Math.max(0, Math.min(100, value)));
        deviceCommand("set-source-volume", defaultMicrophone, microphoneVolume + "%");
    }

    function toggleMicrophoneMute() {
        if (microphoneAvailable) deviceCommand("set-source-mute", defaultMicrophone, "toggle");
    }

    function deviceCommand(action, device, value) {
        audioRevision++;
        enqueue(pendingDeviceCommands, ["pactl", action, device, value]);
        errorMessage = "";
        runNextDeviceCommand();
    }

    function enqueue(queue, command) {
        // Replace unsent volume requests for the same target; preserve mute toggles.
        if (command[1].endsWith("-volume")) {
            for (let i = queue.length - 1; i >= 0; --i) {
                if (queue[i][1] === command[1] && queue[i][2] === command[2]) {
                    queue[i] = command;
                    return;
                }
            }
        }
        queue.push(command);
    }

    function runNextDeviceCommand() {
        if (deviceCommandProc.running || !pendingDeviceCommands.length) return;
        deviceCommandProc.command = pendingDeviceCommands.shift();
        deviceCommandProc.running = true;
    }

    function selectOutput(name) {
        if (switching || !outputs.some(output => output.name === name)) return;
        audioRevision++;
        errorMessage = "";
        switchProc.command = ["bash", Qt.resolvedUrl("../scripts/audio-select-output.sh").toString().replace("file://", ""), name];
        switchProc.running = true;
    }

    function openControl() {
        volumeControlProc.running = true;
    }

    function selectMicrophone(name) {
        if (switchingMicrophone || name === defaultMicrophone || !microphones.some(source => source.name === name)) return;
        audioRevision++;
        errorMessage = "";
        microphoneProc.command = ["bash", Qt.resolvedUrl("../scripts/audio-select-input.sh").toString().replace("file://", ""), name];
        microphoneProc.running = true;
    }

    Process {
        id: statusProc
        property int revision: 0
        command: ["bash", Qt.resolvedUrl("../scripts/audio-status.sh").toString().replace("file://", "")]
        Component.onCompleted: root.refresh()
        onExited: {
            if (revision !== root.audioRevision) root.refresh();
        }
        stdout: StdioCollector {
            onStreamFinished: {
                // Never apply a snapshot begun before a write or while writes are queued.
                if (statusProc.revision !== root.audioRevision || root.commandsPending) return;
                try {
                    var data = JSON.parse(text);
                    root.updateStreams(data.inputs || []);
                    var devices = data.sinks.map(sink => ({name: sink.name, description: sink.description || sink.name}));
                    // Avoid rebuilding device buttons on every volume poll.
                    if (JSON.stringify(devices) !== JSON.stringify(root.outputs)) root.outputs = devices;
                    root.defaultOutput = data.default;
                    const monitors = data.sinks.map(sink => sink.monitor_source);
                    const microphones = (data.sources || [])
                        .filter(source => !monitors.includes(source.name) && !source.name.endsWith(".monitor") && source.properties?.["device.class"] !== "monitor")
                        .map(source => ({name: source.name, description: source.description || source.name}));
                    if (JSON.stringify(microphones) !== JSON.stringify(root.microphones)) root.microphones = microphones;
                    root.defaultMicrophone = data.defaultSource || "";
                    const microphone = (data.sources || []).find(source => source.name === root.defaultMicrophone);
                    root.microphoneMuted = microphone ? !!microphone.mute : false;
                    const micChannels = Object.values(microphone?.volume || {});
                    root.microphoneVolume = micChannels.length ? Math.round(micChannels.reduce((sum, channel) => sum + parseInt(channel.value_percent, 10), 0) / micChannels.length) : 0;
                    var active = data.sinks.find(sink => sink.name === data.default);
                    root.volumeMuted = active ? active.mute : false;
                    var channels = active ? Object.values(active.volume) : [];
                    root.volumeLevel = channels.length ? Math.round(channels.reduce((sum, channel) => sum + parseInt(channel.value_percent, 10), 0) / channels.length) : 0;
                    if (root.errorMessage === "Audio server unavailable.") root.errorMessage = "";
                } catch (error) {
                    root.outputs = [];
                    root.microphones = [];
                    root.defaultMicrophone = "";
                    root.microphoneVolume = 0;
                    root.microphoneMuted = false;
                    streamModel.clear();
                    root.defaultOutput = "";
                    root.volumeLevel = 0;
                    root.volumeMuted = false;
                    root.errorMessage = "Audio server unavailable.";
                }
            }
        }
    }

    Process {
        id: switchProc
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) root.errorMessage = "Could not switch all audio. Check sound settings.";
            root.refresh();
        }
    }

    Process {
        id: volumeControlProc
        command: Settings.volumeControlCommand
    }

    Process {
        id: microphoneProc
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) root.errorMessage = "Could not switch all microphone audio. Check sound settings.";
            root.refresh();
        }
    }

    Process {
        id: deviceCommandProc
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) root.errorMessage = "Could not change device audio. The device may have disconnected.";
            root.runNextDeviceCommand();
            root.refresh();
        }
    }

    Timer {
        interval: Settings.audioInterval
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
