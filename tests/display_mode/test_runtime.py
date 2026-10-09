"""Exercise the real widget, singleton and helper against a fake hyprctl."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class RuntimeTests(unittest.TestCase):
    def test_widget_service_toggle_and_restore(self):
        with tempfile.TemporaryDirectory(prefix='qs-display-mode-') as directory:
            base = Path(directory)
            for name in ['config', 'services', 'scripts', 'modules/bar/widgets', 'components', 'runtime', 'bin']:
                (base / name).mkdir(parents=True, mode=0o700)
            for name in ['services/DisplayMode.qml', 'scripts/display-mode.py',
                         'modules/bar/widgets/DisplayModeWidget.qml', 'components/BarHoverIndicator.qml']:
                shutil.copyfile(ROOT / name, base / name)
            (base / 'services/qmldir').write_text('singleton DisplayMode 1.0 DisplayMode.qml\n')
            (base / 'config/qmldir').write_text('singleton Theme 1.0 Theme.qml\nsingleton Settings 1.0 Settings.qml\n')
            (base / 'config/Theme.qml').write_text('''pragma Singleton
import QtQuick
QtObject {
 property bool verticalBar: false
 property int sideBarWidth: 64
 property int fontSize: 20
 property string fontFamily: "sans-serif"
 property color text: "white"
 property color subtle: "gray"
 property color iris: "#c4a7e7"
 property color love: "#eb6f92"
}
''')
            (base / 'config/Settings.qml').write_text('pragma Singleton\nimport QtQuick\nQtObject { property int barHeight: 42 }\n')
            (base / 'state.json').write_text(json.dumps([
                dict(id=0, name='eDP-1', mirrorOf='none'),
                dict(id=1, name='HDMI-A-1', mirrorOf='none', width=2560, height=1440, refreshRate=144),
            ]))
            fake = base / 'bin/hyprctl'
            fake.write_text('''#!/usr/bin/env python3
import json, os, pathlib, sys
base = pathlib.Path(os.environ['DISPLAY_TEST_BASE'])
path = base / 'state.json'
state = json.loads(path.read_text())
args = sys.argv[1:]
if args == ['-j', 'monitors', 'all']:
    print(json.dumps(state))
elif args[0] in ('eval', 'reload'):
    with (base / 'actions.jsonl').open('a') as stream:
        stream.write(json.dumps(args) + '\\n')
    state[1]['mirrorOf'] = '0' if args[0] == 'eval' else 'none'
    state[1]['refreshRate'] = 60 if args[0] == 'eval' else 144
    path.write_text(json.dumps(state))
    print('ok')
elif args == ['configerrors']:
    print('')
else:
    sys.exit(1)
''')
            fake.chmod(0o700)
            (base / 'shell.qml').write_text('''import QtQuick
import Quickshell
import "services"
import "modules/bar/widgets"
ShellRoot {
    property int phase: 0
    property int elapsed: 0
    DisplayModeWidget { id: button }
    Timer {
        interval: 50; running: true; repeat: true
        onTriggered: {
            elapsed += 50;
            if (elapsed > 8000 || DisplayMode.errorMessage) {
                console.log("DISPLAY_TEST_FAILED: " + JSON.stringify({phase: phase, busy: DisplayMode.busy,
                    available: DisplayMode.available, mirrored: DisplayMode.mirrored,
                    reason: DisplayMode.reason, error: DisplayMode.errorMessage}));
                Qt.quit(); return;
            }
            if (DisplayMode.busy || !DisplayMode.available) return;
            if (phase === 0) {
                if (button.actionText !== "Duplicate laptop screen") throw new Error("initial label");
                DisplayMode.toggle();
                DisplayMode.toggle(); // A second click must not issue a second command.
                phase = 1;
            } else if (phase === 1 && DisplayMode.mirrored) {
                if (button.actionText !== "Restore configured monitor layout") throw new Error("restore label");
                DisplayMode.toggle();
                phase = 2;
            } else if (phase === 2 && !DisplayMode.mirrored) {
                console.log("DISPLAY_TEST_OK"); Qt.quit();
            }
        }
    }
}
''')
            env = dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software',
                       XDG_RUNTIME_DIR=str(base / 'runtime'), XDG_STATE_HOME=str(base / 'state'),
                       XDG_CACHE_HOME=str(base / 'cache'), HYPRLAND_INSTANCE_SIGNATURE='',
                       DISPLAY_TEST_BASE=str(base), PATH=str(base / 'bin') + os.pathsep + os.environ['PATH'])
            result = subprocess.run(['quickshell', '--path', str(base)], env=env,
                                    text=True, capture_output=True, timeout=15)
            output = result.stdout + result.stderr
            if 'DISPLAY_TEST_OK' not in output:
                output += '\nActions: ' + ((base / 'actions.jsonl').read_text() if (base / 'actions.jsonl').exists() else 'none')
                output += '\nState: ' + (base / 'state.json').read_text()
            self.assertEqual(result.returncode, 0, output)
            self.assertIn('DISPLAY_TEST_OK', output)
            self.assertNotIn('DISPLAY_TEST_FAILED', output)
            self.assertNotIn('ReferenceError', output)
            self.assertNotIn('TypeError', output)
            actions = [json.loads(line) for line in (base / 'actions.jsonl').read_text().splitlines()]
            self.assertEqual([action[0] for action in actions], ['eval', 'reload'])
            self.assertEqual(json.loads((base / 'state.json').read_text())[1]['refreshRate'], 144)


if __name__ == '__main__':
    unittest.main()
