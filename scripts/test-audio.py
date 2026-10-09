#!/usr/bin/env python3
"""Exercise audio switching and failed readback without removing confirmed state."""
from pathlib import Path
import os
import shlex
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory(prefix='qs-audio-') as directory:
    base = Path(directory)
    for name in ['services', 'scripts', 'config', 'runtime']:
        (base / name).mkdir(mode=0o700)
    shutil.copyfile(ROOT / 'services/Audio.qml', base / 'services/Audio.qml')
    (base / 'services/qmldir').write_text('singleton Audio 1.0 Audio.qml\n')
    (base / 'config/qmldir').write_text('singleton Settings 1.0 Settings.qml\n')
    (base / 'config/Settings.qml').write_text('pragma Singleton\nimport QtQuick\nQtObject { property int audioInterval: 60000; property var volumeControlCommand: [] }\n')
    helper = base / 'scripts/mock.py'
    helper.write_text('''import json, sys
from pathlib import Path
base = Path(__file__).parent
mode = sys.argv[1]
if mode != 'status':
    (base / mode).write_text(sys.argv[2])
    sys.exit(0)
count = int((base / 'count').read_text()) + 1 if (base / 'count').exists() else 1
(base / 'count').write_text(str(count))
if count == 3:
    print('temporary read failure')
    sys.exit(1)
def device(name): return {'name': name, 'description': name, 'mute': False, 'volume': {'mono': {'value_percent': '45%'}}}
print(json.dumps({'sinks': [device('speaker1'), device('speaker2')], 'sources': [device('mic1'), device('mic2')],
 'default': (base / 'output').read_text() if (base / 'output').exists() else 'speaker1',
 'defaultSource': (base / 'input').read_text() if (base / 'input').exists() else 'mic1', 'inputs': []}))
''')
    for name, mode in [('audio-status', 'status'), ('audio-select-output', 'output'), ('audio-select-input', 'input')]:
        (base / 'scripts' / (name + '.sh')).write_text('exec python3 ' + shlex.quote(str(helper)) + ' ' + mode + ' "$@"\n')
    (base / 'shell.qml').write_text('''import QtQuick
import Quickshell
import "services"
ShellRoot {
    Timer { interval: 5000; running: true; onTriggered: fail("timeout step " + step + " output " + Audio.defaultOutput + " error " + Audio.errorMessage) }
    property int step: 0
    property var outputs: null
    property var microphones: null
    function fail(message) { console.error("AUDIO_FAILED", message); Qt.quit(); }
    Timer {
        interval: 100; running: true; repeat: true
        onTriggered: {
            if (Audio.switching || Audio.switchingMicrophone) return;
            if (step === 0 && Audio.defaultOutput === "speaker1") {
                outputs = Audio.outputs; microphones = Audio.microphones;
                Audio.selectOutput("speaker2"); step++; return;
            }
            if (step === 1 && Audio.defaultOutput === "speaker2") {
                Audio.selectMicrophone("mic2"); step++; return;
            }
            if (step === 2 && Audio.errorMessage) {
                if (Audio.outputs !== outputs || Audio.microphones !== microphones || Audio.volumeLevel !== 45 || Audio.defaultMicrophone !== "mic1") {
                    fail("failed readback cleared confirmed state"); return;
                }
                Audio.refresh(); step++; return;
            }
            if (step === 3 && Audio.defaultMicrophone === "mic2") {
                if (Audio.errorMessage || Audio.outputs !== outputs || Audio.microphones !== microphones) { fail("recovery rebuilt device lists"); return; }
                console.log("AUDIO_OK"); Qt.quit();
            }
        }
    }
}
''')
    env = dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software', XDG_RUNTIME_DIR=str(base / 'runtime'))
    result = subprocess.run(['quickshell', '--path', str(base)], env=env, capture_output=True, text=True, timeout=15)
    output = result.stdout + result.stderr
    assert 'AUDIO_OK' in output and 'AUDIO_FAILED' not in output, output
    for error in ['ReferenceError', 'TypeError', 'Binding loop', 'Unable to assign']:
        assert error not in output, output
    print('PASS: output/input switching, failed readback preserves confirmed state, recovery retains device lists')
