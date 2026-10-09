#!/usr/bin/env python3
"""Check that brightness writes/readback preserve controls and avoid discovery."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent
subprocess.run(['python3', '-m', 'unittest', 'discover', '-s', str(ROOT / 'tests/brightness'), '-v'], check=True)
with tempfile.TemporaryDirectory(prefix='qs-brightness-') as directory:
    base = Path(directory)
    for name in ['services', 'scripts', 'runtime']:
        (base / name).mkdir(mode=0o700)
    shutil.copyfile(ROOT / 'services/Brightness.qml', base / 'services/Brightness.qml')
    (base / 'services/qmldir').write_text('singleton Brightness 1.0 Brightness.qml\n')
    (base / 'scripts/brightness.py').write_text('''import json, sys
from pathlib import Path
base = Path(__file__).parent
args = sys.argv[1:]
with (base / 'calls').open('a') as log: log.write(json.dumps(args) + '\\n')
if not args:
    result = {'displays': [{'id': 'ddc:1', 'name': 'Monitor', 'connection': 'DP-1', 'supported': True, 'value': 40}]}
elif args[0] == 'set':
    (base / 'value').write_text(args[2])
    result = {'ok': True}
else:
    value = int((base / 'value').read_text())
    result = {'levels': [{'id': 'ddc:1', 'value': value}]} if value != 77 else {'levels': [{'id': 'ddc:1', 'error': 'temporarily busy'}]}
print(json.dumps(result))
''')
    (base / 'shell.qml').write_text('''import QtQuick
import Quickshell
import "services"
ShellRoot {
    property int step: 0
    property var original: null
    function fail(message) { console.error("BRIGHTNESS_FAILED", message); Qt.quit(); }
    Timer {
        interval: 100; running: true; repeat: true
        onTriggered: {
            if (Brightness.loading || Brightness.changing) return;
            if (step === 0) { Brightness.openPanels = 1; step++; return; }
            if (!Brightness.displays.length) return;
            if (step === 1) {
                original = Brightness.displays[0];
                Brightness.setBrightness("ddc:1", 60);
                Brightness.setBrightness("ddc:1", 65);
                step++; return;
            }
            if (step === 2) {
                if (Brightness.displays[0] !== original || original.value !== 65) { fail("write replaced entry or lost latest value"); return; }
                Brightness.setBrightness("ddc:1", 77);
                step++; return;
            }
            if (step === 3) {
                if (!original.error) return;
                if (Brightness.displays[0] !== original || !original.supported || original.value !== 77) { fail("failed check reset controls"); return; }
                Brightness.setBrightness("ddc:1", 80);
                step++; return;
            }
            if (step === 4) {
                if (original.error) return;
                if (original.value !== 80) { fail("recovery value"); return; }
                console.log("BRIGHTNESS_OK"); Qt.quit();
            }
        }
    }
}
''')
    env = dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software',
               XDG_RUNTIME_DIR=str(base / 'runtime'))
    result = subprocess.run(['quickshell', '--path', str(base)], env=env, capture_output=True, text=True, timeout=15)
    output = result.stdout + result.stderr
    assert 'BRIGHTNESS_OK' in output and 'BRIGHTNESS_FAILED' not in output, output
    for error in ['ReferenceError', 'TypeError', 'Binding loop', 'Unable to assign']:
        assert error not in output, output
    import json
    calls = [json.loads(line) for line in (base / 'scripts/calls').read_text().splitlines()]
    assert calls.count([]) == 1, calls
    assert sum(bool(call) and call[0] == 'levels' for call in calls) >= 3, calls
    print('PASS: one discovery, queued writes, stable entries, readback failure and recovery')
