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
    def test_widget_switches_both_ways(self):
        with tempfile.TemporaryDirectory(prefix='qs-desktop-tv-') as directory:
            base = Path(directory)
            for name in ['config', 'services', 'scripts', 'modules/bar/widgets',
                         'components', 'runtime', 'bin']:
                (base / name).mkdir(parents=True, mode=0o700)
            for name in ['services/DesktopTv.qml', 'scripts/desktop-tv.py',
                         'modules/bar/widgets/DesktopTvWidget.qml',
                         'components/BarHoverIndicator.qml']:
                shutil.copyfile(ROOT / name, base / name)
            (base / 'services/qmldir').write_text('singleton DesktopTv 1.0 DesktopTv.qml\n')
            (base / 'config/qmldir').write_text(
                'singleton Theme 1.0 Theme.qml\nsingleton Settings 1.0 Settings.qml\n')
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
            (base / 'config/Settings.qml').write_text(
                'pragma Singleton\nimport QtQuick\nQtObject { property int barHeight: 42 }\n')
            (base / 'state.json').write_text(json.dumps(['DP-1', 'DP-2']))
            (base / 'pending.json').write_text('false')
            fake = base / 'bin/hyprctl'
            fake.write_text('''#!/usr/bin/env python3
import json, os, pathlib, sys
base = pathlib.Path(os.environ['DISPLAY_TEST_BASE'])
path = base / 'state.json'
pending_path = base / 'pending.json'
state = json.loads(path.read_text())
pending = json.loads(pending_path.read_text())
args = sys.argv[1:]
if args == ['-j', 'monitors', 'all']:
    print(json.dumps([dict(name=name, disabled=False) for name in state]))
elif args[0] == 'repl':
    print(str(pending).lower())
elif args[0] == 'eval':
    with (base / 'actions.jsonl').open('a') as stream:
        stream.write(json.dumps(args) + '\\n')
    if 'confirmTv()' in args[1]:
        pending = False
    else:
        state = ['HDMI-A-1'] if 'DP-1' in state else ['DP-1', 'DP-2']
        pending = state == ['HDMI-A-1']
    path.write_text(json.dumps(state))
    pending_path.write_text(json.dumps(pending))
    print('ok')
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
    DesktopTvWidget { id: button }
    Timer {
        interval: 50; running: true; repeat: true
        onTriggered: {
            elapsed += 50;
            if (elapsed > 8000 || DesktopTv.errorMessage) {
                console.log("DISPLAY_TEST_FAILED: " + JSON.stringify({phase: phase,
                    mode: DesktopTv.mode, busy: DesktopTv.busy,
                    error: DesktopTv.errorMessage}));
                Qt.quit(); return;
            }
            if (DesktopTv.busy || !DesktopTv.available) return;
            if (phase === 0) {
                if (button.actionText !== "Switch to TV") throw new Error("initial label");
                DesktopTv.toggle();
                DesktopTv.toggle();
                phase = 1;
            } else if (phase === 1 && DesktopTv.mode === "tv" && DesktopTv.pending) {
                if (button.actionText !== "Keep TV") throw new Error("confirm label");
                DesktopTv.toggle();
                phase = 2;
            } else if (phase === 2 && DesktopTv.mode === "tv" && !DesktopTv.pending) {
                if (button.actionText !== "Switch to Desktop") throw new Error("TV label");
                DesktopTv.toggle();
                phase = 3;
            } else if (phase === 3 && DesktopTv.mode === "desktop") {
                console.log("DISPLAY_TEST_OK"); Qt.quit();
            }
        }
    }
}
''')
            env = dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software',
                       XDG_RUNTIME_DIR=str(base / 'runtime'), XDG_STATE_HOME=str(base / 'state'),
                       XDG_CACHE_HOME=str(base / 'cache'), HYPRLAND_INSTANCE_SIGNATURE='',
                       DISPLAY_TEST_BASE=str(base),
                       PATH=str(base / 'bin') + os.pathsep + os.environ['PATH'])
            result = subprocess.run(['quickshell', '--path', str(base)], env=env,
                                    text=True, capture_output=True, timeout=15)
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertIn('DISPLAY_TEST_OK', output)
            self.assertNotIn('DISPLAY_TEST_FAILED', output)
            actions = [json.loads(line) for line in
                       (base / 'actions.jsonl').read_text().splitlines()]
            self.assertEqual([action[0] for action in actions], ['eval', 'eval', 'eval'])
            self.assertEqual(json.loads((base / 'state.json').read_text()), ['DP-1', 'DP-2'])


if __name__ == '__main__':
    unittest.main()
