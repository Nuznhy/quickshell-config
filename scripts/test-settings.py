#!/usr/bin/env python3
"""Test the layout model, drag/drop UI, and section geometry in isolation."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import json
import time

root = Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory(prefix='qs-settings-test-') as directory:
    target = Path(directory)
    for subdir in ['config', 'components', 'modules/settings', 'modules/bar/widgets', 'runtime']:
        (target / subdir).mkdir(parents=True, exist_ok=True, mode=0o700)
    for name in ['ControlSwitch.qml', 'NotificationButton.qml']:
        shutil.copyfile(root / 'components' / name, target / 'components' / name)
    for path in ['config/BarLayoutData.js', 'modules/settings/BarLayoutEditor.qml', 'modules/bar/BarSection.qml']:
        shutil.copyfile(root / path, target / path)
    (target / 'config/qmldir').write_text('singleton Theme 1.0 Theme.qml\nsingleton BarLayout 1.0 BarLayout.qml\nsingleton Settings 1.0 Settings.qml\n')
    (target / 'config/Theme.qml').write_text('''pragma Singleton
import QtQuick
QtObject {
    property bool verticalBar: false
    readonly property color bg: "#191724"
    readonly property color surface: "#1f1d2e"
    readonly property color overlay: "#26233a"
    readonly property color highlightMed: "#403d52"
    readonly property color iris: "#c4a7e7"
    readonly property color text: "#e0def4"
    readonly property color subtle: "#908caa"
    readonly property string fontFamily: "sans-serif"
}
''')
    (target / 'config/Settings.qml').write_text('''pragma Singleton
import QtQuick
QtObject { readonly property int barHeight: 42; readonly property int widgetSpacing: 12 }
''')
    (target / 'config/BarLayout.qml').write_text('''pragma Singleton
import QtQuick
import "BarLayoutData.js" as Data
QtObject {
    property var state: Data.defaults()
    property bool ready: true
    property bool showMedia: true
    property bool showWorkspaces: true
    function ids(section) { return state.sections[section]; }
    function entry(id) { return Data.widget(id); }
    function isEnabled(id) { return !state.disabled.includes(id); }
    function reset() { state = Data.defaults(); }
    function setEnabled(id, enabled) { state = Data.setEnabled(state, id, enabled); }
    function move(id, section, index) { state = Data.move(state, id, section, index); }
}
''')
    for name, conditional in [('WorkspaceBar', 'implicitWidth: BarLayout.showWorkspaces ? 30 : 0'),
                              ('Tray', 'implicitWidth: 30'),
                              ('MediaWidget', 'implicitWidth: 30; visible: BarLayout.showMedia')]:
        (target / f'modules/bar/widgets/{name}.qml').write_text('import QtQuick\nimport "../../../config"\nItem { implicitHeight: 42; ' + conditional + ' }\n')
    for path in (root / 'tests/settings').glob('tst_*.qml'):
        shutil.copyfile(path, target / path.name)
    env = dict(os.environ, QT_QPA_PLATFORM='offscreen', XDG_RUNTIME_DIR=str(target / 'runtime'))
    subprocess.run([os.environ.get('QMLTESTRUNNER', '/usr/lib/qt6/bin/qmltestrunner'), '-input', str(target)], env=env, check=True)

    # Exercise the real FileView singleton across process restarts, never the
    # desktop shell's state. A failed write is produced with a directory at the
    # intended file path, which is reliable even when tests run as root.
    shutil.copyfile(root / 'config/BarLayout.qml', target / 'config/BarLayout.qml')
    (target / 'shell.qml').write_text('''import QtQuick
import Quickshell
import "config"
ShellRoot {
    property int elapsed: 0
    property bool started: false
    function fail(message) { console.error("SETTINGS_TEST_FAILED: " + message); Qt.quit(); }
    Timer {
        interval: 50; running: true; repeat: true
        onTriggered: {
            elapsed += 50;
            if (elapsed > 5000) { fail("timeout"); return; }
            if (!BarLayout.ready) return;
            const phase = Quickshell.env("QS_TEST_PHASE");
            if (!started) {
                started = true;
                if (phase === "write") {
                    BarLayout.move("clock", "start", 1);
                    BarLayout.setEnabled("settings", false);
                } else if (phase === "read") {
                    if (BarLayout.ids("start")[1] !== "clock" || BarLayout.isEnabled("settings")) {
                        fail("saved state was not restored"); return;
                    }
                } else if (phase === "corrupt") {
                    if (!BarLayout.errorMessage || BarLayout.ids("center")[0] !== "clock") {
                        fail("corrupt state did not fall back"); return;
                    }
                    BarLayout.reset();
                } else if (phase === "failure") {
                    BarLayout.setEnabled("tray", false);
                }
            }
            if (elapsed < 900) return;
            if (phase === "failure") {
                if (BarLayout.isEnabled("tray") || !BarLayout.errorMessage.includes("could not save")) {
                    fail("write failure was not surfaced"); return;
                }
            } else if (BarLayout.errorMessage) { fail(BarLayout.errorMessage); return; }
            console.log("SETTINGS_TEST_OK: " + phase);
            Qt.quit();
        }
    }
}
''')
    env.update(XDG_STATE_HOME=str(target / 'state'), XDG_CACHE_HOME=str(target / 'cache'),
               QT_QUICK_BACKEND='software')

    def run_phase(phase):
        result = subprocess.run(['quickshell', '--path', str(target)],
                                env=dict(env, QS_TEST_PHASE=phase),
                                text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                timeout=15, check=True)
        if f'SETTINGS_TEST_OK: {phase}' not in result.stdout or 'SETTINGS_TEST_FAILED' in result.stdout:
            raise AssertionError(result.stdout)
        print(f'PASS: real layout persistence / {phase}', flush=True)

    run_phase('write')
    run_phase('read')
    state_file, = (target / 'state').rglob('bar-layout.json')
    state_file.write_text('{invalid json')
    run_phase('corrupt')
    state_file.unlink()
    state_file.mkdir()
    run_phase('failure')

    # Real settings-window lifecycle and recovery IPC with every widget hidden.
    state_file.rmdir()
    for subdir in ['components', 'config', 'services', 'modules/settings']:
        shutil.copytree(root / subdir, target / subdir, dirs_exist_ok=True)
    (target / 'shell.qml').write_text('''import QtQuick
import Quickshell
import Quickshell.Io
import "config"
import "services"
import "modules/settings"
ShellRoot {
    SettingsWindow { id: window }
    IpcHandler {
        target: "test"
        function hideAll(): void {
            for (const entry of BarLayout.registry) BarLayout.setEnabled(entry.id, false);
        }
        function status(): string {
            return JSON.stringify({visible: window.visible, opened: ShellSettings.opened,
                ready: Theme.ready && BarLayout.ready, disabled: BarLayout.state.disabled.length});
        }
    }
}
''')
    with (target / 'window.log').open('w+') as log:
        process = subprocess.Popen(['quickshell', '--path', str(target)], env=env,
                                   stdout=log, stderr=subprocess.STDOUT)
        try:
            def ipc(target_name, action):
                result = subprocess.run(['quickshell', 'ipc', '--path', str(target), 'call', target_name, action],
                                        env=env, capture_output=True, text=True, timeout=5)
                if result.returncode:
                    raise RuntimeError(result.stdout + result.stderr)
                return result.stdout.strip()

            deadline = time.monotonic() + 8
            while True:
                try:
                    status = json.loads(ipc('test', 'status'))
                    if status['ready']:
                        break
                except (RuntimeError, json.JSONDecodeError):
                    pass
                if time.monotonic() >= deadline:
                    log.seek(0)
                    raise AssertionError(log.read())
                time.sleep(0.05)
            assert not status['visible']
            ipc('settings', 'open')
            assert json.loads(ipc('test', 'status'))['visible']
            ipc('settings', 'open')  # Reuses the same window.
            ipc('test', 'hideAll')
            assert json.loads(ipc('test', 'status'))['disabled'] == 14
            ipc('settings', 'close')
            assert not json.loads(ipc('test', 'status'))['visible']
            ipc('settings', 'open')
            assert json.loads(ipc('test', 'status'))['visible']
            ipc('settings', 'toggle')
            assert not json.loads(ipc('test', 'status'))['opened']
            log.flush()
            log.seek(0)
            output = log.read()
            for error in ['ReferenceError', 'TypeError', 'Binding loop', 'Failed to load configuration']:
                assert error not in output, output
            print('PASS: settings window reuse, close, toggle, and recovery with all widgets hidden', flush=True)
        finally:
            process.terminate()
            process.wait(timeout=5)
